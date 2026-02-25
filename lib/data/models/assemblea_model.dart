import '../../domain/entities/assemblea.dart';
import 'argomento_model.dart';

class AssembleaModel extends Assemblea {
  const AssembleaModel({
    super.id,
    required super.dataPrimaConvocazione,
    required super.dataSecondaConvocazione,
    super.dataFine,
    required super.luogo,
    required super.stato,
    required super.partecipantiIds,
    super.presidenteId,
    super.segretarioId,
    required super.argomenti,
  });

  factory AssembleaModel.fromMap(Map<String, dynamic> map, List<int> partecipanti, List<ArgomentoModel> argomenti) {
    return AssembleaModel(
      id: map['id'],
      dataPrimaConvocazione: DateTime.parse(map['data_prima']),
      dataSecondaConvocazione: DateTime.parse(map['data_seconda']),
      dataFine: map['data_fine'] != null ? DateTime.parse(map['data_fine']) : null,
      luogo: map['luogo'] ?? '',
      stato: map['stato'] == 'avvenuta' ? AssembleaStato.avvenuta : AssembleaStato.nonAvvenuta,
      partecipantiIds: partecipanti,
      presidenteId: map['presidente_id'],
      segretarioId: map['segretario_id'],
      argomenti: argomenti,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_prima': dataPrimaConvocazione.toIso8601String(),
      'data_seconda': dataSecondaConvocazione.toIso8601String(),
      'data_fine': dataFine?.toIso8601String(),
      'luogo': luogo,
      'stato': stato == AssembleaStato.avvenuta ? 'avvenuta' : 'nonAvvenuta',
      'presidente_id': presidenteId,
      'segretario_id': segretarioId,
    };
  }

  factory AssembleaModel.fromEntity(Assemblea assemblea) {
    return AssembleaModel(
      id: assemblea.id,
      dataPrimaConvocazione: assemblea.dataPrimaConvocazione,
      dataSecondaConvocazione: assemblea.dataSecondaConvocazione,
      dataFine: assemblea.dataFine,
      luogo: assemblea.luogo,
      stato: assemblea.stato,
      partecipantiIds: assemblea.partecipantiIds,
      presidenteId: assemblea.presidenteId,
      segretarioId: assemblea.segretarioId,
      argomenti: assemblea.argomenti,
    );
  }
}
