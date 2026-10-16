import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/bloc/cadastro_medicamento_bloc.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

import '../repositories/fake_repository.dart';

void main() {
  group('CadastroMedicamentoBloc', () {
    late CadastroMedicamentoBloc bloc;

    setUp(() {
      bloc = CadastroMedicamentoBloc(repository: FakeMedicamentoRepository());
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial deve ser correto', () {
      expect(bloc.state, const CadastroMedicamentoState());
      expect(bloc.state.isNomeValido, isFalse);
      expect(bloc.state.isEtapaAtualValida, isFalse);
    });

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'não deve avançar etapa 0 se nome for inválido e deve sinalizar erro inline',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(NextStep()),
      expect: () => [
        const CadastroMedicamentoState(
          etapaAtual: 0,
          tentouAvancar: true,
        ),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve avançar etapas quando campos obrigatórios estiverem válidos',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      seed: () => const CadastroMedicamentoState(
        nome: 'Paracetamol',
        horarios: [TimeOfDay(hour: 8, minute: 0)],
      ),
      act: (bloc) {
        bloc.add(NextStep()); // vai para 1
        bloc.add(NextStep()); // vai para 2
        bloc.add(NextStep()); // vai para 3
        bloc.add(NextStep()); // já está na última, não passa de 3
      },
      expect: () => [
        const CadastroMedicamentoState(
          nome: 'Paracetamol',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 1,
        ),
        const CadastroMedicamentoState(
          nome: 'Paracetamol',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 2,
        ),
        const CadastroMedicamentoState(
          nome: 'Paracetamol',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 3,
        ),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve voltar para a etapa anterior (PreviousStep) até o limite 0',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      seed: () => const CadastroMedicamentoState(etapaAtual: 2),
      act: (bloc) {
        bloc.add(PreviousStep()); // vai para 1
        bloc.add(PreviousStep()); // vai para 0
        bloc.add(PreviousStep()); // permanece em 0
      },
      expect: () => [
        const CadastroMedicamentoState(etapaAtual: 1),
        const CadastroMedicamentoState(etapaAtual: 0),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve navegar para etapa concluída via GoToStep',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      seed: () => const CadastroMedicamentoState(etapaAtual: 3),
      act: (bloc) => bloc.add(const GoToStep(1)),
      expect: () => [
        const CadastroMedicamentoState(etapaAtual: 1),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar o nome e a forma corretamente (UpdateNomeForma)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(const UpdateNomeForma('Aspirina', FormaMedicamento.gota)),
      expect: () => [
        const CadastroMedicamentoState(nome: 'Aspirina', forma: FormaMedicamento.gota),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar dosagem (UpdateDosagem)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(const UpdateDosagem(500, 'mg')),
      expect: () => [
        const CadastroMedicamentoState(doseValor: 500, doseUnidade: 'mg'),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar cor temática (UpdateCor)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(const UpdateCor(0xFF2196F3)),
      expect: () => [
        const CadastroMedicamentoState(corHex: 0xFF2196F3),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar a frequencia corretamente (UpdateFrequencia)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(const UpdateFrequencia(Frequencia.intervaloHoras, intervaloHoras: 8)),
      expect: () => [
        const CadastroMedicamentoState(frequencia: Frequencia.intervaloHoras, intervaloHoras: 8),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar duração do tratamento (UpdateTratamentoDuracao)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(const UpdateTratamentoDuracao(usoContinuo: false, duracaoDias: 7)),
      expect: () => [
        const CadastroMedicamentoState(usoContinuo: false, duracaoDias: 7),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve gerar horários automaticamente a partir do inicial (GerarHorariosAutomaticos)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      seed: () => const CadastroMedicamentoState(frequencia: Frequencia.duasVezes),
      act: (bloc) => bloc.add(const GerarHorariosAutomaticos(TimeOfDay(hour: 8, minute: 0))),
      expect: () => [
        const CadastroMedicamentoState(
          frequencia: Frequencia.duasVezes,
          horarios: [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 20, minute: 0),
          ],
        ),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve permitir editar e remover horários pontuais',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      seed: () => const CadastroMedicamentoState(
        horarios: [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
      ),
      act: (bloc) {
        bloc.add(const EditarHorario(1, TimeOfDay(hour: 21, minute: 30)));
        bloc.add(const RemoverHorario(0));
      },
      expect: () => [
        const CadastroMedicamentoState(
          horarios: [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 21, minute: 30),
          ],
        ),
        const CadastroMedicamentoState(
          horarios: [
            TimeOfDay(hour: 21, minute: 30),
          ],
        ),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'deve atualizar o estoque e instrucoes (UpdateEstoqueInstrucoes)',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(const UpdateEstoqueInstrucoes(10, 'Tomar em jejum', estoqueMinimo: 3)),
      expect: () => [
        const CadastroMedicamentoState(
          estoqueAtual: 10,
          estoqueMinimo: 3,
          instrucoes: 'Tomar em jejum',
        ),
      ],
    );

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'SaveMedicamento deve ter sucesso quando dados obrigatórios forem válidos',
      build: () => CadastroMedicamentoBloc(repository: FakeMedicamentoRepository()),
      seed: () => const CadastroMedicamentoState(
        nome: 'Amoxicilina',
        horarios: [TimeOfDay(hour: 8, minute: 0)],
        etapaAtual: 3,
      ),
      act: (bloc) => bloc.add(SaveMedicamento()),
      expect: () => [
        const CadastroMedicamentoState(
          nome: 'Amoxicilina',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 3,
          isSubmitting: true,
        ),
        const CadastroMedicamentoState(
          nome: 'Amoxicilina',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 3,
          isSubmitting: false,
          isSuccess: true,
        ),
      ],
    );

    test('SaveMedicamento persiste o medicamento montado no repositório', () async {
      final repository = FakeMedicamentoRepository();
      final bloc = CadastroMedicamentoBloc(repository: repository);
      bloc.add(const UpdateNomeForma('Dipirona', FormaMedicamento.comprimido));
      bloc.add(const UpdateHorarios([TimeOfDay(hour: 8, minute: 0)]));
      bloc.add(SaveMedicamento());

      await bloc.stream.firstWhere((state) => state.isSuccess);

      final salvo = (await repository.getAll()).single;
      expect(salvo.nome, 'Dipirona');
      expect(salvo.horarios, const [TimeOfDay(hour: 8, minute: 0)]);
      await bloc.close();
    });

    blocTest<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      'SaveMedicamento emite erro quando o repositório falha',
      build: () {
        final repository = FakeMedicamentoRepository()..erroAoSalvar = Exception('falha');
        return CadastroMedicamentoBloc(repository: repository);
      },
      seed: () => const CadastroMedicamentoState(
        nome: 'Amoxicilina',
        horarios: [TimeOfDay(hour: 8, minute: 0)],
        etapaAtual: 3,
      ),
      act: (bloc) => bloc.add(SaveMedicamento()),
      expect: () => [
        const CadastroMedicamentoState(
          nome: 'Amoxicilina',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 3,
          isSubmitting: true,
        ),
        const CadastroMedicamentoState(
          nome: 'Amoxicilina',
          horarios: [TimeOfDay(hour: 8, minute: 0)],
          etapaAtual: 3,
          isSubmitting: false,
          errorMessage: 'Erro ao salvar medicamento. Tente novamente.',
        ),
      ],
    );
  });
}
