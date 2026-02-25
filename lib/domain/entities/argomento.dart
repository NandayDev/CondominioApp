import 'package:equatable/equatable.dart';

import 'votazione.dart';

enum TipoArgomento { custom, consuntivo, preventivo, dimissioni, elezione }

class Argomento extends Equatable {
  final int? id;
  final String titolo;
  final String testo;
  final TipoArgomento tipo;
  final Map<String, dynamic> metadata;
  final List<Votazione> votazioni;

  const Argomento({
    this.id,
    required this.titolo,
    required this.testo,
    this.tipo = TipoArgomento.custom,
    this.metadata = const {},
    required this.votazioni,
  });

  @override
  List<Object?> get props => [id, titolo, testo, tipo, metadata, votazioni];
}
