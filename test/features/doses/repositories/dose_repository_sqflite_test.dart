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
  });
}
