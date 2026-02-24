import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/condomino.dart';
import '../../domain/usecases/add_condomino.dart';
import '../../domain/usecases/delete_condomino.dart';
import '../../domain/usecases/get_condomini.dart';
import '../../domain/usecases/update_condomino.dart';
import 'condomini_state.dart';

class CondominiCubit extends Cubit<CondominiState> {
  final GetCondomini getCondominiUseCase;
  final AddCondomino addCondominoUseCase;
  final UpdateCondomino updateCondominoUseCase;
  final DeleteCondomino deleteCondominoUseCase;

  CondominiCubit({
    required this.getCondominiUseCase,
    required this.addCondominoUseCase,
    required this.updateCondominoUseCase,
    required this.deleteCondominoUseCase,
  }) : super(CondominiInitial());

  Future<void> fetchCondomini() async {
    try {
      emit(CondominiLoading());
      final condomini = await getCondominiUseCase();
      emit(CondominiLoaded(condomini));
    } catch (e) {
      emit(CondominiError("Errore nel caricamento dei condòmini: ${e.toString()}"));
    }
  }

  Future<void> addCondomino(Condomino condomino) async {
    try {
      await addCondominoUseCase(condomino);
      await fetchCondomini();
    } catch (e) {
      emit(CondominiError("Errore nell'aggiunta del condòmino: ${e.toString()}"));
    }
  }

  Future<void> updateCondomino(Condomino condomino) async {
    try {
      await updateCondominoUseCase(condomino);
      await fetchCondomini();
    } catch (e) {
      emit(CondominiError("Errore nella modifica del condòmino: ${e.toString()}"));
    }
  }

  Future<void> deleteCondomino(int id) async {
    try {
      await deleteCondominoUseCase(id);
      await fetchCondomini();
    } catch (e) {
      emit(CondominiError("Errore nell'eliminazione del condòmino: ${e.toString()}"));
    }
  }
}
