import 'package:flutter/material.dart';
import 'mail_management_screen.dart';
import 'bagage_management_screen.dart';

class ManagementHubScreen extends StatefulWidget {
  const ManagementHubScreen({super.key});

  @override
  State<ManagementHubScreen> createState() => _ManagementHubScreenState();
}

class _ManagementHubScreenState extends State<ManagementHubScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MailManagementScreen(),
    BagageManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange.withValues(alpha: 0.6),
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: 'Courriers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage),
            label: 'Bagages',
          ),
        ],
      ),
    );
  }
}

