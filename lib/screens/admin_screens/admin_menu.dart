import 'package:flutter/material.dart';
import 'package:torneo_unjfsc/screens/admin_screens/manage_teams.dart';
import 'package:torneo_unjfsc/screens/admin_screens/manage_matches.dart';

class AdminMenu extends StatelessWidget {
  const AdminMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de administración"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenido al panel de administración",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Aquí puedes gestionar los datos del torneo.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageTeams()),
                  );
                },
                child: const Text("Administrar Equipos"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageMatches(),
                    ),
                  );
                },
                child: const Text("Administrar Partidos"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
