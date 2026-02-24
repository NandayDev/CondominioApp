import '../entities/condomino.dart';

abstract class CondominoRepository {
  Future<List<Condomino>> getCondomini();
}
