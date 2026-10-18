import 'package:material_ui/material_ui.dart';

import '../../medicamentos/models/medicamento.dart';
import '../models/registro_dose.dart';

abstract class DoseRepository {
  /// Retorna todos os registros de dose da [dataIso] (`YYYY-MM-DD`).
  Future<List<RegistroDose>> getByData(String dataIso);

  /// Registra ou atualiza o status de uma dose agendada e ajusta o estoque
  /// descontando a dose consumida ao marcar como tomada (piso 0) e estornando
  /// o valor efetivamente descontado ao sair de tomada.
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

  /// Registra uma dose extra/SOS no horário informado e desconta a dose consumida do estoque.
  Future<void> registrarDoseExtra({
    required Medicamento medicamento,
    required String dataIso,
    required TimeOfDay horario,
  });

  /// Remove uma dose extra/SOS e devolve a quantidade descontada ao estoque.
  Future<void> removerDoseExtra({
    required String registroId,
    required String medicamentoId,
  });
}
