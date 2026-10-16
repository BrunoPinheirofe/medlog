import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Conexão com o banco SQLite local: abre com cache, versiona e aplica migrations.
/// Use o tear-off [database] como [DatabaseProvider] padrão do app.
class AppDatabase {
  AppDatabase._();

  static const String databaseName = 'medlog.db';
  static const int databaseVersion = 1;

  static Future<Database>? _instance;

  /// Conexão única do app (aberta sob demanda).
  static Future<Database> database() => _instance ??= _open();

  static Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), databaseName);
    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: configureForeignKeys,
      onCreate: (db, version) => createSchema(db),
      onUpgrade: _onUpgrade,
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
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // shortcut: versão 1 sem migrations; ao subir a versão, adicione aqui um
    // passo por versão (ALTER TABLE / CREATE TABLE) antes de lançar a release.
  }
}
