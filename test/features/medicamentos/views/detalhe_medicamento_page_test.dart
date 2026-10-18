import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';
import 'package:medlog/features/medicamentos/views/detalhe_medicamento_page.dart';

import '../repositories/fake_repository.dart';

void main() {
  const dipirona = Medicamento(
    id: 'med-1',
    nome: 'Dipirona',
    forma: FormaMedicamento.comprimido,
    doseValor: 500,
    doseUnidade: 'mg',
    frequencia: Frequencia.duasVezes,
    horarios: [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
    estoqueAtual: 3,
    estoqueMinimo: 5,
    instrucoes: 'Tomar com água',
  );

  const ibuprofenoSos = Medicamento(
    id: 'med-sos',
    nome: 'Ibuprofeno',
    forma: FormaMedicamento.gota,
    doseValor: 15,
    doseUnidade: 'gotas',
    frequencia: Frequencia.quandoNecessario,
    horarios: [],
    estoqueAtual: 30,
    estoqueMinimo: 5,
  );

  group('DetalheMedicamentoPage — Edição Rápida por Modais', () {
    testWidgets(
      'US1: edita estoque atual via chip +30 un. e alerta mínimo, removendo aviso de estoque baixo ao salvar',
      (tester) async {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona;

        await tester.pumpWidget(
          MaterialApp(
            home: DetalheMedicamentoPage(
              medicamento: dipirona,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 un.'), findsOneWidget);
        expect(
          find.text('Estoque baixo! Considere repor este medicamento.'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('btn_editar_rapido_estoque')));
        await tester.pumpAndSettle();

        expect(find.text('Editar Estoque'), findsOneWidget);

        await tester.tap(find.text('+30 un.'));
        await tester.pumpAndSettle();

        final alertaField = find.widgetWithText(TextFormField, 'Alerta em');
        await tester.enterText(alertaField, '10');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('33 un.'), findsOneWidget);
        expect(find.text('10 un.'), findsOneWidget);
        expect(
          find.text('Estoque baixo! Considere repor este medicamento.'),
          findsNothing,
        );
        expect(repository.store[dipirona.id]?.estoqueAtual, 33);
        expect(repository.store[dipirona.id]?.estoqueMinimo, 10);
      },
    );

    testWidgets(
      'US1: cancelar modal de estoque descarta alterações',
      (tester) async {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona;

        await tester.pumpWidget(
          MaterialApp(
            home: DetalheMedicamentoPage(
              medicamento: dipirona,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_editar_rapido_estoque')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('+20 un.'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.text('3 un.'), findsOneWidget);
        expect(repository.store[dipirona.id]?.estoqueAtual, 3);
      },
    );

    testWidgets(
      'US2: edita horários removendo uma dose, bloqueia salvar lista vazia e salva quando válido',
      (tester) async {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona;

        await tester.pumpWidget(
          MaterialApp(
            home: DetalheMedicamentoPage(
              medicamento: dipirona,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_editar_rapido_horarios')));
        await tester.pumpAndSettle();

        expect(find.text('Editar Horários'), findsOneWidget);

        // Remove os dois horários e tenta salvar
        await tester.tap(find.byTooltip('Excluir dose').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Excluir dose').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Por favor, defina pelo menos um horário para o medicamento.',
          ),
          findsOneWidget,
        );

        // Gera horários a partir do chip rápido "Iniciar às 07:00" e salva
        await tester.tap(find.text('Iniciar às 07:00'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('07:00'), findsOneWidget);
        expect(find.text('19:00'), findsOneWidget);
        expect(
          repository.store[dipirona.id]?.horarios,
          const [
            TimeOfDay(hour: 7, minute: 0),
            TimeOfDay(hour: 19, minute: 0),
          ],
        );
      },
    );

    testWidgets(
      'US2: exibe mensagem informativa para medicamento SOS no modal de horários',
      (tester) async {
        final repository = FakeMedicamentoRepository()
          ..store[ibuprofenoSos.id] = ibuprofenoSos;

        await tester.pumpWidget(
          MaterialApp(
            home: DetalheMedicamentoPage(
              medicamento: ibuprofenoSos,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_editar_rapido_horarios')));
        await tester.pumpAndSettle();

        expect(
          find.text('Medicamento de Uso Sob Demanda (SOS)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'US3: edita dose inteira e decimal com vírgula, bloqueando valor inválido',
      (tester) async {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona;

        await tester.pumpWidget(
          MaterialApp(
            home: DetalheMedicamentoPage(
              medicamento: dipirona,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('500 mg'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_editar_rapido_dose')));
        await tester.pumpAndSettle();

        expect(find.text('Editar Dose'), findsOneWidget);

        final doseField =
            find.widgetWithText(TextFormField, 'Dose / Concentração');
        await tester.enterText(doseField, '-5');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(
          find.text('Informe um valor numérico maior que zero'),
          findsOneWidget,
        );

        await tester.enterText(doseField, '2,5');
        await tester.pumpAndSettle();

        // Altera unidade para ml
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ml').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.textContaining('2.5 ml'), findsOneWidget);
        expect(repository.store[dipirona.id]?.doseValor, 2.5);
        expect(repository.store[dipirona.id]?.doseUnidade, 'ml');
      },
    );

    testWidgets(
      'US4: edita instruções usando chips de sugestão rápida sem duplicação e permite limpar',
      (tester) async {
        final repository = FakeMedicamentoRepository()
          ..store[dipirona.id] = dipirona;

        await tester.pumpWidget(
          MaterialApp(
            home: DetalheMedicamentoPage(
              medicamento: dipirona,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('btn_editar_rapido_instrucoes')),
          200,
        );
        await tester.tap(find.byKey(const Key('btn_editar_rapido_instrucoes')));
        await tester.pumpAndSettle();

        expect(find.text('Editar Instruções'), findsOneWidget);

        await tester.tap(find.text('Após refeições'));
        await tester.pumpAndSettle();
        // Tocar novamente não duplica
        await tester.tap(find.text('Após refeições'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('Tomar com água, Após refeições'), findsOneWidget);
        expect(
          repository.store[dipirona.id]?.instrucoes,
          'Tomar com água, Após refeições',
        );

        // Abre novamente, limpa o texto e salva
        await tester.tap(find.byKey(const Key('btn_editar_rapido_instrucoes')));
        await tester.pumpAndSettle();

        final instrucoesField =
            find.widgetWithText(TextFormField, 'Orientações especiais');
        await tester.enterText(instrucoesField, '');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(
          find.text('Nenhuma instrução especial cadastrada.'),
          findsOneWidget,
        );
        expect(repository.store[dipirona.id]?.instrucoes, isNull);
      },
    );
  });
}
