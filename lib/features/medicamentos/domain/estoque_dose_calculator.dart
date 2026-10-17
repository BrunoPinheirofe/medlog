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
