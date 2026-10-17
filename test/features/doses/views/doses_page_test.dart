import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/doses/doses_page.dart';
import 'package:medlog/features/doses/models/registro_dose.dart';
import 'package:medlog/features/doses/repositories/dose_repository.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

import '../../medicamentos/repositories/fake_repository.dart';

class FakeDoseRepository implements DoseRepository {
  FakeDoseRepository(this.medRepo);

  final FakeMedicamentoRepository medRepo;
  final Map<String, RegistroDose> store = {};
  int _seq = 0;

  @override
  Future<List<RegistroDose>> getByData(String dataIso) async {
    return store.values.where((r) => r.data == dataIso).toList();
  }

  @override
  Future<void> registrarStatusDose({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
    required StatusDose novoStatus,
  }) async {
    final id = RegistroDose.gerarIdAgendado(dataIso, medicamento.id, horario);
    final anterior = store[id]?.status ?? StatusDose.pendente;
    final silenciadaAnterior = store[id]?.silenciada ?? false;
    if (anterior == novoStatus) return;

    if (novoStatus == StatusDose.pendente && !silenciadaAnterior) {
      store.remove(id);
    } else {
      store[id] = RegistroDose(
        id: id,
        medicamentoId: medicamento.id,
        data: dataIso,
        horario: horario,
        status: novoStatus,
        silenciada: silenciadaAnterior,
        extra: false,
        registradoEm: ++_seq,
      );
    }

    final medAtual = medRepo.store[medicamento.id];
    if (medAtual != null) {
      if (anterior != StatusDose.tomada && novoStatus == StatusDose.tomada) {
        medRepo.store[medicamento.id] = medAtual.copyWith(
          estoqueAtual: medAtual.estoqueAtual > 0 ? medAtual.estoqueAtual - 1 : 0,
        );
      } else if (anterior == StatusDose.tomada && novoStatus != StatusDose.tomada) {
        medRepo.store[medicamento.id] = medAtual.copyWith(
          estoqueAtual: medAtual.estoqueAtual + 1,
        );
      }
    }
  }

  @override
  Future<void> registrarSilenciarDose({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
    required bool silenciada,
  }) async {
    final id = RegistroDose.gerarIdAgendado(dataIso, medicamento.id, horario);
    final statusAtual = store[id]?.status ?? StatusDose.pendente;
    if (statusAtual == StatusDose.pendente && !silenciada) {
      store.remove(id);
    } else {
      store[id] = RegistroDose(
        id: id,
        medicamentoId: medicamento.id,
        data: dataIso,
        horario: horario,
        status: statusAtual,
        silenciada: silenciada,
        extra: false,
        registradoEm: ++_seq,
      );
    }
  }

  @override
  Future<void> registrarDoseExtra({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
  }) async {
    final id = 'extra_${++_seq}_${medicamento.id}';
    store[id] = RegistroDose(
      id: id,
      medicamentoId: medicamento.id,
      data: dataIso,
      horario: horario,
      status: StatusDose.tomada,
      extra: true,
      registradoEm: _seq,
    );
    final medAtual = medRepo.store[medicamento.id];
    if (medAtual != null) {
      medRepo.store[medicamento.id] = medAtual.copyWith(
        estoqueAtual: medAtual.estoqueAtual > 0 ? medAtual.estoqueAtual - 1 : 0,
      );
    }
  }

  @override
  Future<void> removerDoseExtra({
    required String registroId,
    required String medicamentoId,
  }) async {
    if (store.remove(registroId) != null) {
      final medAtual = medRepo.store[medicamentoId];
      if (medAtual != null) {
        medRepo.store[medicamentoId] = medAtual.copyWith(
          estoqueAtual: medAtual.estoqueAtual + 1,
        );
      }
    }
  }
}

