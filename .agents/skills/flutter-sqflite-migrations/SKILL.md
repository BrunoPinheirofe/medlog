---
name: flutter-sqflite-migrations
description: Create, update, and test SQLite database schema migrations in Flutter using `sqflite` and `sqflite_common_ffi`. Use when adding or modifying tables, columns, indexes, or database versions in `AppDatabase` (`lib/core/database/app_database.dart`).
---

# Flutter SQLite (`sqflite`) Migrations

Follow these rules whenever a task changes the SQLite schema (new tables, new columns, indexes, or data migrations) after version 1.

## Core Rules

1. **Dual-Path Consistency (`onCreate` + `onUpgrade`)**:
   - **Fresh installs (`onCreate` / `createSchema`)** must create the latest schema directly at `databaseVersion`.
   - **Existing installs (`onUpgrade`)** must transition step-by-step from any `oldVersion` up to `newVersion` using sequential `if (oldVersion < X)` blocks.
2. **Never Edit Released Migrations**:
   - Once a version `N` is released, its migration block `if (oldVersion < N)` is immutable. Any new change must increment `databaseVersion` to `N + 1` and add `if (oldVersion < N + 1)`.
3. **Sequential `if` Blocks (Never `switch` without fallthrough or `else if`)**:
   - Always use independent `if (oldVersion < 2)`, `if (oldVersion < 3)`, etc., in ascending order so a user upgrading from v1 to v3 runs both steps in sequence.
4. **SQLite `ALTER TABLE` Constraints**:
   - Adding a `NOT NULL` column to an existing table **requires** a `DEFAULT` clause (e.g., `ALTER TABLE medicamentos ADD COLUMN ativo INTEGER NOT NULL DEFAULT 1;`), otherwise SQLite fails on existing rows.
   - Foreign keys in `ADD COLUMN ... REFERENCES ...` must be compatible with existing rows (`NULL` or valid reference).
5. **Remove `shortcut:` Marker on First Migration**:
   - When implementing the first migration (moving `databaseVersion` from `1` to `2`), remove the `// shortcut:` comment in `AppDatabase` and make `onUpgrade` testable (e.g., `static Future<void> migrate(Database db, int oldVersion, int newVersion)`).

---

## Implementation Workflow

Copy and follow this checklist when modifying the database schema:

- [ ] 1. Increment `AppDatabase.databaseVersion` in `lib/core/database/app_database.dart`.
- [ ] 2. Update `AppDatabase.createSchema(Database db)` to reflect the final schema for new installations.
- [ ] 3. Add a sequential `if (oldVersion < <new_version>)` block inside `onUpgrade` / `migrate` with the incremental `ALTER TABLE` / `CREATE TABLE` statements.
- [ ] 4. Update affected models and repositories (`toMap` / `fromMap` / queries).
- [ ] 5. Add a migration test using `sqflite_common_ffi` (`inMemoryDatabasePath`) verifying that a database created at `oldVersion` with existing rows upgrades cleanly to `databaseVersion` without data loss, and that `createSchema` produces the same table structure.
- [ ] 6. Run `flutter test` and `dart analyze`.

---

## Code Pattern (`lib/core/database/app_database.dart`)

```dart
class AppDatabase {
  AppDatabase._();

  static const String databaseName = 'medlog.db';
  static const int databaseVersion = 3; // Incremented on each schema change

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

  /// Creates the full latest schema for fresh installs.
  static Future<void> createSchema(Database db) async {
    // Latest table definitions (including columns added in v2, v3, etc.)
  }

  /// Runs incremental migrations from [oldVersion] to [newVersion].
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE medicamentos ADD COLUMN observacoes TEXT;',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE registro_doses (
          id TEXT PRIMARY KEY,
          medicamento_id TEXT NOT NULL REFERENCES medicamentos(id) ON DELETE CASCADE,
          horario_previsto INTEGER NOT NULL,
          tomado_em INTEGER
        );
      ''');
    }
  }
}
```

---

## Testing Migrations Pattern (`test/core/database/app_database_migration_test.dart`)

Always test migrations with `sqflite_common_ffi` in memory by:
1. Creating the V1 schema and inserting sample records.
2. Calling `AppDatabase.migrate(db, 1, AppDatabase.databaseVersion)`.
3. Asserting that pre-existing records remain intact and new columns/tables work as expected.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:medlog/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('migrates from v1 to latest preserving existing rows', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: AppDatabase.configureForeignKeys,
        onCreate: (db, _) async {
          // V1 schema snapshot
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

    final rows = await db.query('medicamentos', where: 'id = ?', whereArgs: ['med-1']);
    expect(rows, hasLength(1));
    expect(rows.first['nome'], 'Dipirona');

    await db.close();
  });
}
```
