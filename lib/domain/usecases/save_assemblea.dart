import '../entities/assemblea.dart';
import '../repositories/assemblea_repository.dart';

class SaveAssemblea {
  final AssembleaRepository repository;

  SaveAssemblea(this.repository);

  Future<void> call(Assemblea assemblea) async {
    return await repository.saveAssemblea(assemblea);
  }
}
