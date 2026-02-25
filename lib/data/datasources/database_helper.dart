import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/argomento_model.dart';
import '../models/assemblea_model.dart';
import '../models/condomino_model.dart';
import '../models/votazione_model.dart';

/// Parametri per le operazioni sul database che possono essere passati tra Isolate
class _DbTaskParams {
  final String path;
  final String password;
  final Map<String, dynamic>? data;

  _DbTaskParams({required this.path, required this.password, this.data});
}

/// Inizializza e migra il database se necessario (eseguito in background)
void _initDbTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    db.execute('SELECT count(*) FROM sqlite_master;'); // Verifica la chiave
    db.execute('PRAGMA foreign_keys = ON;');

    var currentVersion = (db
        .select('PRAGMA user_version')
        .first['user_version'] as int);

    if (currentVersion < 1) {
      db.execute('''
        CREATE TABLE condomini (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          indirizzo TEXT NOT NULL,
          millesimi REAL NOT NULL
        )
      ''');
      db.execute('PRAGMA user_version = 1');
      currentVersion = 1;
    }

    if (currentVersion < 2) {
      db.execute('''
        CREATE TABLE assemblee (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data_prima TEXT NOT NULL,
          data_seconda TEXT NOT NULL,
          stato TEXT NOT NULL
        )
      ''');
      db.execute('''
        CREATE TABLE assemblea_partecipanti (
          assemblea_id INTEGER NOT NULL,
          condomino_id INTEGER NOT NULL,
          PRIMARY KEY (assemblea_id, condomino_id),
          FOREIGN KEY (assemblea_id) REFERENCES assemblee (id) ON DELETE CASCADE,
          FOREIGN KEY (condomino_id) REFERENCES condomini (id) ON DELETE CASCADE
        )
      ''');
      db.execute('''
        CREATE TABLE argomenti (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assemblea_id INTEGER NOT NULL,
          testo TEXT NOT NULL,
          FOREIGN KEY (assemblea_id) REFERENCES assemblee (id) ON DELETE CASCADE
        )
      ''');
      db.execute('''
        CREATE TABLE votazioni (
          argomento_id INTEGER NOT NULL,
          condomino_id INTEGER NOT NULL,
          esito TEXT NOT NULL,
          PRIMARY KEY (argomento_id, condomino_id),
          FOREIGN KEY (argomento_id) REFERENCES argomenti (id) ON DELETE CASCADE,
          FOREIGN KEY (condomino_id) REFERENCES condomini (id) ON DELETE CASCADE
        )
      ''');
      db.execute('PRAGMA user_version = 2');
      currentVersion = 2;
    }

    if (currentVersion < 3) {
      db.execute('ALTER TABLE argomenti ADD COLUMN titolo TEXT NOT NULL DEFAULT \'\'');
      db.execute('PRAGMA user_version = 3');
      currentVersion = 3;
    }

    if (currentVersion < 4) {
      db.execute('ALTER TABLE assemblee ADD COLUMN luogo TEXT NOT NULL DEFAULT \'\'');
      db.execute('ALTER TABLE assemblee ADD COLUMN data_fine TEXT');
      db.execute('PRAGMA user_version = 4');
      currentVersion = 4;
    }

    if (currentVersion < 5) {
      db.execute('ALTER TABLE argomenti ADD COLUMN tipo TEXT NOT NULL DEFAULT \'custom\'');
      db.execute('ALTER TABLE argomenti ADD COLUMN metadata TEXT');
      db.execute('PRAGMA user_version = 5');
      currentVersion = 5;
    }

    if (currentVersion < 6) {
      db.execute('ALTER TABLE assemblee ADD COLUMN presidente_id INTEGER');
      db.execute('ALTER TABLE assemblee ADD COLUMN segretario_id INTEGER');
      db.execute('PRAGMA user_version = 6');
    }

  } finally {
    db.dispose();
  }
}


/// Recupera i condomini (eseguito in background)
List<Map<String, dynamic>> _getCondominiTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    final ResultSet resultSet = db.select('SELECT * FROM condomini');
    return resultSet.map((row) => Map<String, dynamic>.from(row)).toList();
  } finally {
    db.dispose();
  }
}

