import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../../medicamentos/domain/schedule_calculator.dart';
import '../../medicamentos/models/medicamento.dart';

enum StatusDose { pendente, tomada, pulada }

/// Formata uma [DateTime] em string ISO `YYYY-MM-DD` para indexação no SQLite.
String formatarDataIso(DateTime data) {
  final y = data.year.toString().padLeft(4, '0');
  final m = data.month.toString().padLeft(2, '0');
  final d = data.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class RegistroDose extends Equatable {
  final String id;
  final String medicamentoId;
  final String data;
  final TimeOfDay horario;
  final StatusDose status;
  final bool silenciada;
  final bool extra;
  final double estoqueConsumido;
  final int registradoEm;

  const RegistroDose({
    required this.id,
    required this.medicamentoId,
    required this.data,
    required this.horario,
    required this.status,
    this.silenciada = false,
    this.extra = false,
    this.estoqueConsumido = 0,
    required this.registradoEm,
  });

  static String gerarIdAgendado(String dataIso, String medicamentoId, TimeOfDay horario) {
    return '${dataIso}_${medicamentoId}_${ScheduleCalculator.formatar(horario)}';
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'medicamento_id': medicamentoId,
      'data': data,
      'horario': ScheduleCalculator.formatar(horario),
      'status': status.name,
      'silenciada': silenciada ? 1 : 0,
      'extra': extra ? 1 : 0,
      'estoque_consumido': estoqueConsumido,
      'registrado_em': registradoEm,
    };
  }

  factory RegistroDose.fromRow(Map<String, Object?> row) {
    return RegistroDose(
      id: row['id']! as String,
      medicamentoId: row['medicamento_id']! as String,
      data: row['data']! as String,
      horario: ScheduleCalculator.parse(row['horario']! as String),
      status: StatusDose.values.byName(row['status']! as String),
      silenciada: ((row['silenciada'] as int?) ?? 0) == 1,
      extra: (row['extra']! as int) == 1,
      estoqueConsumido: ((row['estoque_consumido'] as num?) ?? 0).toDouble(),
      registradoEm: row['registrado_em']! as int,
    );
  }

  @override
  List<Object?> get props => [
        id,
        medicamentoId,
        data,
        horario,
        status,
        silenciada,
        extra,
        estoqueConsumido,
        registradoEm,
      ];
}

class ItemDoseDia extends Equatable {
  final Medicamento medicamento;
  final TimeOfDay horario;
  final StatusDose status;
  final bool silenciada;
  final String? registroId;
  final bool extra;

  const ItemDoseDia({
    required this.medicamento,
    required this.horario,
    this.status = StatusDose.pendente,
    this.silenciada = false,
    this.registroId,
    this.extra = false,
  });

  bool get isTomada => status == StatusDose.tomada;
  bool get isPulada => status == StatusDose.pulada;

  @override
  List<Object?> get props => [
        medicamento,
        horario,
        status,
        silenciada,
        registroId,
        extra,
      ];
}

class GrupoHorarioDoses extends Equatable {
  final TimeOfDay horario;
  final List<ItemDoseDia> itens;

  const GrupoHorarioDoses({
    required this.horario,
    required this.itens,
  });

  bool get todasTomadas =>
      itens.isNotEmpty && itens.every((item) => item.status == StatusDose.tomada);

  bool get todosAlarmesSilenciados =>
      itens.isNotEmpty && itens.every((item) => item.silenciada);

  @override
  List<Object?> get props => [horario, itens];
}
