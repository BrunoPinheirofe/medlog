import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

  group('formatarMensagemEstoqueBaixo', () {
    test('formata plural e singular de acordo com a forma do medicamento (FR-002)', () {
      const comp2 = Medicamento(
        id: '1',
        nome: 'Losartana',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 2,
        estoqueMinimo: 5,
      );
      expect(
        formatarMensagemEstoqueBaixo(comp2),
        'Atenção: Restam apenas 2 comprimidos. Hora de comprar!',
      );

      const comp1 = Medicamento(
        id: '1',
        nome: 'Losartana',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 1,
        estoqueMinimo: 5,
      );
      expect(
        formatarMensagemEstoqueBaixo(comp1),
        'Atenção: Resta apenas 1 comprimido. Hora de comprar!',
      );

      const comp0 = Medicamento(
        id: '1',
        nome: 'Losartana',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 0,
        estoqueMinimo: 5,
      );
      expect(
        formatarMensagemEstoqueBaixo(comp0),
        'Atenção: Restam apenas 0 comprimidos. Hora de comprar!',
      );

      const capsula = Medicamento(
        id: '2',
        nome: 'Omeprazol',
        forma: FormaMedicamento.capsula,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 3,
        estoqueMinimo: 5,
      );
      expect(
        formatarMensagemEstoqueBaixo(capsula),
        'Atenção: Restam apenas 3 cápsulas. Hora de comprar!',
      );

      const xarope = Medicamento(
        id: '3',
        nome: 'Xarope',
        forma: FormaMedicamento.liquido,
        doseValor: 2.5,
        doseUnidade: 'ml',
        frequencia: Frequencia.umaVez,
        estoqueAtual: 2.5,
        estoqueMinimo: 10,
      );
      expect(
        formatarMensagemEstoqueBaixo(xarope),
        'Atenção: Restam apenas 2,5 ml. Hora de comprar!',
      );
    });
  });

  group('calcularAlertasEstoqueBaixo', () {
    final hoje = DateTime(2026, 10, 19);

    test('US1: gera alerta quando estoqueAtual <= estoqueMinimo e omite quando acima', () {
      const abaixo = Medicamento(
        id: 'med-abaixo',
        nome: 'Losartana',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 2,
        estoqueMinimo: 5,
      );
      const igual = Medicamento(
        id: 'med-igual',
        nome: 'Atenolol',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 5,
        estoqueMinimo: 5,
      );
      const acima = Medicamento(
        id: 'med-acima',
        nome: 'Vitamina C',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 10,
        estoqueMinimo: 5,
      );

      final alertas = calcularAlertasEstoqueBaixo(
        medicamentos: const [acima, igual, abaixo],
        dataReferencia: hoje,
      );

      expect(alertas.map((a) => a.medicamento.id).toList(), ['med-abaixo', 'med-igual']);
      expect(alertas.first.motivo, MotivoAlertaEstoque.abaixoDoMinimo);
      expect(
        alertas.first.mensagem,
        'Atenção: Restam apenas 2 comprimidos. Hora de comprar!',
      );
    });

    test('US2: gera alerta para tratamento temporário quando estoque não cobre doses até dataFim mesmo acima do mínimo', () {
      // 3 dias de duração iniciando hoje (19, 20, 21/10) com 2 doses/dia = 6 doses restantes
      final antibioticoInsuficiente = Medicamento(
        id: 'med-temp-1',
        nome: 'Amoxicilina',
        forma: FormaMedicamento.comprimido,
        usoContinuo: false,
        duracaoDias: 3,
        dataInicio: hoje,
        frequencia: Frequencia.duasVezes,
        horarios: const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
        estoqueAtual: 4, // > estoqueMinimo (2), mas < 6 doses necessárias
        estoqueMinimo: 2,
      );

      final antibioticoSuficiente = antibioticoInsuficiente.copyWith(
        id: 'med-temp-2',
        nome: 'Azitromicina',
        estoqueAtual: 6, // cobre exatamente as 6 doses e > 2
      );

      final alertas = calcularAlertasEstoqueBaixo(
        medicamentos: [antibioticoInsuficiente, antibioticoSuficiente],
        dataReferencia: hoje,
      );

      expect(alertas, hasLength(1));
      expect(alertas.single.medicamento.id, 'med-temp-1');
      expect(
        alertas.single.motivo,
        MotivoAlertaEstoque.insuficienteAteFimTratamento,
      );
      expect(alertas.single.estoqueNecessario, 6.0);
      expect(alertas.single.folga, -2.0);
    });

    test('US2/SC-004: desconta doses já tomadas hoje ao calcular cobertura restante até dataFim', () {
      // Começou o dia com 6 comprimidos para 6 doses; após tomar 1 dose hoje, estoque caiu para 5
      // e restam 5 doses (1 hoje + 4 nos próximos 2 dias) -> não deve gerar falso positivo!
      final antibioticoApos1Dose = Medicamento(
        id: 'med-temp-ok',
        nome: 'Amoxicilina',
        forma: FormaMedicamento.comprimido,
        usoContinuo: false,
        duracaoDias: 3,
        dataInicio: hoje,
        frequencia: Frequencia.duasVezes,
        horarios: const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
        estoqueAtual: 5,
        estoqueMinimo: 2,
      );

      final alertas = calcularAlertasEstoqueBaixo(
        medicamentos: [antibioticoApos1Dose],
        dataReferencia: hoje,
        dosesConcluidasNoDiaPorMedicamento: const {'med-temp-ok': 1},
      );

      expect(alertas, isEmpty);
    });

    test('US3: ignora medicamentos inativos na data (tratamento encerrado ou futuro) e ordena pelo mais urgente', () {
      final encerrado = Medicamento(
        id: 'med-encerrado',
        nome: 'Antigo',
        forma: FormaMedicamento.comprimido,
        usoContinuo: false,
        duracaoDias: 2,
        dataInicio: DateTime(2026, 10, 10),
        frequencia: Frequencia.umaVez,
        horarios: const [TimeOfDay(hour: 8, minute: 0)],
        estoqueAtual: 0,
        estoqueMinimo: 5,
      );
      const menosUrgente = Medicamento(
        id: 'med-menos',
        nome: 'Cetoprofeno',
        forma: FormaMedicamento.comprimido,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 4, // folga = 4 - 5 = -1
        estoqueMinimo: 5,
      );
      const maisUrgente = Medicamento(
        id: 'med-mais',
        nome: 'Dipirona',
        forma: FormaMedicamento.gota,
        frequencia: Frequencia.umaVez,
        estoqueAtual: 1, // folga = 1 - 10 = -9
        estoqueMinimo: 10,
      );

      final alertas = calcularAlertasEstoqueBaixo(
        medicamentos: [encerrado, menosUrgente, maisUrgente],
        dataReferencia: hoje,
      );

      expect(alertas.map((a) => a.medicamento.id).toList(), ['med-mais', 'med-menos']);
    });
  });
}
