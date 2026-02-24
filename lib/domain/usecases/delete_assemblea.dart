import '../repositories/assemblea_repository.dart';

class DeleteAssemblea {
  final AssembleaRepository repository;

  DeleteAssemblea(this.repository);

  Future<void> call(int id) async {
    return await repository.deleteAssemblea(id);
  }
}
