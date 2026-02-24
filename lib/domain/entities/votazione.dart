import 'package:equatable/equatable.dart';

enum EsitoVotazione { favorevole, contrario, astenuto }

class Votazione extends Equatable {
  final int condominoId;
  final EsitoVotazione esito;

  const Votazione({required this.condominoId, required this.esito});

  @override
  List<Object?> get props => [condominoId, esito];
}
