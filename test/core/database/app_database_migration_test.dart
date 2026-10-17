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

  test('migra da versão 3 para a versão 4 convertendo estoque_atual para REAL e adicionando estoque_consumido',
      () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
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
              data_inicio TEXT,
              instrucoes TEXT,
              intervalo_horas INTEGER,
              estoque_atual INTEGER NOT NULL DEFAULT 0,
              estoque_minimo INTEGER NOT NULL DEFAULT 5,
              foto_url TEXT,
              criado_em INTEGER NOT NULL,
              atualizado_em INTEGER NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE medicamento_horarios (
              medicamento_id TEXT NOT NULL REFERENCES medicamentos(id) ON DELETE CASCADE,
              hora TEXT NOT NULL,
              ordem INTEGER NOT NULL,
              UNIQUE (medicamento_id, hora)
            );
          ''');
          await db.execute('''
            CREATE TABLE registros_dose (
              id TEXT PRIMARY KEY,
              medicamento_id TEXT NOT NULL REFERENCES medicamentos(id) ON DELETE CASCADE,
              data TEXT NOT NULL,
              horario TEXT NOT NULL,
              status TEXT NOT NULL,
              silenciada INTEGER NOT NULL DEFAULT 0,
              extra INTEGER NOT NULL DEFAULT 0,
              registrado_em INTEGER NOT NULL
            );
          ''');
        },
      ),
    );

    await db.insert('medicamentos', {
      'id': 'med-v3',
      'nome': 'Xarope',
      'forma': 'liquido',
      'frequencia': 'duasVezes',
      'dose_valor': 2.5,
      'dose_unidade': 'ml',
      'uso_continuo': 1,
      'data_inicio': '2026-10-15',
      'estoque_atual': 30,
      'estoque_minimo': 5,
      'criado_em': 1000,
      'atualizado_em': 1000,
    });
    await db.insert('medicamento_horarios', {
      'medicamento_id': 'med-v3',
      'hora': '08:00',
      'ordem': 0,
    });
    await db.insert('registros_dose', {
      'id': '2026-10-16_med-v3_08:00',
      'medicamento_id': 'med-v3',
      'data': '2026-10-16',
      'horario': '08:00',
      'status': 'tomada',
      'silenciada': 0,
      'extra': 0,
      'registrado_em': 2000,
    });

    await AppDatabase.migrate(db, 3, 4);

    expect(AppDatabase.databaseVersion, 4);

    final medRows = await db.query('medicamentos', where: 'id = ?', whereArgs: ['med-v3']);
    expect(medRows, hasLength(1));
    expect((medRows.first['estoque_atual'] as num).toDouble(), 30.0);

    // Aceita atualização fracionária e preserva como REAL
    await db.update(
      'medicamentos',
      {'estoque_atual': 27.5},
      where: 'id = ?',
      whereArgs: ['med-v3'],
    );
    final medAfter = await db.query('medicamentos', where: 'id = ?', whereArgs: ['med-v3']);
    expect(medAfter.first['estoque_atual'], 27.5);

    // Verifica coluna estoque_consumido nas doses legadas
    final doseRows = await db.query('registros_dose', where: 'id = ?', whereArgs: ['2026-10-16_med-v3_08:00']);
    expect(doseRows, hasLength(1));
    expect(doseRows.first.containsKey('estoque_consumido'), isTrue);
    expect((doseRows.first['estoque_consumido'] as num).toDouble(), 0.0);

    // Verifica que medicamento_horarios continua intacta
    final horarioRows = await db.query('medicamento_horarios', where: 'medicamento_id = ?', whereArgs: ['med-v3']);
    expect(horarioRows, hasLength(1));
    expect(horarioRows.first['hora'], '08:00');

    // Idempotência: chamar migrate(db, 4, 4) não falha nem duplica linhas
    await AppDatabase.migrate(db, 4, 4);
    expect(await db.query('medicamentos'), hasLength(1));

    await db.close();
  });
}

