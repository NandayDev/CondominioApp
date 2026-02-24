import '../entities/condomino.dart';

abstract class CondominoRepository {
  Future<List<Condomino>> getCondomini();

  Future<void> addCondomino(Condomino condomino);

  Future<void> updateCondomino(Condomino condomino);

  Future<void> deleteCondomino(int id);
}
