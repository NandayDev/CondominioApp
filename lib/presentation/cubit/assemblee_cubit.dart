import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/assemblea.dart';
import '../../domain/usecases/delete_assemblea.dart';
import '../../domain/usecases/get_assemblee.dart';
import '../../domain/usecases/save_assemblea.dart';
import 'assemblee_state.dart';

class AssembleeCubit extends Cubit<AssembleeState> {
  final GetAssemblee getAssembleeUseCase;
  final SaveAssemblea saveAssembleaUseCase;
  final DeleteAssemblea deleteAssembleaUseCase;

  AssembleeCubit({required this.getAssembleeUseCase, required this.saveAssembleaUseCase, required this.deleteAssembleaUseCase})
    : super(AssembleeInitial());

  Future<void> fetchAssemblee() async {
    try {
      emit(AssembleeLoading());
      final assemblee = await getAssembleeUseCase();
      emit(AssembleeLoaded(assemblee));
    } catch (e) {
      emit(AssembleeError("Errore nel caricamento delle assemblee: ${e.toString()}"));
    }
  }

  Future<void> saveAssemblea(Assemblea assemblea) async {
    try {
      await saveAssembleaUseCase(assemblea);
      await fetchAssemblee();
    } catch (e) {
      emit(AssembleeError("Errore nel salvataggio dell'assemblea: ${e.toString()}"));
    }
  }

  Future<void> deleteAssemblea(int id) async {
    try {
      await deleteAssembleaUseCase(id);
      await fetchAssemblee();
    } catch (e) {
      emit(AssembleeError("Errore nell'eliminazione dell'assemblea: ${e.toString()}"));
    }
  }
}
