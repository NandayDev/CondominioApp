import '../entities/assemblea.dart';

abstract class AssembleaRepository {
  Future<List<Assemblea>> getAssemblee();

  Future<void> saveAssemblea(Assemblea assemblea);

  Future<void> deleteAssemblea(int id);
}