/// Recupera le assemblee (eseguito in background)
List<Map<String, dynamic>> _getAssembleeTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    final List<Map<String, dynamic>> result = [];

    final ResultSet assembleeRS = db.select('SELECT * FROM assemblee');
    for (final row in assembleeRS) {
      final int assembleaId = row['id'];

      // Partecipanti
      final ResultSet partecipantiRS = db.select(
          'SELECT condomino_id FROM assemblea_partecipanti WHERE assemblea_id = ?',
          [assembleaId]
      );
      final List<int> partecipanti = partecipantiRS.map((p) => p['condomino_id'] as int).toList();

      // Argomenti
      final List<Map<String, dynamic>> argomenti = [];
      final ResultSet argomentiRS = db.select(
          'SELECT * FROM argomenti WHERE assemblea_id = ?',
          [assembleaId]
      );
      for (final argRow in argomentiRS) {
        final int argomentoId = argRow['id'];

        // Votazioni
        final ResultSet votazioniRS = db.select(
            'SELECT * FROM votazioni WHERE argomento_id = ?',
            [argomentoId]
        );
        final List<Map<String, dynamic>> votazioni = votazioniRS.map((v) => Map<String, dynamic>.from(v)).toList();

        final Map<String, dynamic> argMap = Map<String, dynamic>.from(argRow);
        argMap['votazioni'] = votazioni;
        argomenti.add(argMap);
      }

      final Map<String, dynamic> assembleaMap = Map<String, dynamic>.from(row);
      assembleaMap['partecipanti'] = partecipanti;
      assembleaMap['argomenti'] = argomenti;
      result.add(assembleaMap);
    }
    return result;
  } finally {
    db.dispose();
  }
}

/// Salva un'assemblea (eseguito in background)
void _saveAssembleaTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    db.execute('PRAGMA foreign_keys = ON;');

    final Map<String, dynamic> data = params.data!;
    final List<int> partecipanti = data['partecipanti'];
    final List<Map<String, dynamic>> argomenti = data['argomenti'];

    db.execute('BEGIN TRANSACTION');

    int assembleaId;
    if (data['id'] == null) {
      final stmt = db.prepare(
          'INSERT INTO assemblee (data_prima, data_seconda, data_fine, luogo, stato, presidente_id, segretario_id) VALUES (?, ?, ?, ?, ?, ?, ?)');
      stmt.execute(
          [data['data_prima'], data['data_seconda'], data['data_fine'], data['luogo'], data['stato'], data['presidente_id'], data['segretario_id']]);
      assembleaId = db.lastInsertRowId;
      stmt.dispose();
    } else {
      assembleaId = data['id'];
      final stmt = db.prepare(
          'UPDATE assemblee SET data_prima = ?, data_seconda = ?, data_fine = ?, luogo = ?, stato = ?, presidente_id = ?, segretario_id = ? WHERE id = ?');
      stmt.execute([
        data['data_prima'],
        data['data_seconda'],
        data['data_fine'],
        data['luogo'],
        data['stato'],
        data['presidente_id'],
        data['segretario_id'],
        assembleaId
      ]);
      stmt.dispose();
      
      // Pulisci relazioni esistenti per l'update
      db.execute('DELETE FROM argomenti WHERE assemblea_id = ?', [assembleaId]);
      db.execute('DELETE FROM assemblea_partecipanti WHERE assemblea_id = ?', [assembleaId]);
    }

    // Salva Partecipanti
    for (final condominoId in partecipanti) {
      db.execute('INSERT INTO assemblea_partecipanti (assemblea_id, condomino_id) VALUES (?, ?)', [assembleaId, condominoId]);
    }

    // Salva Argomenti e relative Votazioni
    for (final argData in argomenti) {
      final argStmt = db.prepare('INSERT INTO argomenti (assemblea_id, titolo, testo, tipo, metadata) VALUES (?, ?, ?, ?, ?)');
      argStmt.execute([assembleaId, argData['titolo'], argData['testo'], argData['tipo'], argData['metadata']]);
      final int argomentoId = db.lastInsertRowId;
      argStmt.dispose();
      
      final List<Map<String, dynamic>> votazioni = argData['votazioni'];
      for (final votData in votazioni) {
        db.execute(
            'INSERT INTO votazioni (argomento_id, condomino_id, esito) VALUES (?, ?, ?)',
            [argomentoId, votData['condomino_id'], votData['esito']]
        );
      }
    }

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    db.close();
  }
}

