import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/bloc/medicamentos_bloc.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

import '../repositories/fake_repository.dart';

void main() {
  const dipirona = Medicamento(
    id: '1',
    nome: 'Dipirona',
    forma: FormaMedicamento.comprimido,
    frequencia: Frequencia.duasVezes,
    horarios: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    estoqueAtual: 2,
    estoqueMinimo: 5,
  );
  const ibuprofeno = Medicamento(
    id: '2',
    nome: 'Ibuprofeno',
    forma: FormaMedicamento.gota,
    frequencia: Frequencia.quandoNecessario,
    horarios: [],
  );

  group('MedicamentosBloc', () {
    blocTest<MedicamentosBloc, MedicamentosState>(
      'LoadMedicamentos emite sucesso com a lista do repositório',
      build: () {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona
          ..store[ibuprofeno.id] = ibuprofeno;
        return MedicamentosBloc(repository: repository);
      },
      act: (bloc) => bloc.add(LoadMedicamentos()),
      expect: () => [
        const MedicamentosState(
          status: MedicamentosStatus.success,
          medicamentos: [dipirona, ibuprofeno],
        ),
      ],
    );

    blocTest<MedicamentosBloc, MedicamentosState>(
      'LoadMedicamentos com repositório vazio emite sucesso sem itens',
      build: () => MedicamentosBloc(repository: FakeMedicamentoRepository()),
      act: (bloc) => bloc.add(LoadMedicamentos()),
      expect: () => [
        const MedicamentosState(status: MedicamentosStatus.success),
      ],
    );

    blocTest<MedicamentosBloc, MedicamentosState>(
      'LoadMedicamentos emite falha com mensagem quando o repositório lança erro',
      build: () => MedicamentosBloc(
        repository: FakeMedicamentoRepository()..erroAoCarregar = Exception('falha'),
      ),
      act: (bloc) => bloc.add(LoadMedicamentos()),
      expect: () => [
        const MedicamentosState(
          status: MedicamentosStatus.failure,
          errorMessage: 'Erro ao carregar medicamentos.',
        ),
      ],
    );

    blocTest<MedicamentosBloc, MedicamentosState>(
      'DeleteMedicamento remove o item do estado e persiste a exclusão',
      build: () {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona
          ..store[ibuprofeno.id] = ibuprofeno;
        return MedicamentosBloc(repository: repository);
      },
      seed: () => const MedicamentosState(
        status: MedicamentosStatus.success,
        medicamentos: [dipirona, ibuprofeno],
      ),
      act: (bloc) => bloc.add(const DeleteMedicamento('1')),
      expect: () => [
        const MedicamentosState(
          status: MedicamentosStatus.success,
          medicamentos: [ibuprofeno],
        ),
      ],
    );

    blocTest<MedicamentosBloc, MedicamentosState>(
      'DeleteMedicamento emite falha com mensagem quando o repositório lança erro',
      build: () => MedicamentosBloc(
        repository: FakeMedicamentoRepository()..erroAoRemover = Exception('falha'),
      ),
      seed: () => const MedicamentosState(
        status: MedicamentosStatus.success,
        medicamentos: [dipirona],
      ),
      act: (bloc) => bloc.add(const DeleteMedicamento('1')),
      expect: () => [
        const MedicamentosState(
          status: MedicamentosStatus.failure,
          errorMessage: 'Erro ao remover medicamento.',
          // lista preservada após falha
          medicamentos: [dipirona],
        ),
      ],
    );

    blocTest<MedicamentosBloc, MedicamentosState>(
      'RestoreMedicamento salva novamente o medicamento e recarrega a lista',
      build: () {
        final repository = FakeMedicamentoRepository()
          ..store[ibuprofeno.id] = ibuprofeno;
        return MedicamentosBloc(repository: repository);
      },
      seed: () => const MedicamentosState(
        status: MedicamentosStatus.success,
        medicamentos: [ibuprofeno],
      ),
      act: (bloc) => bloc.add(const RestoreMedicamento(dipirona)),
      expect: () => [
        const MedicamentosState(
          status: MedicamentosStatus.success,
          medicamentos: [ibuprofeno, dipirona],
        ),
      ],
    );
  });
}
