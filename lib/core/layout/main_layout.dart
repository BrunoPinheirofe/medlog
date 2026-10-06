import 'package:material_ui/material_ui.dart';
import '../../features/medicamentos/medicamentos_page.dart';
import '../../features/doses/doses_page.dart';
import '../../features/checkin/checkin_page.dart';
import '../../features/medicamentos/views/cadastro_medicamento_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DosesPage(), // Tela Inicial / Hoje (Doses do dia)
    MedicamentosPage(), // Lista de Medicamentos
    CheckinPage(), // Diário / Check-in
  ];

  final List<String> _titles = const [
    'Hoje',
    'Medicamentos',
    'Check-in',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroMedicamentoPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Remédios',
          ),
          NavigationDestination(
            icon: Icon(Icons.mood_outlined),
            selectedIcon: Icon(Icons.mood),
            label: 'Check-in',
          ),
        ],
      ),
    );
  }
}
