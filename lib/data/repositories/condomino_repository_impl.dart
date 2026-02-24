import '../../data/models/condomino_model.dart';
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

  @override
  Future<void> addCondomino(Condomino condomino) async {
    final condominoModel = CondominoModel.fromEntity(condomino);
    await databaseHelper.addCondomino(condominoModel);
  }

  @override
  Future<void> updateCondomino(Condomino condomino) async {
    final condominoModel = CondominoModel.fromEntity(condomino);
    await databaseHelper.updateCondomino(condominoModel);
  }

  @override
  Future<void> deleteCondomino(int id) async {
    await databaseHelper.deleteCondomino(id);
  }
}
