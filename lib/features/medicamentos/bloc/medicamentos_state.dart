part of 'medicamentos_bloc.dart';

enum MedicamentosStatus { loading, success, failure }

class MedicamentosState extends Equatable {
  final MedicamentosStatus status;
  final List<Medicamento> medicamentos;
  final String? errorMessage;

  const MedicamentosState({
    this.status = MedicamentosStatus.loading,
    this.medicamentos = const [],
    this.errorMessage,
  });

  bool get estaVazia => medicamentos.isEmpty;

  MedicamentosState copyWith({
    MedicamentosStatus? status,
    List<Medicamento>? medicamentos,
    String? errorMessage,
  }) {
    return MedicamentosState(
      status: status ?? this.status,
      medicamentos: medicamentos ?? this.medicamentos,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, medicamentos, errorMessage];
}
