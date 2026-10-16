import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/medicamentos_page.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

import '../repositories/fake_repository.dart';

void main() {
  const dipirona = Medicamento(
    id: '1',
    nome: 'Dipirona',
    forma: FormaMedicamento.comprimido,
    doseValor: 500,
    doseUnidade: 'mg',
    frequencia: Frequencia.duasVezes,
    horarios: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    estoqueAtual: 2,
    estoqueMinimo: 5,
  );
  const ibuprofeno = Medicamento(
    id: '2',
    nome: 'Ibuprofeno',
    forma: FormaMedicamento.gota,
    frequencia: Frequencia.quandoNecessario,
    horarios: [],
    estoqueAtual: 30,
    estoqueMinimo: 5,
  );

  testWidgets('Exibe os medicamentos persistidos no repositório', (tester) async {
    final repository = FakeMedicamentoRepository()
      ..store[dipirona.id] = dipirona
      ..store[ibuprofeno.id] = ibuprofeno;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Dipirona'), findsOneWidget);
    expect(find.text('Ibuprofeno'), findsOneWidget);
    // Sinaliza estoque baixo e frequência SOS
    expect(find.textContaining('Estoque baixo'), findsOneWidget);
    expect(find.text('Quando necessário (SOS)'), findsOneWidget);
  });

  testWidgets('Exibe estado vazio quando não há medicamentos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MedicamentosPage(repository: FakeMedicamentoRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum medicamento cadastrado'), findsOneWidget);
  });

  testWidgets('Exclui o medicamento pela tela de detalhes após confirmação e permite desfazer no SnackBar',
      (tester) async {
    final repository = FakeMedicamentoRepository()
      ..store[dipirona.id] = dipirona
      ..store[ibuprofeno.id] = ibuprofeno;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    // Abre a tela de detalhes da Dipirona e aciona a exclusão
    await tester.tap(find.text('Dipirona'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover medicamento'));
    await tester.pumpAndSettle();
    expect(find.text('Remover Dipirona?'), findsOneWidget);

    // Confirma exclusão
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    // Item foi removido e o SnackBar de desfazer está visível
    expect(repository.store.containsKey('1'), isFalse);
    expect(find.text('Dipirona foi removido'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);

    // Clica em Desfazer no SnackBar
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    // O medicamento foi restaurado no repositório e na lista
    expect(repository.store.containsKey('1'), isTrue);
    expect(find.text('Dipirona'), findsOneWidget);
  });

  testWidgets('Exclui o medicamento arrastando para o lado (swipe) com confirmação e SnackBar',
      (tester) async {
    final repository = FakeMedicamentoRepository()
      ..store[dipirona.id] = dipirona
      ..store[ibuprofeno.id] = ibuprofeno;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    // Arrasta o card da Dipirona para a esquerda
    await tester.drag(find.byKey(const ValueKey('1')), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Exibe o popup de confirmação
    expect(find.text('Remover Dipirona?'), findsOneWidget);
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    // Confirma que excluiu e abriu o SnackBar de desfazer
    expect(repository.store.containsKey('1'), isFalse);
    expect(find.text('Dipirona foi removido'), findsOneWidget);

    // Após 2 segundos o SnackBar fecha automaticamente
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Dipirona foi removido'), findsNothing);
  });

  testWidgets('Abre página de detalhes ao tocar no medicamento e permite editar',
      (tester) async {
    final repository = FakeMedicamentoRepository()
      ..store[dipirona.id] = dipirona;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    // Toca no card da Dipirona para abrir detalhes
    await tester.tap(find.text('Dipirona'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do Medicamento'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Estoque baixo! Considere repor este medicamento.'), findsOneWidget);

    // Toca em Editar na AppBar
    await tester.tap(find.byTooltip('Editar medicamento'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Medicamento'), findsOneWidget);

    // Altera o nome para Dipirona Sódica e avança até salvar
    final nomeInput = find.widgetWithText(TextFormField, 'Nome do medicamento *');
    await tester.enterText(nomeInput, 'Dipirona Sódica');
    await tester.pumpAndSettle();

    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();

    // Verifica que a página de detalhes exibe o nome atualizado
    expect(find.text('Dipirona Sódica'), findsOneWidget);
    expect(repository.store['1']?.nome, 'Dipirona Sódica');
  });
}
