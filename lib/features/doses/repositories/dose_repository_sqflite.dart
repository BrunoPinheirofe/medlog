import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../medicamentos/models/medicamento.dart';
import '../models/registro_dose.dart';
import 'dose_repository.dart';

class DoseRepositorySqflite implements DoseRepository {
  DoseRepositorySqflite({Future<Database> Function()? databaseProvider})
      : _databaseProvider = databaseProvider ?? AppDatabase.database;

  final Future<Database> Function() _databaseProvider;

  @override
  Future<List<RegistroDose>> getByData(String dataIso) async {
    final db = await _databaseProvider();
    final rows = await db.query(
      'registros_dose',
      where: 'data = ?',
      whereArgs: [dataIso],
      orderBy: 'horario ASC, registrado_em ASC',
    );
    return [for (final row in rows) RegistroDose.fromRow(row)];
  }

  @override
  Future<void> registrarStatusDose({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
    required StatusDose novoStatus,
  }) async {
    final db = await _databaseProvider();
    final id = RegistroDose.gerarIdAgendado(dataIso, medicamento.id, horario);
    final agora = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final existentes = await txn.query(
        'registros_dose',
        where: 'id = ?',
        whereArgs: [id],
      );
      final StatusDose statusAnterior = existentes.isEmpty
          ? StatusDose.pendente
          : StatusDose.values.byName(existentes.first['status']! as String);
      final bool silenciadaAnterior = existentes.isNotEmpty &&
          ((existentes.first['silenciada'] as int?) ?? 0) == 1;

      if (statusAnterior == novoStatus) return;

      if (novoStatus == StatusDose.pendente && !silenciadaAnterior) {
        await txn.delete('registros_dose', where: 'id = ?', whereArgs: [id]);
      } else {
        final registro = RegistroDose(
          id: id,
          medicamentoId: medicamento.id,
          data: dataIso,
          horario: horario,
          status: novoStatus,
          silenciada: silenciadaAnterior,
          extra: false,
          registradoEm: agora,
        );
        await txn.insert(
          'registros_dose',
          registro.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Ajuste de estoque: -1 ao passar para tomada; +1 ao sair de tomada.
      if (statusAnterior != StatusDose.tomada && novoStatus == StatusDose.tomada) {
        await _ajustarEstoque(txn, medicamento.id, -1);
      } else if (statusAnterior == StatusDose.tomada && novoStatus != StatusDose.tomada) {
        await _ajustarEstoque(txn, medicamento.id, 1);
      }
    });
  }

  @override
  Future<void> registrarSilenciarDose({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
    required bool silenciada,
  }) async {
    final db = await _databaseProvider();
    final id = RegistroDose.gerarIdAgendado(dataIso, medicamento.id, horario);
    final agora = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final existentes = await txn.query(
        'registros_dose',
        where: 'id = ?',
        whereArgs: [id],
      );
      final StatusDose statusAtual = existentes.isEmpty
          ? StatusDose.pendente
          : StatusDose.values.byName(existentes.first['status']! as String);

      if (statusAtual == StatusDose.pendente && !silenciada) {
        await txn.delete('registros_dose', where: 'id = ?', whereArgs: [id]);
      } else {
        final registro = RegistroDose(
          id: id,
          medicamentoId: medicamento.id,
          data: dataIso,
          horario: horario,
          status: statusAtual,
          silenciada: silenciada,
          extra: false,
          registradoEm: agora,
        );
        await txn.insert(
          'registros_dose',
          registro.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> registrarDoseExtra({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
  }) async {
    final db = await _databaseProvider();
    final agora = DateTime.now().millisecondsSinceEpoch;
    final registro = RegistroDose(
      id: 'extra_${agora}_${medicamento.id}',
      medicamentoId: medicamento.id,
      data: dataIso,
      horario: horario,
      status: StatusDose.tomada,
      extra: true,
      registradoEm: agora,
    );

    await db.transaction((txn) async {
      await txn.insert('registros_dose', registro.toRow());
      await _ajustarEstoque(txn, medicamento.id, -1);
    });
  }

  @override
  Future<void> removerDoseExtra({
    required String registroId,
    required String medicamentoId,
  }) async {
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      final deletados = await txn.delete(
        'registros_dose',
        where: 'id = ?',
        whereArgs: [registroId],
      );
      if (deletados > 0) {
        await _ajustarEstoque(txn, medicamentoId, 1);
      }
    });
  }

  Future<void> _ajustarEstoque(Transaction txn, String medicamentoId, int delta) async {
    final rows = await txn.query(
      'medicamentos',
      columns: ['estoque_atual'],
      where: 'id = ?',
      whereArgs: [medicamentoId],
    );
    if (rows.isEmpty) return;
    final atual = rows.first['estoque_atual']! as int;
    final novoEstoque = (atual + delta) < 0 ? 0 : (atual + delta);
    await txn.update(
      'medicamentos',
      {'estoque_atual': novoEstoque},
      where: 'id = ?',
      whereArgs: [medicamentoId],
    );
  }
}
