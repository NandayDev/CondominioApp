import 'dart:convert';

import '../../domain/entities/argomento.dart';
import 'votazione_model.dart';

class ArgomentoModel extends Argomento {
  const ArgomentoModel({
    super.id,
    required super.titolo,
    required super.testo,
    super.tipo = TipoArgomento.custom,
    super.metadata = const {},
    required super.votazioni,
  });

  factory ArgomentoModel.fromMap(Map<String, dynamic> map, List<VotazioneModel> votazioni) {
    return ArgomentoModel(
      id: map['id'],
      titolo: map['titolo'] ?? '',
      testo: map['testo'],
      tipo: TipoArgomento.values.firstWhere(
            (e) => e.name == (map['tipo'] ?? 'custom'),
        orElse: () => TipoArgomento.custom,
      ),
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
      votazioni: votazioni,
    );
  }

  Map<String, dynamic> toMap(int assembleaId) {
    return {
      'id': id,
      'assemblea_id': assembleaId,
      'titolo': titolo,
      'testo': testo,
      'tipo': tipo.name,
      'metadata': jsonEncode(metadata),
    };
  }

  factory ArgomentoModel.fromEntity(Argomento argomento) {
    return ArgomentoModel(
      id: argomento.id,
      titolo: argomento.titolo,
      testo: argomento.testo,
      tipo: argomento.tipo,
      metadata: argomento.metadata,
      votazioni: argomento.votazioni,
    );
  }
}
