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

  testWidgets('US3: formata saldo fracionado com vírgula (12,5) e inteiro sem decimais (10) na lista e nos detalhes',
      (tester) async {
    const xaropeBaixo = Medicamento(
      id: 'med-frac',
      nome: 'Xarope Pediátrico',
      forma: FormaMedicamento.liquido,
      doseValor: 2.5,
      doseUnidade: 'ml',
      frequencia: Frequencia.duasVezes,
      horarios: [TimeOfDay(hour: 8, minute: 0)],
      estoqueAtual: 4.5,
      estoqueMinimo: 5,
    );
    const medInteiro = Medicamento(
      id: 'med-int',
      nome: 'Vitamina D',
      forma: FormaMedicamento.capsula,
      frequencia: Frequencia.umaVez,
      horarios: [TimeOfDay(hour: 12, minute: 0)],
      estoqueAtual: 10.0,
      estoqueMinimo: 5,
    );

    final repository = FakeMedicamentoRepository()
      ..store[xaropeBaixo.id] = xaropeBaixo
      ..store[medInteiro.id] = medInteiro;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    // Na listagem: estoque baixo fracionado mostra "4,5" (sem "4.5")
    expect(find.textContaining('Estoque baixo (atual: 4,5)'), findsOneWidget);

    // Abre detalhes do xarope (4,5 un.)
    await tester.tap(find.text('Xarope Pediátrico'));
    await tester.pumpAndSettle();
    expect(find.text('4,5 un.'), findsOneWidget);
    expect(find.text('Estoque baixo! Considere repor este medicamento.'), findsOneWidget);

    // Volta e abre detalhes da Vitamina D (10 un. sem ".0")
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vitamina D'));
    await tester.pumpAndSettle();
    expect(find.text('10 un.'), findsOneWidget);
  });

  testWidgets('Sincroniza listagem principal após edições rápidas por modal na tela de detalhes',
      (tester) async {
    final repository = FakeMedicamentoRepository()
      ..store[dipirona.id] = dipirona;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.textContaining('500 mg'), findsOneWidget);
    expect(find.textContaining('Estoque baixo'), findsOneWidget);

    await tester.tap(find.text('Dipirona'));
    await tester.pumpAndSettle();

    // Edita estoque rápido (+30 un.)
    await tester.tap(find.byKey(const Key('btn_editar_rapido_estoque')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+30 un.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Edita dose rápida (1000 mg)
    await tester.tap(find.byKey(const Key('btn_editar_rapido_dose')));
    await tester.pumpAndSettle();
    final doseField = find.widgetWithText(TextFormField, 'Dose / Concentração');
    await tester.enterText(doseField, '1000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Retorna para a listagem de medicamentos
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('1000 mg'), findsOneWidget);
    expect(find.textContaining('Estoque baixo'), findsNothing);
  });
}
