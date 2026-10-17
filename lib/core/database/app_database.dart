import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Conexão com o banco SQLite local: abre com cache, versiona e aplica migrations.
/// Use o tear-off [database] como [DatabaseProvider] padrão do app.
class AppDatabase {
  AppDatabase._();

  static const String databaseName = 'medlog.db';
  static const int databaseVersion = 4;

  static Future<Database>? _instance;

  /// Conexão única do app (aberta sob demanda), garantindo que migrations
  /// pendentes rodem mesmo quando a instância foi preservada por Hot Reload.
  static Future<Database> database() async {
    final db = await (_instance ??= _open());
    final currentVersion = await db.getVersion();
    if (currentVersion < databaseVersion) {
      await migrate(db, currentVersion, databaseVersion);
      await db.setVersion(databaseVersion);
    }
    return db;
  }

  static Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), databaseName);
    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: configureForeignKeys,
      onCreate: (db, version) => createSchema(db),
      onUpgrade: migrate,
    );
  }

  /// SQLiteDatabase só aplica foreign keys com o PRAGMA ativo em cada conexão.
  static void configureForeignKeys(Database db) {
    db.execute('PRAGMA foreign_keys = ON');
  }

  /// Cria o schema completo. Chamado pela [onCreate] e reutilizado nos testes
  /// com banco in-memory para reproduzir o schema real de produção.
  static Future<void> createSchema(Database db) async {
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
        estoque_atual REAL NOT NULL DEFAULT 0,
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

    await _createRegistrosDoseTable(db);
  }

  static Future<void> _createRegistrosDoseTable(Database db) async {
    await db.execute('''
      CREATE TABLE registros_dose (
        id TEXT PRIMARY KEY,
        medicamento_id TEXT NOT NULL REFERENCES medicamentos(id) ON DELETE CASCADE,
        data TEXT NOT NULL,
        horario TEXT NOT NULL,
        status TEXT NOT NULL,
        silenciada INTEGER NOT NULL DEFAULT 0,
        extra INTEGER NOT NULL DEFAULT 0,
        estoque_consumido REAL NOT NULL DEFAULT 0,
        registrado_em INTEGER NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_registros_dose_data ON registros_dose(data);',
    );
  }

  /// Executa migrations incrementais de [oldVersion] até [newVersion].
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createRegistrosDoseTable(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE medicamentos ADD COLUMN data_inicio TEXT;',
      );
      await db.execute('''
        UPDATE medicamentos
        SET data_inicio = strftime('%Y-%m-%d', criado_em / 1000, 'unixepoch', 'localtime')
        WHERE data_inicio IS NULL;
      ''');
    }
    if (oldVersion < 4 && newVersion >= 4) {
      await _migrateV3ParaV4(db);
    }
  }

  static Future<void> _migrateV3ParaV4(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE medicamentos_v4 (
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
            estoque_atual REAL NOT NULL DEFAULT 0,
            estoque_minimo INTEGER NOT NULL DEFAULT 5,
            foto_url TEXT,
            criado_em INTEGER NOT NULL,
            atualizado_em INTEGER NOT NULL
          );
        ''');

        await txn.execute('''
          INSERT INTO medicamentos_v4 (
            id, nome, forma, frequencia, dose_valor, dose_unidade, cor_hex,
            uso_continuo, duracao_dias, data_inicio, instrucoes, intervalo_horas,
            estoque_atual, estoque_minimo, foto_url, criado_em, atualizado_em
          )
          SELECT
            id, nome, forma, frequencia, dose_valor, dose_unidade, cor_hex,
            uso_continuo, duracao_dias, data_inicio, instrucoes, intervalo_horas,
            CAST(estoque_atual AS REAL), estoque_minimo, foto_url, criado_em, atualizado_em
          FROM medicamentos;
        ''');

        await txn.execute('DROP TABLE medicamentos;');
        await txn.execute('ALTER TABLE medicamentos_v4 RENAME TO medicamentos;');

        final cols = await txn.rawQuery('PRAGMA table_info(registros_dose);');
        final temEstoqueConsumido = cols.any((c) => c['name'] == 'estoque_consumido');
        if (!temEstoqueConsumido) {
          await txn.execute(
            'ALTER TABLE registros_dose ADD COLUMN estoque_consumido REAL NOT NULL DEFAULT 0;',
          );
        }

        final fkErrors = await txn.rawQuery('PRAGMA foreign_key_check;');
        if (fkErrors.isNotEmpty) {
          throw StateError('Falha na verificação de chaves estrangeiras na migração v4: $fkErrors');
        }
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }
  }
}
