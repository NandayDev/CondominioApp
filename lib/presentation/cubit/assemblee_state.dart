import 'package:equatable/equatable.dart';

import '../../domain/entities/assemblea.dart';

abstract class AssembleeState extends Equatable {
  const AssembleeState();

  @override
  List<Object?> get props => [];
}

class AssembleeInitial extends AssembleeState {}

class AssembleeLoading extends AssembleeState {}

class AssembleeLoaded extends AssembleeState {
  final List<Assemblea> assemblee;

  const AssembleeLoaded(this.assemblee);

  @override
  List<Object?> get props => [assemblee];
}

class AssembleeError extends AssembleeState {
  final String message;

  const AssembleeError(this.message);

  @override
  List<Object?> get props => [message];
}