void main() {
  const losartana = Medicamento(
    id: 'med-1',
    nome: 'Losartana',
    forma: FormaMedicamento.comprimido,
    doseValor: 50,
    doseUnidade: 'mg',
    frequencia: Frequencia.duasVezes,
    horarios: [TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 19, minute: 0)],
    estoqueAtual: 10,
    estoqueMinimo: 3,
  );

  const dipironaSos = Medicamento(
    id: 'med-2',
    nome: 'Dipirona SOS',
    forma: FormaMedicamento.gota,
    frequencia: Frequencia.quandoNecessario,
    horarios: [],
    estoqueAtual: 5,
    estoqueMinimo: 2,
  );

  testWidgets(
      'Exibe grupos de horário, permite marcar dose tomada, silenciar apenas uma dose e registrar dose extra',
      (tester) async {
    final medRepo = FakeMedicamentoRepository()
      ..store[losartana.id] = losartana
      ..store[dipironaSos.id] = dipironaSos;
    final doseRepo = FakeDoseRepository(medRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DosesPage(
            medicamentoRepository: medRepo,
            doseRepository: doseRepo,
            dataInicial: DateTime(2026, 10, 16),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Horários agendados da Losartana estão visíveis
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('Losartana'), findsNWidgets(2));

    // Toca na primeira dose de Losartana (07:00) para marcar como tomada
    await tester.tap(find.text('Losartana').first);
    await tester.pumpAndSettle();

    expect(medRepo.store['med-1']!.estoqueAtual, 9);
    // O ícone de comprimido continua visível nas duas doses de Losartana + badge de check
    expect(find.byIcon(Icons.medication), findsNWidgets(2));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Silencia apenas a primeira dose (07:00); a de 19:00 permanece ativa
    await tester.tap(find.byTooltip('Silenciar esta dose').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ativar alarme da dose'), findsOneWidget);
    expect(find.byTooltip('Silenciar esta dose'), findsOneWidget);

    // Registra uma dose extra (Quando necessário)
    await tester.tap(find.text('Registrar dose extra'));
    await tester.pumpAndSettle();

    expect(find.text('Dipirona SOS'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    await tester.tap(find.text('Dipirona SOS'));
    await tester.pumpAndSettle();

    // Verifica que a dose extra foi exibida com o ícone de gotas e descontou do estoque
    expect(find.textContaining('Dose extra registrada às'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    expect(medRepo.store['med-2']!.estoqueAtual, 4);
  });

  testWidgets(
      'Não exibe doses em dias anteriores ao início do tratamento nem após o término de tratamento temporário',
      (tester) async {
    final antibiotico = Medicamento(
      id: 'med-temp',
      nome: 'Amoxicilina',
      forma: FormaMedicamento.comprimido,
      usoContinuo: false,
      duracaoDias: 2,
      dataInicio: DateTime(2026, 10, 15), // Ativo apenas em 15/10 e 16/10
      frequencia: Frequencia.umaVez,
      horarios: const [TimeOfDay(hour: 8, minute: 0)],
      estoqueAtual: 10,
      estoqueMinimo: 2,
    );

    final medRepo = FakeMedicamentoRepository()
      ..store[antibiotico.id] = antibiotico;
    final doseRepo = FakeDoseRepository(medRepo);
    // Mesmo que houvesse um registro salvo no dia 14 (anterior ao início em 15/10),
    // a dose não deve aparecer antes do início do tratamento.
    await doseRepo.registrarStatusDose(
      medicamento: antibiotico,
      dataIso: '2026-10-14',
      horario: const TimeOfDay(hour: 8, minute: 0),
      novoStatus: StatusDose.tomada,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DosesPage(
            medicamentoRepository: medRepo,
            doseRepository: doseRepo,
            dataInicial: DateTime(2026, 10, 15),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Em 15/10 (início): aparece
    expect(find.text('Amoxicilina'), findsOneWidget);

    // Seleciona 14/10 (antes do início): não deve aparecer
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(find.text('Amoxicilina'), findsNothing);

    // Seleciona 16/10 (2º e último dia): aparece
    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    expect(find.text('Amoxicilina'), findsOneWidget);

    // Seleciona 17/10 (após os 2 dias de duração): não deve aparecer
    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();
    expect(find.text('Amoxicilina'), findsNothing);
  });
}
