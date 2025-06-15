import 'package:supabase_flutter/supabase_flutter.dart';

class MatchesServices {
  final SupabaseClient supabase;

  MatchesServices({required this.supabase});

  Future<List<Map<String, dynamic>>> cargarPartidos() async {
    final response = await supabase.from('matches').select('*');
    return List<Map<String, dynamic>>.from(response);
  }

  List<Map<String, dynamic>> filtrarPartidosPorGrupo(
    List<Map<String, dynamic>> partidos,
    List<Map<String, dynamic>> equiposDelGrupo,
  ) {
    // Obtener IDs de equipos del grupo
    final equiposIds = equiposDelGrupo.map((e) => e['id']).toList();

    return partidos.where((partido) {
      return (equiposIds.contains(partido['equipo_1_id']) ||
              equiposIds.contains(partido['equipo_2_id'])) &&
          partido['grupo_id'].toString() ==
              equiposDelGrupo.first['grupo_id'].toString();
    }).toList();
  }

  Future<void> generarPartidosTodosContraTodos(
    dynamic grupoId,
    List<Map<String, dynamic>> equiposDelGrupo,
  ) async {
    // Verificar si ya existen partidos para este grupo
    final response = await supabase
        .from('matches')
        .select('id, equipo_1_id, equipo_2_id')
        .eq('grupo_id', grupoId);

    final partidosExistentes = List<Map<String, dynamic>>.from(response);

    // Generar todos los partidos posibles (cada equipo contra todos los demás, una sola vez)
    final partidosAGenerar = <Map<String, dynamic>>[];

    for (int i = 0; i < equiposDelGrupo.length; i++) {
      for (int j = i + 1; j < equiposDelGrupo.length; j++) {
        final equipo1 = equiposDelGrupo[i];
        final equipo2 = equiposDelGrupo[j];

        // Verificar si este encuentro ya existe
        bool encuentroExistente = partidosExistentes.any(
          (partido) =>
              (partido['equipo_1_id'] == equipo1['id'] &&
                  partido['equipo_2_id'] == equipo2['id']) ||
              (partido['equipo_1_id'] == equipo2['id'] &&
                  partido['equipo_2_id'] == equipo1['id']),
        );
        if (!encuentroExistente) {
          // Crear el partido (un solo enfrentamiento)
          partidosAGenerar.add({
            'equipo_1_id': equipo1['id'],
            'equipo_2_id': equipo2['id'],
            'grupo_id': grupoId,
            'estado': 'Programado',
            'fecha': null,
            'goles_equipo_1': null,
            'goles_equipo_2': null,
          });
        }
      }
    }

    // Insertar los partidos generados en la base de datos
    if (partidosAGenerar.isNotEmpty) {
      await supabase.from('matches').insert(partidosAGenerar);
    }
  }
}
