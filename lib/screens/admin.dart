import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torneo_unjfsc/screens/admin_screens/admin_menu.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final TextEditingController _controller = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> _verificarPassword() async {
    final input = _controller.text.trim();

    try {
      final response = await supabase
          .from('password')
          .select('contra')
          .eq('id', 1)
          .limit(1);

      if (response.isNotEmpty) {
        final String passwordEnBD = response.first['contra'];

        if (input == passwordEnBD) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminMenu()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña incorrecta')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró la contraseña en la base de datos'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al verificar: $e')));
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("CONTRASEÑA", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Contraseña',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verificarPassword,
                child: const Text("INGRESAR"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
