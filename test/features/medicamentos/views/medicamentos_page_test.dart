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

  testWidgets('Exclui o medicamento após confirmação', (tester) async {
    final repository = FakeMedicamentoRepository()
      ..store[dipirona.id] = dipirona
      ..store[ibuprofeno.id] = ibuprofeno;

    await tester.pumpWidget(MaterialApp(home: MedicamentosPage(repository: repository)));
    await tester.pumpAndSettle();

    // Abre a confirmação de exclusão da Dipirona
    await tester.tap(find.byTooltip('Remover').first);
    await tester.pumpAndSettle();
    expect(find.text('Remover Dipirona?'), findsOneWidget);

    // Confirma exclusão
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Dipirona'), findsNothing);
    expect(find.text('Ibuprofeno'), findsOneWidget);
    expect(repository.store.containsKey('1'), isFalse);
  });
}
