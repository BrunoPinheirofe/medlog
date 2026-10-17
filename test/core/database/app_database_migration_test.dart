import 'package:flutter_test/flutter_test.dart';
import 'package:medlog/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('migra da versão 1 para a versão 3 preservando medicamentos e adicionando registros_dose e data_inicio',
      () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: AppDatabase.configureForeignKeys,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE medicamentos (
              id TEXT PRIMARY KEY,
              nome TEXT NOT NULL,
              forma TEXT NOT NULL,
              frequencia TEXT NOT NULL,
              dose_valor REAL,
              dose_unidade TEXT,
              cor_hex INTEGER,
              uso_continuo INTEGER NOT NULL DEFAULT 1,
              duracao_dias INTEGER,
              instrucoes TEXT,
              intervalo_horas INTEGER,
              estoque_atual INTEGER NOT NULL DEFAULT 0,
              estoque_minimo INTEGER NOT NULL DEFAULT 5,
              foto_url TEXT,
              criado_em INTEGER NOT NULL,
              atualizado_em INTEGER NOT NULL
            );
          ''');
        },
      ),
    );

    await db.insert('medicamentos', {
      'id': 'med-1',
      'nome': 'Dipirona',
      'forma': 'comprimido',
      'frequencia': 'umaVez',
      'uso_continuo': 1,
      'estoque_atual': 10,
      'estoque_minimo': 5,
      'criado_em': 1000,
      'atualizado_em': 1000,
    });

    await AppDatabase.migrate(db, 1, AppDatabase.databaseVersion);

    final medRows = await db.query('medicamentos', where: 'id = ?', whereArgs: ['med-1']);
    expect(medRows, hasLength(1));
    expect(medRows.first['nome'], 'Dipirona');
    expect(medRows.first.containsKey('data_inicio'), isTrue);

    await db.update(
      'medicamentos',
      {'data_inicio': '2026-10-16'},
      where: 'id = ?',
      whereArgs: ['med-1'],
    );
    final atualizado = await db.query('medicamentos', where: 'id = ?', whereArgs: ['med-1']);
    expect(atualizado.first['data_inicio'], '2026-10-16');

    await db.insert('registros_dose', {
      'id': '2026-10-16_med-1_08:00',
      'medicamento_id': 'med-1',
      'data': '2026-10-16',
      'horario': '08:00',
      'status': 'pendente',
      'silenciada': 1,
      'extra': 0,
      'registrado_em': 2000,
    });

    final doseRows = await db.query('registros_dose');
    expect(doseRows, hasLength(1));
    expect(doseRows.first['silenciada'], 1);

    await db.close();
  });
}
