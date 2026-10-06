import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../models/medicamento.dart';

part 'cadastro_medicamento_event.dart';
part 'cadastro_medicamento_state.dart';

class CadastroMedicamentoBloc
    extends Bloc<CadastroMedicamentoEvent, CadastroMedicamentoState> {
  CadastroMedicamentoBloc() : super(const CadastroMedicamentoState()) {
    on<NextStep>((event, emit) {
      if (state.etapaAtual < 4) {
        emit(state.copyWith(etapaAtual: state.etapaAtual + 1));
      }
    });

    on<PreviousStep>((event, emit) {
      if (state.etapaAtual > 0) {
        emit(state.copyWith(etapaAtual: state.etapaAtual - 1));
      }
    });

    on<UpdateNomeForma>((event, emit) {
      emit(state.copyWith(nome: event.nome, forma: event.forma));
    });

    on<UpdateFrequencia>((event, emit) {
      emit(state.copyWith(
        frequencia: event.frequencia,
        intervaloHoras: event.intervaloHoras,
      ));
    });

    on<UpdateHorarios>((event, emit) {
      emit(state.copyWith(horarios: event.horarios));
    });

    on<UpdateEstoqueInstrucoes>((event, emit) {
      emit(state.copyWith(
        estoqueAtual: event.estoqueAtual,
        instrucoes: event.instrucoes,
      ));
    });
    
    on<UpdateFoto>((event, emit) {
      emit(state.copyWith(fotoUrl: event.fotoUrl));
    });

    on<SaveMedicamento>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));
      
      try {
        // Simulando salvar
        await Future.delayed(const Duration(seconds: 1));
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } catch (e) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: 'Erro ao salvar medicamento',
        ));
      }
    });
  }
}
