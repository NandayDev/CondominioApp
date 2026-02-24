import 'package:equatable/equatable.dart';
import '../../domain/entities/condomino.dart';

abstract class CondominiState extends Equatable {
  const CondominiState();

  @override
  List<Object?> get props => [];
}

class CondominiInitial extends CondominiState {}

class CondominiLoading extends CondominiState {}

class CondominiLoaded extends CondominiState {
  final List<Condomino> condomini;

  const CondominiLoaded(this.condomini);

  @override
  List<Object?> get props => [condomini];
}

class CondominiError extends CondominiState {
  final String message;

  const CondominiError(this.message);

  @override
  List<Object?> get props => [message];
}
