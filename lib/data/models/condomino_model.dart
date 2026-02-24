import '../../domain/entities/condomino.dart';

class CondominoModel extends Condomino {
  const CondominoModel({
    super.id,
    required super.nome,
    required super.indirizzo,
    required super.millesimi,
  });

  factory CondominoModel.fromMap(Map<String, dynamic> map) {
    return CondominoModel(
      id: map['id'],
      nome: map['nome'],
      indirizzo: map['indirizzo'],
      millesimi: map['millesimi'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'indirizzo': indirizzo,
      'millesimi': millesimi,
    };
  }

  factory CondominoModel.fromEntity(Condomino condomino) {
    return CondominoModel(
      id: condomino.id,
      nome: condomino.nome,
      indirizzo: condomino.indirizzo,
      millesimi: condomino.millesimi,
    );
  }
}
