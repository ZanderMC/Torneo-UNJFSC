import 'package:supabase_flutter/supabase_flutter.dart';

class TeamsServices {
  final SupabaseClient supabase;

  TeamsServices({required this.supabase});

  Future<List<Map<String, dynamic>>> cargarEquipos() async {
    final response = await supabase.from('teams').select();
    return List<Map<String, dynamic>>.from(response);
  }

  List<Map<String, dynamic>> filtrarEquiposPorGrupo(
    List<Map<String, dynamic>> equipos,
    dynamic grupoId,
  ) {
    if (grupoId == null) return [];

    // Convertir ambos a string para comparar
    String grupoIdStr = grupoId.toString();

    return equipos.where((equipo) {
      // Verificamos que el equipo tenga grupo_id y lo comparamos como string
      return equipo['grupo_id'] != null &&
          equipo['grupo_id'].toString() == grupoIdStr;
    }).toList();
  }

  Future<Map<String, dynamic>> agregarEquipo(
    String nombre,
    dynamic grupoId,
  ) async {
    final response = await supabase
        .from('teams')
        .insert({'nombre': nombre, 'grupo_id': grupoId})
        .select()
        .single();

    return response;
  }

  Future<void> eliminarEquipo(dynamic id) async {
    await supabase.from('teams').delete().eq('id', id);
  }
}
