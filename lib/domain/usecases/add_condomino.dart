import '../entities/condomino.dart';
import '../repositories/condomino_repository.dart';

class AddCondomino {
  final CondominoRepository repository;

  AddCondomino(this.repository);

  Future<void> call(Condomino condomino) async {
    return await repository.addCondomino(condomino);
  }
}
