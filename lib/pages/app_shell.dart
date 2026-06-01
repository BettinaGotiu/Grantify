import 'package:flutter/material.dart';
import '../core/app_style.dart';
import 'home_news_tab.dart';
import 'friends_screen.dart';
import 'matching_tab.dart';
import 'vault_tab.dart';
import 'settings_tab.dart';

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
      const HomeNewsTab(),
      const MatchingTab(),
      const VaultTab(),
      const FriendsScreen(),
      const SettingsTab(),
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
              icon: Icon(Icons.newspaper_outlined, color: Colors.black),
              selectedIcon: Icon(Icons.newspaper, color: Colors.black),
              label: 'Acasă',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: Colors.black),
              selectedIcon: Icon(Icons.analytics, color: Colors.black),
              label: 'Matching',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_special_outlined, color: Colors.black),
              selectedIcon: Icon(Icons.folder_special, color: Colors.black),
              label: 'Vault',
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
