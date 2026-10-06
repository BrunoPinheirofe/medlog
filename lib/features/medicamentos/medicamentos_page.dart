import 'package:material_ui/material_ui.dart';
import 'views/cadastro_medicamento_page.dart';

class MedicamentosPage extends StatelessWidget {
  const MedicamentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Página de Medicamentos - Lista Vazia'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CadastroMedicamentoPage(),
              fullscreenDialog: true,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
