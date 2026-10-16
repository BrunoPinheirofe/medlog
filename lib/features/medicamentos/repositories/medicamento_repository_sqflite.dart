import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../data/medicamento_mappers.dart';
import '../models/medicamento.dart';
import 'medicamento_repository.dart';

/// Implementação do contrato sobre sqflite. Medicamento e horários são
/// gravados juntos numa transação: ou persiste tudo, ou nada.
class MedicamentoRepositorySqflite implements MedicamentoRepository {
  MedicamentoRepositorySqflite({Future<Database> Function()? databaseProvider})
      : _databaseProvider = databaseProvider ?? AppDatabase.database;

  final Future<Database> Function() _databaseProvider;

  @override
  Future<void> save(Medicamento medicamento) async {
    final Database db = await _databaseProvider();
    final int agora = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      // Upsert preservando criado_em de registros anteriores.
      final List<Map<String, Object?>> existentes = await txn.query(
        'medicamentos',
        columns: ['criado_em'],
        where: 'id = ?',
        whereArgs: [medicamento.id],
      );
      final int criadoEm = existentes.isEmpty ? agora : existentes.first['criado_em']! as int;

      await txn.insert(
        'medicamentos',
        medicamento.toRow(criadoEm: criadoEm, atualizadoEm: agora),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Horários são reescritos por completo a cada salvamento.
      await txn.delete(
        'medicamento_horarios',
        where: 'medicamento_id = ?',
        whereArgs: [medicamento.id],
      );
      for (var i = 0; i < medicamento.horarios.length; i++) {
        await txn.insert('medicamento_horarios', medicamento.horarioToRow(i));
      }
    });
  }

  @override
  Future<List<Medicamento>> getAll() async {
    final Database db = await _databaseProvider();
    final List<Map<String, Object?>> rows = await db.query(
      'medicamentos',
      orderBy: 'criado_em DESC, id DESC',
    );
    if (rows.isEmpty) return const [];

    final List<String> ids = rows.map((r) => r['id']! as String).toList();
    final List<Map<String, Object?>> horarioRows = await db.query(
      'medicamento_horarios',
      where: 'medicamento_id IN (${List.filled(ids.length, '?').join(', ')})',
      whereArgs: ids,
      orderBy: 'medicamento_id, ordem',
    );

    final Map<String, List<Map<String, Object?>>> horariosPorId = {};
    for (final row in horarioRows) {
      (horariosPorId[row['medicamento_id']! as String] ??= []).add(row);
    }

    return [
      for (final row in rows)
        medicamentoFromRow(row, horariosPorId[row['id']! as String] ?? const []),
    ];
  }

  @override
  Future<Medicamento?> getById(String id) async {
    final Database db = await _databaseProvider();
    final List<Map<String, Object?>> rows = await db.query(
      'medicamentos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;

    final List<Map<String, Object?>> horarioRows = await db.query(
      'medicamento_horarios',
      where: 'medicamento_id = ?',
      whereArgs: [id],
      orderBy: 'ordem',
    );
    return medicamentoFromRow(rows.first, horarioRows);
  }

  @override
  Future<void> delete(String id) async {
    final Database db = await _databaseProvider();
    await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateEstoque(String id, int estoqueAtual, int estoqueMinimo) async {
    final Database db = await _databaseProvider();
    await db.update(
      'medicamentos',
      {'estoque_atual': estoqueAtual, 'estoque_minimo': estoqueMinimo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
