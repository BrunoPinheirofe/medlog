import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/medicamento.dart';
import '../repositories/medicamento_repository.dart';
import '../repositories/medicamento_repository_sqflite.dart';

part 'medicamentos_event.dart';
part 'medicamentos_state.dart';

/// Bloc da listagem de medicamentos: carrega do repositório e remove itens.
class MedicamentosBloc extends Bloc<MedicamentosEvent, MedicamentosState> {
  MedicamentosBloc({MedicamentoRepository? repository})
      : _repository = repository ?? MedicamentoRepositorySqflite(),
        super(const MedicamentosState()) {
    on<LoadMedicamentos>((event, emit) async {
      if (state.status != MedicamentosStatus.loading) {
        emit(state.copyWith(status: MedicamentosStatus.loading));
      }
      try {
        final List<Medicamento> medicamentos = await _repository.getAll();
        emit(state.copyWith(
          status: MedicamentosStatus.success,
          medicamentos: medicamentos,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: MedicamentosStatus.failure,
          errorMessage: 'Erro ao carregar medicamentos.',
        ));
      }
    });

    on<DeleteMedicamento>((event, emit) async {
      try {
        await _repository.delete(event.id);
        emit(state.copyWith(
          status: MedicamentosStatus.success,
          medicamentos: state.medicamentos.where((m) => m.id != event.id).toList(),
        ));
      } catch (e) {
        emit(state.copyWith(
          status: MedicamentosStatus.failure,
          errorMessage: 'Erro ao remover medicamento.',
        ));
      }
    });

    on<RestoreMedicamento>((event, emit) async {
      try {
        await _repository.save(event.medicamento);
        final List<Medicamento> medicamentos = await _repository.getAll();
        emit(state.copyWith(
          status: MedicamentosStatus.success,
          medicamentos: medicamentos,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: MedicamentosStatus.failure,
          errorMessage: 'Erro ao restaurar medicamento.',
        ));
      }
    });
  }

  final MedicamentoRepository _repository;
}
