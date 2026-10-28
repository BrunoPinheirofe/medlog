part of 'doses_bloc.dart';

enum DosesStatus { loading, success, failure }

class DosesState extends Equatable {
  final DosesStatus status;
  final DateTime dataSelecionada;
  final List<GrupoHorarioDoses> gruposHorario;
  final List<ItemDoseDia> dosesExtras;
  final List<Medicamento> medicamentosDisponiveis;
  final List<AlertaEstoqueBaixo> alertasEstoque;
  final String? errorMessage;

  const DosesState({
    this.status = DosesStatus.loading,
    required this.dataSelecionada,
    this.gruposHorario = const [],
    this.dosesExtras = const [],
    this.medicamentosDisponiveis = const [],
    this.alertasEstoque = const [],
    this.errorMessage,
  });

  bool get semDosesAgendadas => gruposHorario.isEmpty;

  DosesState copyWith({
    DosesStatus? status,
    DateTime? dataSelecionada,
    List<GrupoHorarioDoses>? gruposHorario,
    List<ItemDoseDia>? dosesExtras,
    List<Medicamento>? medicamentosDisponiveis,
    List<AlertaEstoqueBaixo>? alertasEstoque,
    String? errorMessage,
  }) {
    return DosesState(
      status: status ?? this.status,
      dataSelecionada: dataSelecionada ?? this.dataSelecionada,
      gruposHorario: gruposHorario ?? this.gruposHorario,
      dosesExtras: dosesExtras ?? this.dosesExtras,
      medicamentosDisponiveis: medicamentosDisponiveis ?? this.medicamentosDisponiveis,
      alertasEstoque: alertasEstoque ?? this.alertasEstoque,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        dataSelecionada,
        gruposHorario,
        dosesExtras,
        medicamentosDisponiveis,
        alertasEstoque,
        errorMessage,
      ];
}
