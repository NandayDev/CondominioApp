import 'package:get_it/get_it.dart';

import 'data/datasources/database_helper.dart';
import 'data/repositories/assemblea_repository_impl.dart';
import 'data/repositories/condomino_repository_impl.dart';
import 'domain/repositories/assemblea_repository.dart';
import 'domain/repositories/condomino_repository.dart';
import 'domain/usecases/add_condomino.dart';
import 'domain/usecases/delete_assemblea.dart';
import 'domain/usecases/delete_condomino.dart';
import 'domain/usecases/get_assemblee.dart';
import 'domain/usecases/get_condomini.dart';
import 'domain/usecases/save_assemblea.dart';
import 'domain/usecases/update_condomino.dart';
import 'presentation/cubit/assemblee_cubit.dart';
import 'presentation/cubit/condomini_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Cubits
  sl.registerFactory(
        () =>
        CondominiCubit(
          getCondominiUseCase: sl(),
          addCondominoUseCase: sl(),
          updateCondominoUseCase: sl(),
          deleteCondominoUseCase: sl(),
        ),
  );
  sl.registerFactory(
        () =>
        AssembleeCubit(
          getAssembleeUseCase: sl(),
          saveAssembleaUseCase: sl(),
          deleteAssembleaUseCase: sl(),
        ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCondomini(sl()));
  sl.registerLazySingleton(() => AddCondomino(sl()));
  sl.registerLazySingleton(() => UpdateCondomino(sl()));
  sl.registerLazySingleton(() => DeleteCondomino(sl()));
  sl.registerLazySingleton(() => GetAssemblee(sl()));
  sl.registerLazySingleton(() => SaveAssemblea(sl()));
  sl.registerLazySingleton(() => DeleteAssemblea(sl()));

  // Repositories
  sl.registerLazySingleton<CondominoRepository>(
    () => CondominoRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AssembleaRepository>(
        () => AssembleaRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton(() => DatabaseHelper.instance);
}
