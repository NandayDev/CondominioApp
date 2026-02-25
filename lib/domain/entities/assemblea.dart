import 'package:equatable/equatable.dart';

import 'argomento.dart';

enum AssembleaStato { avvenuta, nonAvvenuta }

class Assemblea extends Equatable {
  final int? id;
  final DateTime dataPrimaConvocazione;
  final DateTime dataSecondaConvocazione;
  final DateTime? dataFine;
  final String luogo;
  final AssembleaStato stato;
  final List<int> partecipantiIds;
  final int? presidenteId; // Nuova colonna
  final int? segretarioId; // Nuova colonna
  final List<Argomento> argomenti;

  const Assemblea({
    this.id,
    required this.dataPrimaConvocazione,
    required this.dataSecondaConvocazione,
    this.dataFine,
    required this.luogo,
    required this.stato,
    required this.partecipantiIds,
    this.presidenteId,
    this.segretarioId,
    required this.argomenti,
  });

  @override
  List<Object?> get props => [
    id,
    dataPrimaConvocazione,
    dataSecondaConvocazione,
    dataFine,
    luogo,
    stato,
    partecipantiIds,
    presidenteId,
    segretarioId,
    argomenti,
  ];
}
