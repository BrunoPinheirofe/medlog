part of 'medicamentos_bloc.dart';

abstract class MedicamentosEvent extends Equatable {
  const MedicamentosEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedicamentos extends MedicamentosEvent {}

class DeleteMedicamento extends MedicamentosEvent {
  final String id;

  const DeleteMedicamento(this.id);

  @override
  List<Object?> get props => [id];
}
