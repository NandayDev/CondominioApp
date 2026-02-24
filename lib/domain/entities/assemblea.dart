import 'package:equatable/equatable.dart';

import 'argomento.dart';

enum AssembleaStato { avvenuta, nonAvvenuta }

class Assemblea extends Equatable {
  final int? id;
  final DateTime dataPrimaConvocazione;
  final DateTime dataSecondaConvocazione;
  final DateTime? dataFine; // Nuova colonna: obbligatoria solo se avvenuta
  final String luogo; // Nuova colonna: obbligatoria sempre
  final AssembleaStato stato;
  final List<int> partecipantiIds; // IDs dei condomini partecipanti
  final List<Argomento> argomenti;

  const Assemblea({
    this.id,
    required this.dataPrimaConvocazione,
    required this.dataSecondaConvocazione,
    this.dataFine,
    required this.luogo,
    required this.stato,
    required this.partecipantiIds,
    required this.argomenti,
  });

  @override
  List<Object?> get props => [id, dataPrimaConvocazione, dataSecondaConvocazione, dataFine, luogo, stato, partecipantiIds, argomenti];
}
