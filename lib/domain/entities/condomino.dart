import 'package:equatable/equatable.dart';

class Condomino extends Equatable {
  final int? id;
  final String nome;
  final String indirizzo;
  final double millesimi;

  const Condomino({
    this.id,
    required this.nome,
    required this.indirizzo,
    required this.millesimi,
  });

  @override
  List<Object?> get props => [id, nome, indirizzo, millesimi];
}
