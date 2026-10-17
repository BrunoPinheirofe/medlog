import '../domain/schedule_calculator.dart';
import '../models/medicamento.dart';

/// Converte [Medicamento] de/para linhas do SQLite. Fica na camada de dados
/// para o modelo continuar puro, sem conhecimento do mecanismo de persistência.

String _formatarDataIso(DateTime data) {
  final y = data.year.toString().padLeft(4, '0');
  final m = data.month.toString().padLeft(2, '0');
  final d = data.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime _parseDataInicio(String? dataIso, int criadoEm) {
  if (dataIso != null && dataIso.trim().isNotEmpty) {
    final partes = dataIso.trim().split('-');
    if (partes.length == 3) {
      final y = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      final d = int.tryParse(partes[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
  }
  final dt = DateTime.fromMillisecondsSinceEpoch(criadoEm);
  return DateTime(dt.year, dt.month, dt.day);
}

extension MedicamentoRowX on Medicamento {
  /// Linha da tabela `medicamentos`.
  Map<String, Object?> toRow({required int criadoEm, required int atualizadoEm}) {
    String? textoOpcional(String? valor) {
      final v = valor?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final inicioEfetivo =
        dataInicio ?? DateTime.fromMillisecondsSinceEpoch(criadoEm);

    return <String, Object?>{
      'id': id,
      'nome': nome,
      'forma': forma.name,
      'frequencia': frequencia.name,
      'dose_valor': doseValor,
      'dose_unidade': textoOpcional(doseUnidade),
      'cor_hex': corHex,
      'uso_continuo': usoContinuo ? 1 : 0,
      'duracao_dias': duracaoDias,
      'data_inicio': _formatarDataIso(inicioEfetivo),
      'instrucoes': textoOpcional(instrucoes),
      'intervalo_horas': intervaloHoras,
      'estoque_atual': estoqueAtual,
      'estoque_minimo': estoqueMinimo,
      'foto_url': fotoUrl,
      'criado_em': criadoEm,
      'atualizado_em': atualizadoEm,
    };
  }

  /// Linha da tabela `medicamento_horarios` para o horário na [ordem] dada.
  Map<String, Object?> horarioToRow(int ordem) {
    return <String, Object?>{
      'medicamento_id': id,
      'hora': ScheduleCalculator.formatar(horarios[ordem]),
      'ordem': ordem,
    };
  }
}

/// Reconstrói um [Medicamento] a partir da linha da tabela `medicamentos`.
Medicamento medicamentoFromRow(
  Map<String, Object?> row,
  List<Map<String, Object?>> horarioRows,
) {
  final criadoEm = row['criado_em']! as int;
  return Medicamento(
    id: row['id']! as String,
    nome: row['nome']! as String,
    forma: FormaMedicamento.values.firstWhere(
      (f) => f.name == row['forma'],
      orElse: () => FormaMedicamento.outro,
    ),
    frequencia: Frequencia.values.byName(row['frequencia']! as String),
    doseValor: (row['dose_valor'] as num?)?.toDouble(),
    doseUnidade: row['dose_unidade'] as String?,
    corHex: row['cor_hex'] as int?,
    usoContinuo: (row['uso_continuo']! as int) == 1,
    duracaoDias: row['duracao_dias'] as int?,
    dataInicio: _parseDataInicio(row['data_inicio'] as String?, criadoEm),
    instrucoes: row['instrucoes'] as String?,
    intervaloHoras: row['intervalo_horas'] as int?,
    horarios: [
      for (final linha in horarioRows) ScheduleCalculator.parse(linha['hora']! as String),
    ],
    estoqueAtual: row['estoque_atual']! as int,
    estoqueMinimo: row['estoque_minimo']! as int,
    fotoUrl: row['foto_url'] as String?,
  );
}
