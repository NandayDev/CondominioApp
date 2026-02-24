import '../entities/condomino.dart';
import '../repositories/condomino_repository.dart';

class GetCondomini {
  final CondominoRepository repository;

  GetCondomini(this.repository);

  Future<List<Condomino>> call() async {
    return await repository.getCondomini();
  }
}
