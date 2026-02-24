import 'package:get_it/get_it.dart';
import 'data/datasources/database_helper.dart';
import 'data/repositories/condomino_repository_impl.dart';
import 'domain/repositories/condomino_repository.dart';
import 'domain/usecases/get_condomini.dart';
import 'presentation/cubit/condomini_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Cubit
  sl.registerFactory(() => CondominiCubit(getCondominiUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetCondomini(sl()));

  // Repository
  sl.registerLazySingleton<CondominoRepository>(
    () => CondominoRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton(() => DatabaseHelper.instance);
}
