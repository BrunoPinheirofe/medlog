import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../models/medicamento.dart';

/// Unidades farmacológicas que expressam a concentração do princípio ativo
/// (massa/potência) e não a quantidade de unidades físicas descontadas do estoque
/// quando o medicamento está em forma sólida/unitária.
const Set<String> _unidadesConcentracao = {
  'mg',
  'mcg',
  'g',
  'ui',
};

/// Unidades que expressam consumo direto do saldo de estoque.
const Set<String> _unidadesConsumoDireto = {
  'ml',
  'gota',
  'gotas',
  'comprimido',
  'comprimidos',
  'capsula',
  'capsulas',
  'cápsula',
  'cápsulas',
  'dose',
  'doses',
  'jato',
  'jatos',
  'ampola',
  'ampolas',
  'un',
  'un.',
  'unidade',
  'unidades',
};

/// Calcula a quantidade de unidades do estoque consumida em UMA tomada de [medicamento].
///
/// Regras (FR-001):
/// - Se `doseValor` for nulo ou `<= 0`, retorna `1.0`.
/// - Se a unidade indicar consumo direto do saldo (`ml`, `gotas`, `comprimido`, etc.),
///   retorna `doseValor`.
/// - Se a unidade indicar concentração farmacológica (`mg`, `mcg`, `g`, `UI`) em formas
///   não-líquidas (ex: comprimido de 500 mg), retorna `1.0` unidade física.
/// - Se a forma for líquida ou gotas (`FormaMedicamento.gota` ou `FormaMedicamento.liquido`)
///   e a unidade não for uma unidade de concentração, retorna `doseValor`.
/// - Caso contrário, retorna `1.0` por padrão seguro.
double quantidadeConsumidaPorDose(Medicamento medicamento) {
  final valor = medicamento.doseValor;
  if (valor == null || valor <= 0) {
    return 1.0;
  }

  final unidadeNormalizada = (medicamento.doseUnidade ?? '').trim().toLowerCase();

  if (_unidadesConsumoDireto.contains(unidadeNormalizada)) {
    return valor;
  }

  if (_unidadesConcentracao.contains(unidadeNormalizada)) {
    return 1.0;
  }

  if (medicamento.forma == FormaMedicamento.gota ||
      medicamento.forma == FormaMedicamento.liquido) {
    return valor;
  }

  return 1.0;
}

/// Formata um valor numérico de estoque exibindo números inteiros sem casas decimais
/// (ex: `30.0` → `"30"`) e números fracionados com vírgula decimal no padrão pt-BR
/// sem zeros finais desnecessários (ex: `12.50` → `"12,5"`, `0.25` → `"0,25"`).
String formatarEstoque(double valor) {
  final arredondado = (valor * 100).roundToDouble() / 100;
  if (arredondado % 1 == 0) {
    return arredondado.toInt().toString();
  }
  var texto = arredondado.toStringAsFixed(2);
  while (texto.endsWith('0')) {
    texto = texto.substring(0, texto.length - 1);
  }
  if (texto.endsWith('.')) {
    texto = texto.substring(0, texto.length - 1);
  }
  return texto.replaceAll('.', ',');
}

/// Razão pela qual um medicamento entrou em alerta de reposição de estoque.
enum MotivoAlertaEstoque {
  /// `estoqueAtual <= estoqueMinimo` (FR-001).
  abaixoDoMinimo,

  /// Tratamento temporário com `estoqueAtual < consumoRestanteAteFim` (FR-004).
  insuficienteAteFimTratamento,
}

/// Projeção de domínio representando um aviso de reposição de estoque na tela Hoje.
class AlertaEstoqueBaixo extends Equatable {
  final Medicamento medicamento;
  final MotivoAlertaEstoque motivo;
  final double estoqueNecessario;
  final double folga;
  final String mensagem;

  const AlertaEstoqueBaixo({
    required this.medicamento,
    required this.motivo,
    required this.estoqueNecessario,
    required this.folga,
    required this.mensagem,
  });

  @override
  List<Object?> get props => [
        medicamento,
        motivo,
        estoqueNecessario,
        folga,
        mensagem,
      ];
}

/// Retorna a unidade textual correspondente à [forma] farmacêutica no singular ou plural.
String unidadeFormaEstoque(
  FormaMedicamento forma, {
  required bool singular,
  String? doseUnidade,
}) {
  final unidadeNorm = (doseUnidade ?? '').trim().toLowerCase();
  switch (forma) {
    case FormaMedicamento.comprimido:
      return singular ? 'comprimido' : 'comprimidos';
    case FormaMedicamento.capsula:
      return singular ? 'cápsula' : 'cápsulas';
    case FormaMedicamento.gota:
      return singular ? 'gota' : 'gotas';
    case FormaMedicamento.liquido:
      if (unidadeNorm == 'gota' || unidadeNorm == 'gotas') {
        return singular ? 'gota' : 'gotas';
      }
      return 'ml';
    case FormaMedicamento.injetavel:
      return singular ? 'ampola' : 'ampolas';
    case FormaMedicamento.spray:
      return singular ? 'dose' : 'doses';
    case FormaMedicamento.pomada:
    case FormaMedicamento.outro:
      return singular ? 'unidade' : 'unidades';
  }
}

