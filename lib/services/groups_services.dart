import 'package:supabase_flutter/supabase_flutter.dart';

class GroupsService {
  final SupabaseClient supabase;

  GroupsService({required this.supabase});

  Future<List<Map<String, dynamic>>> cargarGrupos() async {
    final response = await supabase.from('grupos').select();

    // Convertir a List<Map<String, dynamic>> para unificar el formato
    final grupos = List<Map<String, dynamic>>.from(response);

    // Ordenar por nombre para mostrarlos en orden
    grupos.sort(
      (a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()),
    );

    return grupos;
  }

  Future<Map<String, dynamic>> crearGrupo() async {
    // Generar el siguiente nombre de grupo (A, B, C, etc.)
    final grupos = await cargarGrupos();
    final String nuevoNombre = _generarSiguienteNombreGrupo(grupos);

    // Crear el nuevo grupo en Supabase
    final response = await supabase
        .from('grupos')
        .insert({'nombre': nuevoNombre})
        .select()
        .limit(1)
        .single();

    return response;
  }

  String _generarSiguienteNombreGrupo(List<Map<String, dynamic>> grupos) {
    if (grupos.isEmpty) {
      return 'A';
    }

    // Encontrar la última letra usada
    final letrasUsadas = grupos.map((g) => g['nombre'].toString()).toList();

    // Encontrar la siguiente letra disponible
    String letra = 'A';
    while (letrasUsadas.contains(letra)) {
      letra = String.fromCharCode(letra.codeUnitAt(0) + 1);
    }

    return letra;
  }
}
