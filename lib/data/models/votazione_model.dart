import '../../domain/entities/votazione.dart';

class VotazioneModel extends Votazione {
  const VotazioneModel({required super.condominoId, required super.esito});

  factory VotazioneModel.fromMap(Map<String, dynamic> map) {
    return VotazioneModel(condominoId: map['condomino_id'], esito: EsitoVotazione.values.firstWhere((e) => e.name == map['esito']));
  }

  Map<String, dynamic> toMap(int argomentoId) {
    return {'argomento_id': argomentoId, 'condomino_id': condominoId, 'esito': esito.name};
  }

  factory VotazioneModel.fromEntity(Votazione votazione) {
    return VotazioneModel(condominoId: votazione.condominoId, esito: votazione.esito);
  }
}
