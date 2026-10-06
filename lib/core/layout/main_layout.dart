import 'package:material_ui/material_ui.dart';
import '../../features/medicamentos/medicamentos_page.dart';
import '../../features/doses/doses_page.dart';
import '../../features/checkin/checkin_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MedicamentosPage(),
    const DosesPage(),
    const CheckinPage(),
  ];

  final List<String> _titles = [
    'Medicamentos',
    'Doses',
    'Check-in',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Doses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Check-in',
          ),
        ],
      ),
    );
  }
}
