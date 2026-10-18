import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/core/database/app_database.dart';
import 'package:medlog/features/doses/models/registro_dose.dart';
import 'package:medlog/features/doses/repositories/dose_repository_sqflite.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';
import 'package:medlog/features/medicamentos/repositories/medicamento_repository_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late MedicamentoRepositorySqflite medRepo;
  late DoseRepositorySqflite doseRepo;

  const dipirona = Medicamento(
    id: 'med-1',
    nome: 'Dipirona',
    forma: FormaMedicamento.comprimido,
    doseValor: 500,
    doseUnidade: 'mg',
    frequencia: Frequencia.duasVezes,
    horarios: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    estoqueAtual: 10,
    estoqueMinimo: 3,
  );

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.databaseVersion,
        onConfigure: AppDatabase.configureForeignKeys,
        onCreate: (db, _) => AppDatabase.createSchema(db),
      ),
    );
    medRepo = MedicamentoRepositorySqflite(databaseProvider: () async => db);
    doseRepo = DoseRepositorySqflite(databaseProvider: () async => db);
    await medRepo.save(dipirona);
  });

  tearDown(() async {
    await db.close();
  });

  test('registrarStatusDose tomada desconta 1 do estoque e desmarcar devolve 1', () async {
    const horario = TimeOfDay(hour: 8, minute: 0);

    await doseRepo.registrarStatusDose(
      medicamento: dipirona,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.tomada,
    );

    var registros = await doseRepo.getByData('2026-10-16');
    expect(registros, hasLength(1));
    expect(registros.first.status, StatusDose.tomada);
    expect((await medRepo.getById('med-1'))!.estoqueAtual, 9);

    // Mudar para pulada devolve 1 ao estoque
    await doseRepo.registrarStatusDose(
      medicamento: dipirona,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.pulada,
    );
    expect((await medRepo.getById('med-1'))!.estoqueAtual, 10);

    // Voltar para pendente remove o registro sem alterar estoque novamente
    await doseRepo.registrarStatusDose(
      medicamento: dipirona,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.pendente,
    );
    registros = await doseRepo.getByData('2026-10-16');
    expect(registros, isEmpty);
    expect((await medRepo.getById('med-1'))!.estoqueAtual, 10);
  });

  test('registrarDoseExtra e removerDoseExtra ajustam o estoque corretamente', () async {
    await doseRepo.registrarDoseExtra(
      medicamento: dipirona,
      dataIso: '2026-10-16',
      horario: const TimeOfDay(hour: 14, minute: 30),
    );

    final registros = await doseRepo.getByData('2026-10-16');
    expect(registros, hasLength(1));
    expect(registros.first.extra, isTrue);
    expect((await medRepo.getById('med-1'))!.estoqueAtual, 9);

    await doseRepo.removerDoseExtra(
      registroId: registros.first.id,
      medicamentoId: dipirona.id,
    );

    expect(await doseRepo.getByData('2026-10-16'), isEmpty);
    expect((await medRepo.getById('med-1'))!.estoqueAtual, 10);
  });

  test('registrarSilenciarDose silencia apenas a dose específica sem afetar outras doses',
      () async {
    await doseRepo.registrarSilenciarDose(
      medicamento: dipirona,
      dataIso: '2026-10-16',
      horario: const TimeOfDay(hour: 8, minute: 0),
      silenciada: true,
    );

    var registros = await doseRepo.getByData('2026-10-16');
    expect(registros, hasLength(1));
    expect(registros.single.horario, const TimeOfDay(hour: 8, minute: 0));
    expect(registros.single.silenciada, isTrue);
    expect(registros.single.status, StatusDose.pendente);

    // Ao reativar o alarme de uma dose pendente, o registro é limpo
    await doseRepo.registrarSilenciarDose(
      medicamento: dipirona,
      dataIso: '2026-10-16',
      horario: const TimeOfDay(hour: 8, minute: 0),
      silenciada: false,
    );
    registros = await doseRepo.getByData('2026-10-16');
    expect(registros, isEmpty);
    expect((await medRepo.getById('med-1'))!.estoqueAtual, 10);
  });

  test('US1/US2: desconta e estorna dose fracionada (2.5 ml) e grava estoque_consumido', () async {
    const xarope = Medicamento(
      id: 'med-xarope',
      nome: 'Xarope Infantil',
      forma: FormaMedicamento.liquido,
      doseValor: 2.5,
      doseUnidade: 'ml',
      frequencia: Frequencia.duasVezes,
      horarios: [TimeOfDay(hour: 9, minute: 0)],
      estoqueAtual: 100.0,
      estoqueMinimo: 10,
    );
    await medRepo.save(xarope);

    const horario = TimeOfDay(hour: 9, minute: 0);
    await doseRepo.registrarStatusDose(
      medicamento: xarope,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.tomada,
    );

    expect((await medRepo.getById('med-xarope'))!.estoqueAtual, 97.5);
    final registros = await doseRepo.getByData('2026-10-16');
    expect(registros.single.estoqueConsumido, 2.5);

    // Idempotência: repetir tomada não desconta novamente
    await doseRepo.registrarStatusDose(
      medicamento: xarope,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.tomada,
    );
    expect((await medRepo.getById('med-xarope'))!.estoqueAtual, 97.5);

    // Desmarcar (pendente) estorna 2.5 ml
    await doseRepo.registrarStatusDose(
      medicamento: xarope,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.pendente,
    );
    expect((await medRepo.getById('med-xarope'))!.estoqueAtual, 100.0);
  });

  test('US1/US2: dose extra SOS em gotas (15 gotas) desconta e estorna ao remover', () async {
    const gotasMed = Medicamento(
      id: 'med-gotas',
      nome: 'Dipirona Gotas',
      forma: FormaMedicamento.gota,
      doseValor: 15,
      doseUnidade: 'gotas',
      frequencia: Frequencia.quandoNecessario,
      estoqueAtual: 200.0,
      estoqueMinimo: 20,
    );
    await medRepo.save(gotasMed);

    await doseRepo.registrarDoseExtra(
      medicamento: gotasMed,
      dataIso: '2026-10-16',
      horario: const TimeOfDay(hour: 15, minute: 0),
    );

    expect((await medRepo.getById('med-gotas'))!.estoqueAtual, 185.0);
    final registros = await doseRepo.getByData('2026-10-16');
    expect(registros.single.estoqueConsumido, 15.0);

    await doseRepo.removerDoseExtra(
      registroId: registros.single.id,
      medicamentoId: gotasMed.id,
    );
    expect((await medRepo.getById('med-gotas'))!.estoqueAtual, 200.0);
  });

  test('US1/US2: piso zero quando estoque < dose e estorno restaura exatamente o consumido', () async {
    const xaropeBaixo = Medicamento(
      id: 'med-piso',
      nome: 'Xarope Fim',
      forma: FormaMedicamento.liquido,
      doseValor: 2.5,
      doseUnidade: 'ml',
      frequencia: Frequencia.umaVez,
      horarios: [TimeOfDay(hour: 10, minute: 0)],
      estoqueAtual: 1.0,
      estoqueMinimo: 5,
    );
    await medRepo.save(xaropeBaixo);

    const horario = TimeOfDay(hour: 10, minute: 0);
    await doseRepo.registrarStatusDose(
      medicamento: xaropeBaixo,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.tomada,
    );

    // Estoque crava em 0.0 (nunca negativo) e grava estoque_consumido = 1.0
    expect((await medRepo.getById('med-piso'))!.estoqueAtual, 0.0);
    final registros = await doseRepo.getByData('2026-10-16');
    expect(registros.single.estoqueConsumido, 1.0);

    // Desfazer tomada devolve apenas 1.0 (e não 2.5 fantasma)
    await doseRepo.registrarStatusDose(
      medicamento: xaropeBaixo,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.pendente,
    );
    expect((await medRepo.getById('med-piso'))!.estoqueAtual, 1.0);

    // Tomar com estoque já em 0.0 nunca bloqueia e mantém 0.0 no estorno
    await medRepo.updateEstoque('med-piso', 0.0, 5);
    await doseRepo.registrarStatusDose(
      medicamento: xaropeBaixo,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.tomada,
    );
    expect((await medRepo.getById('med-piso'))!.estoqueAtual, 0.0);
    expect((await doseRepo.getByData('2026-10-16')).single.estoqueConsumido, 0.0);

    await doseRepo.registrarStatusDose(
      medicamento: xaropeBaixo,
      dataIso: '2026-10-16',
      horario: horario,
      novoStatus: StatusDose.pendente,
    );
    expect((await medRepo.getById('med-piso'))!.estoqueAtual, 0.0);
  });

  test('US2: registro tomado legado v3 (estoque_consumido = 0) usa fallback da dose ao estornar',
      () async {
    const compDuplo = Medicamento(
      id: 'med-legado',
      nome: 'Vitamina C',
      forma: FormaMedicamento.comprimido,
      doseValor: 2,
      doseUnidade: 'comprimido',
      frequencia: Frequencia.umaVez,
      horarios: [TimeOfDay(hour: 8, minute: 0)],
      estoqueAtual: 8.0,
      estoqueMinimo: 5,
    );
    await medRepo.save(compDuplo);

    // Simula linha v3 pré-existente marcada como tomada com estoque_consumido = 0
    await db.insert('registros_dose', {
      'id': '2026-10-16_med-legado_08:00',
      'medicamento_id': 'med-legado',
      'data': '2026-10-16',
      'horario': '08:00',
      'status': 'tomada',
      'silenciada': 0,
      'extra': 0,
      'estoque_consumido': 0.0,
      'registrado_em': 1000,
    });

    await doseRepo.registrarStatusDose(
      medicamento: compDuplo,
      dataIso: '2026-10-16',
      horario: const TimeOfDay(hour: 8, minute: 0),
      novoStatus: StatusDose.pulada,
    );

    expect((await medRepo.getById('med-legado'))!.estoqueAtual, 10.0);
    final reg = (await doseRepo.getByData('2026-10-16')).single;
    expect(reg.status, StatusDose.pulada);
    expect(reg.estoqueConsumido, 0.0);
  });

  test('US1/US2 (T013): grupo de horário com múltiplos medicamentos desconta e estorna cada dose específica',
      () async {
    const meioComprimido = Medicamento(
      id: 'med-meio',
      nome: 'Clonazepam',
      forma: FormaMedicamento.comprimido,
      doseValor: 0.5,
      doseUnidade: 'comprimido',
      frequencia: Frequencia.umaVez,
      horarios: [TimeOfDay(hour: 8, minute: 0)],
      estoqueAtual: 10.0,
      estoqueMinimo: 2,
    );
    await medRepo.save(meioComprimido);

    const horario = TimeOfDay(hour: 8, minute: 0);
    // Marca ambos do horário 08:00 como tomados
    for (final med in [dipirona, meioComprimido]) {
      await doseRepo.registrarStatusDose(
        medicamento: med,
        dataIso: '2026-10-16',
        horario: horario,
        novoStatus: StatusDose.tomada,
      );
    }

    expect((await medRepo.getById('med-1'))!.estoqueAtual, 9.0);
    expect((await medRepo.getById('med-meio'))!.estoqueAtual, 9.5);

    // Desmarca ambos do horário 08:00
    for (final med in [dipirona, meioComprimido]) {
      await doseRepo.registrarStatusDose(
        medicamento: med,
        dataIso: '2026-10-16',
        horario: horario,
        novoStatus: StatusDose.pendente,
      );
    }

    expect((await medRepo.getById('med-1'))!.estoqueAtual, 10.0);
    expect((await medRepo.getById('med-meio'))!.estoqueAtual, 10.0);
  });
}
