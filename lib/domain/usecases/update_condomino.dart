import '../entities/condomino.dart';
import '../repositories/condomino_repository.dart';

class UpdateCondomino {
  final CondominoRepository repository;

  UpdateCondomino(this.repository);

  Future<void> call(Condomino condomino) async {
    return await repository.updateCondomino(condomino);
  }
}
