import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlog/features/medicamentos/bloc/cadastro_medicamento_bloc.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

void main() {
  group('CadastroMedicamentoBloc', () {
    late CadastroMedicamentoBloc bloc;

    setUp(() {
      bloc = CadastroMedicamentoBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial deve ser correto', () {
      expect(bloc.state, const CadastroMedicamentoState());
    });

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve avançar para a próxima etapa (NextStep) até o limite',
      build: () => CadastroMedicamentoBloc(),
      act: (bloc) {
        bloc.add(NextStep()); // vai para 1
        bloc.add(NextStep()); // vai para 2
        bloc.add(NextStep()); // vai para 3
        bloc.add(NextStep()); // vai para 4
        bloc.add(NextStep()); // tenta ir para 5 (ignora)
      },
      expect: () => [
        const CadastroMedicamentoState(etapaAtual: 1),
        const CadastroMedicamentoState(etapaAtual: 2),
        const CadastroMedicamentoState(etapaAtual: 3),
        const CadastroMedicamentoState(etapaAtual: 4),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve voltar para a etapa anterior (PreviousStep) até o limite',
      build: () => CadastroMedicamentoBloc()..emit(const CadastroMedicamentoState(etapaAtual: 2)),
      act: (bloc) {
        bloc.add(PreviousStep()); // vai para 1
        bloc.add(PreviousStep()); // vai para 0
        bloc.add(PreviousStep()); // tenta ir para -1 (ignora)
      },
      expect: () => [
        const CadastroMedicamentoState(etapaAtual: 1),
        const CadastroMedicamentoState(etapaAtual: 0),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar o nome e a forma corretamente (UpdateNomeForma)',
      build: () => CadastroMedicamentoBloc(),
      act: (bloc) => bloc.add(const UpdateNomeForma('Aspirina', FormaMedicamento.gota)),
      expect: () => [
        const CadastroMedicamentoState(nome: 'Aspirina', forma: FormaMedicamento.gota),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar a frequencia corretamente (UpdateFrequencia)',
      build: () => CadastroMedicamentoBloc(),
      act: (bloc) => bloc.add(const UpdateFrequencia(Frequencia.intervaloHoras, intervaloHoras: 8)),
      expect: () => [
        const CadastroMedicamentoState(frequencia: Frequencia.intervaloHoras, intervaloHoras: 8),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar o estoque e instrucoes (UpdateEstoqueInstrucoes)',
      build: () => CadastroMedicamentoBloc(),
      act: (bloc) => bloc.add(const UpdateEstoqueInstrucoes(10, 'Tomar em jejum')),
      expect: () => [
        const CadastroMedicamentoState(estoqueAtual: 10, instrucoes: 'Tomar em jejum'),
      ],
    );
  });
}