/// Elimina un'assemblea (eseguito in background)
void _deleteAssembleaTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('DELETE FROM assemblee WHERE id = ?', [params.data!['id']]);
  } finally {
    db.dispose();
  }
}

// ... (Metodi per i condomini già presenti)
void _addCondominoTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    final data = params.data!;
    final stmt = db.prepare('INSERT INTO condomini (nome, indirizzo, millesimi) VALUES (?, ?, ?)');
    stmt.execute([data['nome'], data['indirizzo'], data['millesimi']]);
    stmt.dispose();
  } finally {
    db.close();
  }
}

void _updateCondominoTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    final data = params.data!;
    final stmt = db.prepare('UPDATE condomini SET nome = ?, indirizzo = ?, millesimi = ? WHERE id = ?');
    stmt.execute([data['nome'], data['indirizzo'], data['millesimi'], data['id']]);
    stmt.dispose();
  } finally {
    db.close();
  }
}

void _deleteCondominoTask(_DbTaskParams params) {
  final db = sqlite3.open(params.path);
  try {
    db.execute("PRAGMA key = '${params.password}';");
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('DELETE FROM condomini WHERE id = ?', [params.data!['id']]);
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

  _DbTaskParams _getParams(String path, {Map<String, dynamic>? data}) => 
      _DbTaskParams(path: path, password: _password, data: data);

  Future<void> _ensureInitialized() async {
    final path = await _path;
    await compute(_initDbTask, _getParams(path));
  }

  // Condomini
  Future<List<CondominoModel>> getCondomini() async {
    await _ensureInitialized();
    final path = await _path;
    final List<Map<String, dynamic>> maps = await compute(_getCondominiTask, _getParams(path));
    return maps.map((json) => CondominoModel.fromMap(json)).toList();
  }

  Future<void> addCondomino(CondominoModel condomino) async {
    await _ensureInitialized();
    final path = await _path;
    await compute(_addCondominoTask, _getParams(path, data: condomino.toMap()));
  }

  Future<void> updateCondomino(CondominoModel condomino) async {
    await _ensureInitialized();
    final path = await _path;
    await compute(_updateCondominoTask, _getParams(path, data: condomino.toMap()));
  }

  Future<void> deleteCondomino(int id) async {
    await _ensureInitialized();
    final path = await _path;
    await compute(_deleteCondominoTask, _getParams(path, data: {'id': id}));
  }

  // Assemblee
  Future<List<AssembleaModel>> getAssemblee() async {
    await _ensureInitialized();
    final path = await _path;
    final List<Map<String, dynamic>> maps = await compute(_getAssembleeTask, _getParams(path));

    return maps.map((map) {
      final List<int> partecipanti = List<int>.from(map['partecipanti']);
      final List<ArgomentoModel> argomenti = (map['argomenti'] as List).map((argMap) {
        final List<VotazioneModel> votazioni = (argMap['votazioni'] as List)
            .map((v) => VotazioneModel.fromMap(v as Map<String, dynamic>))
            .toList();
        return ArgomentoModel.fromMap(argMap as Map<String, dynamic>, votazioni);
      }).toList();
      return AssembleaModel.fromMap(map, partecipanti, argomenti);
    }).toList();
  }

  Future<void> saveAssemblea(AssembleaModel assemblea) async {
    await _ensureInitialized();
    final path = await _path;

    final Map<String, dynamic> data = assemblea.toMap();
    data['partecipanti'] = assemblea.partecipantiIds;
    data['argomenti'] = assemblea.argomenti.map((arg) {
      final argModel = ArgomentoModel.fromEntity(arg);
      final Map<String, dynamic> argMap = argModel.toMap(0); // id assemblea gestito nel task
      argMap['votazioni'] = arg.votazioni.map((v) => VotazioneModel.fromEntity(v).toMap(0)).toList();
      return argMap;
    }).toList();

    await compute(_saveAssembleaTask, _getParams(path, data: data));
  }

  Future<void> deleteAssemblea(int id) async {
    await _ensureInitialized();
    final path = await _path;
    await compute(_deleteAssembleaTask, _getParams(path, data: {'id': id}));
  }
}