/// Formata a mensagem padrão do banner de estoque baixo (FR-002):
/// - Singular (`estoqueAtual == 1`): `"Atenção: Resta apenas 1 <unidade>. Hora de comprar!"`
/// - Plural (demais valores): `"Atenção: Restam apenas <X> <unidades>. Hora de comprar!"`
String formatarMensagemEstoqueBaixo(Medicamento medicamento) {
  final arredondado = (medicamento.estoqueAtual * 100).roundToDouble() / 100;
  final singular = arredondado == 1.0;
  final quantidade = formatarEstoque(arredondado);
  final unidade = unidadeFormaEstoque(
    medicamento.forma,
    singular: singular,
    doseUnidade: medicamento.doseUnidade,
  );
  if (singular) {
    return 'Atenção: Resta apenas $quantidade $unidade. Hora de comprar!';
  }
  return 'Atenção: Restam apenas $quantidade $unidade. Hora de comprar!';
}

/// Avalia todos os [medicamentos] na [dataReferencia] e retorna os alertas de estoque
/// baixo ordenados pelo mais urgente (menor `folga`).
///
/// [dosesConcluidasNoDiaPorMedicamento] informa quantas doses agendadas na
/// [dataReferencia] já foram marcadas como tomadas ou puladas para cada `medicamento.id`.
List<AlertaEstoqueBaixo> calcularAlertasEstoqueBaixo({
  required List<Medicamento> medicamentos,
  required DateTime dataReferencia,
  Map<String, int> dosesConcluidasNoDiaPorMedicamento = const {},
}) {
  final alvoUtc = DateTime.utc(
    dataReferencia.year,
    dataReferencia.month,
    dataReferencia.day,
  );
  final alertas = <AlertaEstoqueBaixo>[];

  for (final med in medicamentos) {
    if (!med.estaAtivoNaData(dataReferencia)) continue;

    final bool abaixoDoMinimo =
        med.estoqueMinimo >= 0 && med.estoqueAtual <= med.estoqueMinimo;

    double consumoRestanteAteFim = 0.0;
    bool insuficienteAteFim = false;

    if (!med.usoContinuo &&
        med.duracaoDias != null &&
        med.duracaoDias! > 0 &&
        med.horarios.isNotEmpty) {
      final baseInicio = med.dataInicio ?? dataReferencia;
      final inicioUtc = DateTime.utc(
        baseInicio.year,
        baseInicio.month,
        baseInicio.day,
      );
      final fimUtc = DateTime.utc(
        inicioUtc.year,
        inicioUtc.month,
        inicioUtc.day + med.duracaoDias! - 1,
      );
      final diasFuturos = math.max(0, fimUtc.difference(alvoUtc).inDays);
      final dosesPorDia = med.horarios.length;
      final concluidasHoje = dosesConcluidasNoDiaPorMedicamento[med.id] ?? 0;
      final dosesRestantesHoje = math.max(0, dosesPorDia - concluidasHoje);
      final dosesRestantesTotal =
          dosesRestantesHoje + (diasFuturos * dosesPorDia);
      consumoRestanteAteFim =
          dosesRestantesTotal * quantidadeConsumidaPorDose(med);
      if (med.estoqueAtual < consumoRestanteAteFim) {
        insuficienteAteFim = true;
      }
    }

    if (!abaixoDoMinimo && !insuficienteAteFim) continue;

    final limiarMinimo = math.max(0, med.estoqueMinimo).toDouble();
    final estoqueNecessario = math.max(limiarMinimo, consumoRestanteAteFim);
    final folga = med.estoqueAtual - estoqueNecessario;
    final motivo = abaixoDoMinimo
        ? MotivoAlertaEstoque.abaixoDoMinimo
        : MotivoAlertaEstoque.insuficienteAteFimTratamento;

    alertas.add(
      AlertaEstoqueBaixo(
        medicamento: med,
        motivo: motivo,
        estoqueNecessario: estoqueNecessario,
        folga: folga,
        mensagem: formatarMensagemEstoqueBaixo(med),
      ),
    );
  }

  alertas.sort((a, b) {
    final cmpFolga = a.folga.compareTo(b.folga);
    if (cmpFolga != 0) return cmpFolga;
    final cmpEstoque =
        a.medicamento.estoqueAtual.compareTo(b.medicamento.estoqueAtual);
    if (cmpEstoque != 0) return cmpEstoque;
    final cmpNome = a.medicamento.nome
        .toLowerCase()
        .compareTo(b.medicamento.nome.toLowerCase());
    if (cmpNome != 0) return cmpNome;
    return a.medicamento.id.compareTo(b.medicamento.id);
  });

  return alertas;
}
