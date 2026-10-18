import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../medicamentos/domain/estoque_dose_calculator.dart';
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
      final double consumidoAnterior = existentes.isEmpty
          ? 0.0
          : ((existentes.first['estoque_consumido'] as num?) ?? 0).toDouble();

      if (statusAnterior == novoStatus) return;

      double novoConsumido = 0.0;
      if (statusAnterior != StatusDose.tomada && novoStatus == StatusDose.tomada) {
        final dosePadrao = quantidadeConsumidaPorDose(medicamento);
        novoConsumido = await _baixarEstoque(txn, medicamento.id, dosePadrao);
      } else if (statusAnterior == StatusDose.tomada && novoStatus != StatusDose.tomada) {
        final valorEstorno = consumidoAnterior > 0
            ? consumidoAnterior
            : await _calcularEstornoRegistroSemConsumoGravado(txn, medicamento);
        await _estornarEstoque(txn, medicamento.id, valorEstorno);
      }

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
          estoqueConsumido: novoConsumido,
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
      final double consumidoAtual = existentes.isEmpty
          ? 0.0
          : ((existentes.first['estoque_consumido'] as num?) ?? 0).toDouble();

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
          estoqueConsumido: consumidoAtual,
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

    await db.transaction((txn) async {
      final dosePadrao = quantidadeConsumidaPorDose(medicamento);
      final consumido = await _baixarEstoque(txn, medicamento.id, dosePadrao);
      final registro = RegistroDose(
        id: 'extra_${agora}_${medicamento.id}',
        medicamentoId: medicamento.id,
        data: dataIso,
        horario: horario,
        status: StatusDose.tomada,
        extra: true,
        estoqueConsumido: consumido,
        registradoEm: agora,
      );
      await txn.insert('registros_dose', registro.toRow());
    });
  }

  @override
  Future<void> removerDoseExtra({
    required String registroId,
    required String medicamentoId,
  }) async {
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      final existentes = await txn.query(
        'registros_dose',
        where: 'id = ?',
        whereArgs: [registroId],
      );
      final deletados = await txn.delete(
        'registros_dose',
        where: 'id = ?',
        whereArgs: [registroId],
      );
      if (deletados > 0 && existentes.isNotEmpty) {
        final consumido = ((existentes.first['estoque_consumido'] as num?) ?? 0).toDouble();
        if (consumido > 0) {
          await _estornarEstoque(txn, medicamentoId, consumido);
        }
      }
    });
  }

  /// Subtrai até [quantidade] do estoque atual, respeitando o piso `0.0`,
  /// e retorna a quantidade efetivamente descontada.
  Future<double> _baixarEstoque(
    Transaction txn,
    String medicamentoId,
    double quantidade,
  ) async {
    final rows = await txn.query(
      'medicamentos',
      columns: ['estoque_atual'],
      where: 'id = ?',
      whereArgs: [medicamentoId],
    );
    if (rows.isEmpty) return 0.0;
    final atual = (rows.first['estoque_atual']! as num).toDouble();
    final efetivo = math.max(0.0, math.min(quantidade, atual));
    final novoEstoque = _arredondarEstoque(math.max(0.0, atual - efetivo));
    await txn.update(
      'medicamentos',
      {'estoque_atual': novoEstoque},
      where: 'id = ?',
      whereArgs: [medicamentoId],
    );
    return _arredondarEstoque(efetivo);
  }

  Future<void> _estornarEstoque(
    Transaction txn,
    String medicamentoId,
    double quantidade,
  ) async {
    if (quantidade <= 0) return;
    final rows = await txn.query(
      'medicamentos',
      columns: ['estoque_atual'],
      where: 'id = ?',
      whereArgs: [medicamentoId],
    );
    if (rows.isEmpty) return;
    final atual = (rows.first['estoque_atual']! as num).toDouble();
    final novoEstoque = _arredondarEstoque(atual + quantidade);
    await txn.update(
      'medicamentos',
      {'estoque_atual': novoEstoque},
      where: 'id = ?',
      whereArgs: [medicamentoId],
    );
  }

  /// Para registros com `estoque_consumido == 0`: se o estoque do medicamento já era `0.0`
  /// quando a dose foi tomada na v4, a dedução efetiva foi `0.0` (não estorna estoque fantasma).
  /// Já para registros herdados da v3 (onde `estoque_atual > 0` após a migração),
  /// usa o fallback `quantidadeConsumidaPorDose(medicamento)`.
  Future<double> _calcularEstornoRegistroSemConsumoGravado(
    Transaction txn,
    Medicamento medicamento,
  ) async {
    final rows = await txn.query(
      'medicamentos',
      columns: ['estoque_atual'],
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
    if (rows.isEmpty) return 0.0;
    final atual = (rows.first['estoque_atual']! as num).toDouble();
    if (atual <= 0) return 0.0;
    return quantidadeConsumidaPorDose(medicamento);
  }

  static double _arredondarEstoque(double valor) {
    return (valor * 100).roundToDouble() / 100;
  }
}
