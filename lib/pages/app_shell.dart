import 'package:flutter/material.dart';
import '../core/app_style.dart';
import 'home_screen.dart';
import 'friends_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const FriendsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppStyle.primaryYellow,
          selectedIndex: _index,
          elevation: 0,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.black),
              selectedIcon: Icon(Icons.home, color: Colors.black),
              label: 'Acasă',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: Colors.black),
              selectedIcon: Icon(Icons.people, color: Colors.black),
              label: 'Prieteni',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Colors.black),
              selectedIcon: Icon(Icons.settings, color: Colors.black),
              label: 'Setări',
            ),
          ],
        ),
      ),
    );
  }
}
