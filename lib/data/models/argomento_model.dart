import '../../domain/entities/argomento.dart';
import 'votazione_model.dart';

class ArgomentoModel extends Argomento {
  const ArgomentoModel({super.id, required super.titolo, required super.testo, required super.votazioni});

  factory ArgomentoModel.fromMap(Map<String, dynamic> map, List<VotazioneModel> votazioni) {
    return ArgomentoModel(id: map['id'], titolo: map['titolo'] ?? '', testo: map['testo'], votazioni: votazioni);
  }

  Map<String, dynamic> toMap(int assembleaId) {
    return {'id': id, 'assemblea_id': assembleaId, 'titolo': titolo, 'testo': testo};
  }

  factory ArgomentoModel.fromEntity(Argomento argomento) {
    return ArgomentoModel(id: argomento.id, titolo: argomento.titolo, testo: argomento.testo, votazioni: argomento.votazioni);
  }
}
