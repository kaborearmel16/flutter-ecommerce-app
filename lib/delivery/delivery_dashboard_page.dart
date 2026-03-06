import 'package:flutter/material.dart';
import 'delivery_home_page.dart';
import 'delivery_history_page.dart';
import 'delivery_settings_page.dart';

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  int _index = 0;

  final pages = const [
    DeliveryHomePage(),
    DeliveryHistoryPage(),
    DeliverySettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true, 
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.black,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}