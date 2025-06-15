import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:torneo_unjfsc/screens/matches_screen.dart';
import 'package:torneo_unjfsc/screens/positions.dart';
import 'package:torneo_unjfsc/screens/admin.dart';

class Matches extends StatefulWidget {
  const Matches({super.key});

  @override
  State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const MatchesScreen(),
    const Positions(),
    const Admin(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneo UNJFSC'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.blue,
              color: Colors.black,
              tabs: const [
                GButton(icon: Icons.sports_soccer, text: 'Encuentros'),
                GButton(icon: Icons.table_rows_rounded, text: 'Posiciones'),
                GButton(icon: Icons.admin_panel_settings, text: 'Administrar'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
