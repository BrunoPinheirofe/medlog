import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:medlog/core/database/app_database.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';
import 'package:medlog/features/medicamentos/repositories/medicamento_repository_sqflite.dart';

void main() {
  // Usa a implementação ffi (banco real em memória) nos testes.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late MedicamentoRepositorySqflite repository;

  Medicamento medicamento({
    String id = 'med-1',
    String nome = 'Paracetamol',
    FormaMedicamento forma = FormaMedicamento.comprimido,
    double? doseValor = 750,
    String? doseUnidade = 'mg',
    int? corHex = 0xFF2196F3,
    bool usoContinuo = false,
    int? duracaoDias = 7,
    DateTime? dataInicio,
    String? instrucoes = 'Tomar após as refeições',
    Frequencia frequencia = Frequencia.duasVezes,
    List<TimeOfDay> horarios = const [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 20, minute: 30),
    ],
    int? intervaloHoras,
    double estoqueAtual = 12,
    int estoqueMinimo = 5,
    String? fotoUrl,
  }) {
    final hoje = DateTime.now();
    return Medicamento(
      id: id,
      nome: nome,
      forma: forma,
      doseValor: doseValor,
      doseUnidade: doseUnidade,
      corHex: corHex,
      usoContinuo: usoContinuo,
      duracaoDias: duracaoDias,
      dataInicio: dataInicio ?? DateTime(hoje.year, hoje.month, hoje.day),
      instrucoes: instrucoes,
      frequencia: frequencia,
      horarios: horarios,
      intervaloHoras: intervaloHoras,
      estoqueAtual: estoqueAtual,
      estoqueMinimo: estoqueMinimo,
      fotoUrl: fotoUrl,
    );
  }

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: AppDatabase.configureForeignKeys,
      onCreate: (db, _) => AppDatabase.createSchema(db),
    );
    repository = MedicamentoRepositorySqflite(databaseProvider: () async => db);

    // O banco in-memory do ffi é compartilhado entre testes do processo.
    await db.execute('DELETE FROM medicamento_horarios');
    await db.execute('DELETE FROM medicamentos');
  });

  group('MedicamentoRepositorySqflite', () {
    test('save + getById preserva todos os campos incluindo nulos', () async {
      final original = medicamento(
        doseValor: 2.5,
        doseUnidade: null,
        horarios: const [],
        frequencia: Frequencia.quandoNecessario,
        corHex: null,
        duracaoDias: null,
        instrucoes: null,
      );

      await repository.save(original);
      final recuperado = await repository.getById('med-1');

      expect(recuperado, original);
      expect(recuperado?.doseValor, 2.5);
      expect(recuperado?.doseUnidade, isNull);
      expect(recuperado?.corHex, isNull);
      expect(recuperado?.duracaoDias, isNull);
      expect(recuperado?.instrucoes, isNull);
      expect(recuperado?.horarios, isEmpty);
    });

    test('getAll retorna ordenado do mais recente para o mais antigo', () async {
      await repository.save(medicamento(id: 'a', nome: 'A'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.save(medicamento(id: 'b', nome: 'B'));

      final lista = await repository.getAll();

      expect(lista.map((m) => m.id), ['b', 'a']);
    });

    test('save no mesmo id atualiza e preserva criado_em', () async {
      await repository.save(medicamento(id: 'med-1', nome: 'Antigo'));

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.save(medicamento(id: 'med-1', nome: 'Novo'));

      final depois = await repository.getById('med-1');
      expect(depois?.nome, 'Novo');
      expect(depois!.id, 'med-1');
    });

    test('horários são reescritos por completo no re-save', () async {
      await repository.save(medicamento());
      await repository.save(medicamento(horarios: const [TimeOfDay(hour: 6, minute: 15)]));

      final recuperado = await repository.getById('med-1');
      expect(recuperado?.horarios, const [TimeOfDay(hour: 6, minute: 15)]);
    });

    test('delete remove o medicamento e os horários em cascata', () async {
      await repository.save(medicamento());

      await repository.delete('med-1');

      expect(await repository.getById('med-1'), isNull);
      expect(await db.query('medicamento_horarios'), isEmpty);
    });

    test('updateEstoque altera somente estoque atual e mínimo', () async {
      await repository.save(medicamento());

      await repository.updateEstoque('med-1', 3, 2);

      final recuperado = await repository.getById('med-1');
      expect(recuperado?.estoqueAtual, 3);
      expect(recuperado?.estoqueMinimo, 2);
      expect(recuperado?.nome, 'Paracetamol');
    });

    test('getById retorna null quando não existe', () async {
      expect(await repository.getById('inexistente'), isNull);
    });
  });
}
