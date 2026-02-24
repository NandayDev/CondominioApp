import 'package:equatable/equatable.dart';

import 'votazione.dart';

class Argomento extends Equatable {
  final int? id;
  final String titolo;
  final String testo;
  final List<Votazione> votazioni;

  const Argomento({this.id, required this.titolo, required this.testo, required this.votazioni});

  @override
  List<Object?> get props => [id, titolo, testo, votazioni];
}
