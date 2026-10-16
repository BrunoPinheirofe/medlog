import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/views/cadastro_medicamento_page.dart';

import '../repositories/fake_repository.dart';

void main() {
  testWidgets('Deve validar campos obrigatórios e permitir avançar somente com dados válidos',
      (WidgetTester tester) async {
    // Salvar medicamento (botão fixo no rodapé). O fake trava o save
    // para exercitar o estado de submissão sem depender de banco real.
    final repository = FakeMedicamentoRepository()..travaNoSave = Completer<void>();
    await tester.pumpWidget(MaterialApp(
      home: CadastroMedicamentoPage(repository: repository),
    ));

    // Passo 0: Identificação
    expect(find.text('Identificação do Medicamento'), findsOneWidget);

    // Tentar avançar com nome vazio -> Deve exibir mensagem de validação
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um nome válido com ao menos 2 caracteres'), findsOneWidget);

    // Digitar nome válido
    final nomeInput = find.widgetWithText(TextFormField, 'Nome do medicamento *');
    await tester.enterText(nomeInput, 'Dipirona');
    await tester.pumpAndSettle();

    // Selecionar forma 'Gotas'
    await tester.tap(find.text('Gotas'));
    await tester.pumpAndSettle();

    // Avançar para Passo 1: Frequência
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    expect(find.text('Frequência e Duração'), findsOneWidget);

    // Selecionar "2 vezes ao dia"
    await tester.tap(find.text('2 vezes ao dia'));
    await tester.pumpAndSettle();

    // Avançar para Passo 2: Horários
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    expect(find.text('Horários das Doses'), findsOneWidget);

    // Tentar avançar sem horários -> deve bloquear e exibir alerta
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    expect(find.text('Defina pelo menos um horário de dose para continuar.'), findsOneWidget);

    // Usar atalho rápido para iniciar às 08:00
    final chip08 = find.text('Iniciar às 08:00');
    expect(chip08, findsOneWidget);
    await tester.ensureVisible(chip08);
    await tester.pumpAndSettle();
    await tester.tap(chip08);
    await tester.pumpAndSettle();

    // Horários calculados (2 doses: 08:00 e 20:00)
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('2 doses configuradas'), findsOneWidget);

    // Avançar para Passo 3: Estoque, Instruções & Revisão
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();
    expect(find.text('Estoque, Instruções & Revisão'), findsOneWidget);

    // Adicionar instrução rápida
    final chipInstrucao = find.text('Após refeições');
    await tester.ensureVisible(chipInstrucao);
    await tester.pumpAndSettle();
    await tester.tap(chipInstrucao);
    await tester.pumpAndSettle();

    // Rolar até o Card de Resumo da Prescrição
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Resumo da Prescrição'), findsOneWidget);

    // Salvar medicamento (botão fixo no rodapé)
    final btnSalvar = find.text('SALVAR');
    await tester.tap(btnSalvar);
    await tester.pump(); // Estado de submissão com indicador de progresso
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Libera o save previsto no fake; isSuccess dispara snackbar e pop
    repository.travaNoSave!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Deve exibir diálogo de confirmação ao tentar fechar tela com dados preenchidos',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CadastroMedicamentoPage(),
    ));

    // Digita um nome
    final nomeInput = find.widgetWithText(TextFormField, 'Nome do medicamento *');
    await tester.enterText(nomeInput, 'Amoxicilina');
    await tester.pumpAndSettle();

    // Clica no botão de fechar (X)
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verifica que o diálogo de descarte foi exibido
    expect(find.text('Descartar alterações?'), findsOneWidget);
    expect(find.text('Continuar editando'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);

    // Clica em 'Continuar editando' e permanece na página
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.text('Identificação do Medicamento'), findsOneWidget);
  });
}
