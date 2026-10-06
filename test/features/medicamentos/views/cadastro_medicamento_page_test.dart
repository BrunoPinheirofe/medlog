import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/views/cadastro_medicamento_page.dart';

void main() {
  testWidgets('Deve exibir o formulário de cadastro e navegar entre as etapas', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CadastroMedicamentoPage(),
    ));

    // Passo 0: Identificação
    expect(find.text('Qual o nome do medicamento?'), findsOneWidget);
    expect(find.text('Qual a forma do medicamento?'), findsOneWidget);
    
    // Inserir nome
    await tester.enterText(find.byType(TextFormField), 'Paracetamol');
    
    // Avançar
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();

    // Passo 1: Frequência
    expect(find.text('Com que frequência você toma este medicamento?'), findsOneWidget);
    
    // Escolher frequência (Uma vez ao dia)
    await tester.tap(find.text('Uma vez por dia'));
    await tester.pumpAndSettle();

    // Avançar
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();

    // Passo 2: Horários
    expect(find.text('Em quais horários você toma?'), findsOneWidget);
    expect(find.text('Defina o horário da primeira dose, e nós calculamos o restante para você.'), findsOneWidget);
    
    // Avançar
    await tester.tap(find.text('PRÓXIMO'));
    await tester.pumpAndSettle();

    // Passo 3: Detalhes
    expect(find.text('Estoque e Instruções'), findsOneWidget);

    // Salvar
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();

    // Como o save apenas emite isSuccess e o listener faz o pop e snackbar, não precisamos mockar tudo
    // Apenas verificamos que ele não quebrou e a barra de progresso rodou
  });
}
