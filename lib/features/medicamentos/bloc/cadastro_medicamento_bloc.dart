import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/schedule_calculator.dart';
import '../models/medicamento.dart';
import '../repositories/medicamento_repository.dart';
import '../repositories/medicamento_repository_sqflite.dart';

part 'cadastro_medicamento_event.dart';
part 'cadastro_medicamento_state.dart';

class CadastroMedicamentoBloc
    extends Bloc<CadastroMedicamentoEvent, CadastroMedicamentoState> {
  final MedicamentoRepository _repository;

  CadastroMedicamentoBloc({MedicamentoRepository? repository})
      : _repository = repository ?? MedicamentoRepositorySqflite(),
        super(const CadastroMedicamentoState()) {
    on<NextStep>((event, emit) {
      if (!state.isEtapaAtualValida) {
        emit(state.copyWith(
          tentouAvancar: true,
        ));
        return;
      }

      if (state.etapaAtual < 3) {
        emit(state.copyWith(
          etapaAtual: state.etapaAtual + 1,
          tentouAvancar: false,
          errorMessage: null,
        ));
      }
    });

    on<PreviousStep>((event, emit) {
      if (state.etapaAtual > 0) {
        emit(state.copyWith(
          etapaAtual: state.etapaAtual - 1,
          tentouAvancar: false,
          errorMessage: null,
        ));
      }
    });

    on<GoToStep>((event, emit) {
      if (event.step >= 0 && event.step <= 3 && event.step <= state.etapaAtual) {
        emit(state.copyWith(
          etapaAtual: event.step,
          tentouAvancar: false,
          errorMessage: null,
        ));
      }
    });

    on<UpdateNomeForma>((event, emit) {
      emit(state.copyWith(
        nome: event.nome,
        forma: event.forma,
        errorMessage: null,
      ));
    });

    on<UpdateDosagem>((event, emit) {
      emit(state.copyWith(
        doseValor: event.doseValor,
        doseUnidade: event.doseUnidade,
      ));
    });

    on<UpdateCor>((event, emit) {
      emit(state.copyWith(corHex: event.corHex));
    });

    on<UpdateFrequencia>((event, emit) {
      List<TimeOfDay> horariosAjustados = state.horarios;
      if (event.frequencia == Frequencia.quandoNecessario) {
        horariosAjustados = const [];
      } else if (state.horarios.isNotEmpty) {
        // Se já havia um horário inicial definido, recalcula automaticamente para a nova frequência
        horariosAjustados = ScheduleCalculator.gerarHorarios(
          inicial: state.horarios.first,
          frequencia: event.frequencia,
          intervaloHoras: event.intervaloHoras,
        );
      }

      emit(state.copyWith(
        frequencia: event.frequencia,
        intervaloHoras: event.intervaloHoras,
        horarios: horariosAjustados,
        errorMessage: null,
      ));
    });

    on<UpdateTratamentoDuracao>((event, emit) {
      emit(state.copyWith(
        usoContinuo: event.usoContinuo,
        duracaoDias: event.duracaoDias,
      ));
    });

    on<GerarHorariosAutomaticos>((event, emit) {
      final novosHorarios = ScheduleCalculator.gerarHorarios(
        inicial: event.inicial,
        frequencia: state.frequencia,
        intervaloHoras: state.intervaloHoras,
      );
      emit(state.copyWith(
        horarios: novosHorarios,
        tentouAvancar: false,
        errorMessage: null,
      ));
    });

    on<UpdateHorarios>((event, emit) {
      emit(state.copyWith(
        horarios: ScheduleCalculator.normalizarEOrdenar(event.horarios),
        errorMessage: null,
      ));
    });

    on<EditarHorario>((event, emit) {
      if (event.index >= 0 && event.index < state.horarios.length) {
        final novos = List<TimeOfDay>.from(state.horarios);
        novos[event.index] = event.novoHorario;
        emit(state.copyWith(
          horarios: ScheduleCalculator.normalizarEOrdenar(novos),
        ));
      }
    });

    on<RemoverHorario>((event, emit) {
      if (event.index >= 0 && event.index < state.horarios.length) {
        final novos = List<TimeOfDay>.from(state.horarios)..removeAt(event.index);
        emit(state.copyWith(horarios: novos));
      }
    });

    on<AdicionarHorario>((event, emit) {
      final novos = List<TimeOfDay>.from(state.horarios)..add(event.horario);
      emit(state.copyWith(
        horarios: ScheduleCalculator.normalizarEOrdenar(novos),
        errorMessage: null,
      ));
    });

    on<UpdateEstoqueInstrucoes>((event, emit) {
      emit(state.copyWith(
        estoqueAtual: event.estoqueAtual,
        estoqueMinimo: event.estoqueMinimo ?? state.estoqueMinimo,
        instrucoes: event.instrucoes,
      ));
    });

    on<UpdateFoto>((event, emit) {
      emit(state.copyWith(fotoUrl: event.fotoUrl));
    });

    on<SaveMedicamento>((event, emit) async {
      if (!state.isNomeValido) {
        emit(state.copyWith(
          etapaAtual: 0,
          tentouAvancar: true,
          errorMessage: 'Por favor, informe o nome do medicamento.',
        ));
        return;
      }

      if (!state.isHorariosValidos) {
        emit(state.copyWith(
          etapaAtual: 2,
          tentouAvancar: true,
          errorMessage: 'Por favor, defina pelo menos um horário para o medicamento.',
        ));
        return;
      }

      emit(state.copyWith(isSubmitting: true, errorMessage: null));

      try {
        await _repository.save(state.toMedicamento());
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } catch (e) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: 'Erro ao salvar medicamento. Tente novamente.',
        ));
      }
    });
  }
}
