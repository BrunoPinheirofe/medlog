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
  int _medicamentosRefreshKey = 0;

  final List<String> _titles = const [
    'Hoje',
    'Medicamentos',
    'Check-in',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DosesPage(),
      MedicamentosPage(key: ValueKey(_medicamentosRefreshKey)),
      const CheckinPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final salvo = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroMedicamentoPage(),
            ),
          );
          if (salvo != null && mounted) {
            setState(() {
              _medicamentosRefreshKey++;
            });
          }
        },
        label: const Text('Novo Medicamento'),
        icon: const Icon(Icons.add),
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
