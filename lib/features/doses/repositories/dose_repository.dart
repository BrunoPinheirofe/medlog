import 'package:material_ui/material_ui.dart';

import '../../medicamentos/models/medicamento.dart';
import '../models/registro_dose.dart';

abstract class DoseRepository {
  /// Retorna todos os registros de dose da [dataIso] (`YYYY-MM-DD`).
  Future<List<RegistroDose>> getByData(String dataIso);

  /// Registra ou atualiza o status de uma dose agendada e ajusta o estoque
  /// (`-1` ao marcar como tomada, `+1` ao sair de tomada).
  Future<void> registrarStatusDose({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
    required StatusDose novoStatus,
  });

  /// Silencia ou reativa o alarme de uma única dose específica `(medicamento, dataIso, horario)`.
  Future<void> registrarSilenciarDose({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
    required bool silenciada,
  });

  /// Registra uma dose extra/SOS no horário informado e desconta 1 unidade do estoque.
  Future<void> registrarDoseExtra({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
  });

  /// Remove uma dose extra/SOS e devolve 1 unidade ao estoque.
  Future<void> removerDoseExtra({
    required String registroId,
    required String medicamentoId,
  });
}
