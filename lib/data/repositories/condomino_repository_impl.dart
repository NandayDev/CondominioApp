import '../../domain/entities/condomino.dart';
import '../../domain/repositories/condomino_repository.dart';
import '../datasources/database_helper.dart';

class CondominoRepositoryImpl implements CondominoRepository {
  final DatabaseHelper databaseHelper;

  CondominoRepositoryImpl(this.databaseHelper);

  @override
  Future<List<Condomino>> getCondomini() async {
    return await databaseHelper.getCondomini();
  }
}
