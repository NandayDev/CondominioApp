import '../repositories/condomino_repository.dart';

class DeleteCondomino {
  final CondominoRepository repository;

  DeleteCondomino(this.repository);

  Future<void> call(int id) async {
    return await repository.deleteCondomino(id);
  }
}
