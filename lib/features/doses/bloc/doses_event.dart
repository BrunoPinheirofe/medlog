part of 'doses_bloc.dart';

abstract class DosesEvent extends Equatable {
  const DosesEvent();

  @override
  List<Object?> get props => [];
}

class LoadDosesDia extends DosesEvent {
  final DateTime? data;

  const LoadDosesDia([this.data]);

  @override
  List<Object?> get props => [data];
}

class SelectDataDoses extends DosesEvent {
  final DateTime data;

  const SelectDataDoses(this.data);

  @override
  List<Object?> get props => [data];
}

class ToggleDoseTomada extends DosesEvent {
  final ItemDoseDia item;

  const ToggleDoseTomada(this.item);

  @override
  List<Object?> get props => [item];
}

class AlterarStatusDose extends DosesEvent {
  final ItemDoseDia item;
  final StatusDose status;

  const AlterarStatusDose(this.item, this.status);

  @override
  List<Object?> get props => [item, status];
}

class ToggleSilenciarDose extends DosesEvent {
  final ItemDoseDia item;

  const ToggleSilenciarDose(this.item);

  @override
  List<Object?> get props => [item];
}

class MarcarGrupoHorarioTomado extends DosesEvent {
  final GrupoHorarioDoses grupo;

  const MarcarGrupoHorarioTomado(this.grupo);

  @override
  List<Object?> get props => [grupo];
}

class RegistrarDoseExtraEvent extends DosesEvent {
  final Medicamento medicamento;
  final TimeOfDay? horario;

  const RegistrarDoseExtraEvent(this.medicamento, {this.horario});

  @override
  List<Object?> get props => [medicamento, horario];
}

class RemoverDoseExtraEvent extends DosesEvent {
  final String registroId;
  final String medicamentoId;

  const RemoverDoseExtraEvent(this.registroId, this.medicamentoId);

  @override
  List<Object?> get props => [registroId, medicamentoId];
}
