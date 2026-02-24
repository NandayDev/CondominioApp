import '../entities/assemblea.dart';
import '../repositories/assemblea_repository.dart';

class GetAssemblee {
  final AssembleaRepository repository;

  GetAssemblee(this.repository);

  Future<List<Assemblea>> call() async {
    return await repository.getAssemblee();
  }
}
