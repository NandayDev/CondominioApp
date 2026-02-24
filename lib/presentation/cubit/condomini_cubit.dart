import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_condomini.dart';
import 'condomini_state.dart';

class CondominiCubit extends Cubit<CondominiState> {
  final GetCondomini getCondominiUseCase;

  CondominiCubit({required this.getCondominiUseCase}) : super(CondominiInitial());

  Future<void> fetchCondomini() async {
    try {
      emit(CondominiLoading());
      final condomini = await getCondominiUseCase();
      emit(CondominiLoaded(condomini));
    } catch (e) {
      emit(CondominiError("Errore nel caricamento dei condòmini: ${e.toString()}"));
    }
  }
}
