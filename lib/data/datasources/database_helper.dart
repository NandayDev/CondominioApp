import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/condomino_model.dart';

/// Parametri per le operazioni sul database che possono essere passati tra Isolate
class _DbTaskParams {
  final String path;
  final String password;

  _DbTaskParams({required this.path, required this.password});
}

/// Inizializza il database se non esiste (eseguito in background)
void _initDbTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    // Verifica che la chiave sia corretta
    db.execute('SELECT count(*) FROM sqlite_master;');

    final tableExistsResult = db.select(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ?', 
      ['table', 'condomini']
    );

    if (tableExistsResult.isEmpty) {
      db.execute('''
        CREATE TABLE condomini (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          indirizzo TEXT NOT NULL,
          millesimi REAL NOT NULL
        )
      ''');

      final stmt = db.prepare('INSERT INTO condomini (nome, indirizzo, millesimi) VALUES (?, ?, ?)');
      stmt.execute(['Mario Rossi', 'Via Roma 1', 100.0]);
      stmt.execute(['Luigi Bianchi', 'Via Milano 10', 50.5]);
      stmt.close();
    }
  } finally {
    db.close();
  }
}

/// Recupera i condomini (eseguito in background)
List<Map<String, dynamic>> _getCondominiTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    final ResultSet resultSet = db.select('SELECT * FROM condomini');
    // Convertiamo Row in un Map standard perché Row potrebbe avere problemi ad uscire dall'Isolate
    return resultSet.map((row) => Map<String, dynamic>.from(row)).toList();
  } finally {
    db.close();
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  String? _dbPath;
  final String _password = 'my-secure-password';

  Future<String> get _path async {
    if (_dbPath != null) return _dbPath!;
    final docsDir = await getApplicationDocumentsDirectory();
    _dbPath = join(docsDir.path, 'condominio.db');
    return _dbPath!;
  }

  _DbTaskParams _getParams(String path) => _DbTaskParams(path: path, password: _password);

  Future<void> _ensureInitialized() async {
    final path = await _path;
    await compute(_initDbTask, _getParams(path));
  }

  Future<List<CondominoModel>> getCondomini() async {
    await _ensureInitialized();
    final path = await _path;
    
    final List<Map<String, dynamic>> maps = await compute(
      _getCondominiTask, 
      _getParams(path)
    );
    
    return maps.map((json) => CondominoModel.fromMap(json)).toList();
  }
}
