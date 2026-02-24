import '../../domain/entities/assemblea.dart';
import '../../domain/repositories/assemblea_repository.dart';
import '../datasources/database_helper.dart';
import '../models/assemblea_model.dart';

class AssembleaRepositoryImpl implements AssembleaRepository {
  final DatabaseHelper databaseHelper;

  AssembleaRepositoryImpl(this.databaseHelper);

  @override
  Future<List<Assemblea>> getAssemblee() async {
    return await databaseHelper.getAssemblee();
  }

  @override
  Future<void> saveAssemblea(Assemblea assemblea) async {
    final model = AssembleaModel.fromEntity(assemblea);
    await databaseHelper.saveAssemblea(model);
  }

  @override
  Future<void> deleteAssemblea(int id) async {
    await databaseHelper.deleteAssemblea(id);
  }
}
