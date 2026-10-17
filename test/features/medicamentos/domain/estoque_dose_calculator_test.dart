import 'package:flutter_test/flutter_test.dart';
import 'package:medlog/features/medicamentos/domain/estoque_dose_calculator.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

void main() {
  Medicamento criarMed({
    FormaMedicamento forma = FormaMedicamento.comprimido,
    double? doseValor,
    String? doseUnidade,
  }) {
    return Medicamento(
      id: 'm1',
      nome: 'Teste',
      forma: forma,
      doseValor: doseValor,
      doseUnidade: doseUnidade,
      frequencia: Frequencia.umaVez,
    );
  }

  group('quantidadeConsumidaPorDose', () {
    test('retorna doseValor quando unidade é gotas', () {
      final med = criarMed(
        forma: FormaMedicamento.gota,
        doseValor: 15,
        doseUnidade: 'gotas',
      );
      expect(quantidadeConsumidaPorDose(med), 15.0);
    });

    test('retorna doseValor fracionado quando unidade é ml', () {
      final med = criarMed(
        forma: FormaMedicamento.liquido,
        doseValor: 2.5,
        doseUnidade: 'ml',
      );
      expect(quantidadeConsumidaPorDose(med), 2.5);
    });

    test('retorna 1.0 para comprimido com unidade de concentração (500 mg, mcg, g, UI)', () {
      for (final unidade in ['mg', 'mcg', 'g', 'UI']) {
        final med = criarMed(
          forma: FormaMedicamento.comprimido,
          doseValor: 500,
          doseUnidade: unidade,
        );
        expect(quantidadeConsumidaPorDose(med), 1.0, reason: 'unidade: $unidade');
      }
    });

    test('retorna doseValor para comprimido quando unidade é comprimido (ex: 0.5 ou 2)', () {
      final meioComp = criarMed(
        forma: FormaMedicamento.comprimido,
        doseValor: 0.5,
        doseUnidade: 'comprimido',
      );
      final doisComp = criarMed(
        forma: FormaMedicamento.comprimido,
        doseValor: 2,
        doseUnidade: 'comprimido',
      );
      expect(quantidadeConsumidaPorDose(meioComp), 0.5);
      expect(quantidadeConsumidaPorDose(doisComp), 2.0);
    });

    test('retorna 1.0 quando doseValor é nulo ou menor/igual a zero', () {
      expect(quantidadeConsumidaPorDose(criarMed(doseValor: null, doseUnidade: 'ml')), 1.0);
      expect(quantidadeConsumidaPorDose(criarMed(doseValor: 0, doseUnidade: 'gotas')), 1.0);
      expect(quantidadeConsumidaPorDose(criarMed(doseValor: -2, doseUnidade: 'ml')), 1.0);
    });

    test('retorna doseValor para forma líquida ou gotas mesmo com unidade omitida', () {
      final gotaSemUnidade = criarMed(
        forma: FormaMedicamento.gota,
        doseValor: 10,
        doseUnidade: null,
      );
      final liquidoSemUnidade = criarMed(
        forma: FormaMedicamento.liquido,
        doseValor: 5.5,
        doseUnidade: '',
      );
      expect(quantidadeConsumidaPorDose(gotaSemUnidade), 10.0);
      expect(quantidadeConsumidaPorDose(liquidoSemUnidade), 5.5);
    });
  });

  group('formatarEstoque', () {
    test('formata inteiros sem casas decimais', () {
      expect(formatarEstoque(30.0), '30');
      expect(formatarEstoque(0.0), '0');
      expect(formatarEstoque(10), '10');
    });

    test('formata números fracionados com vírgula (pt-BR) sem zeros finais supérfluos', () {
      expect(formatarEstoque(12.5), '12,5');
      expect(formatarEstoque(97.50), '97,5');
      expect(formatarEstoque(0.25), '0,25');
    });
  });
}
