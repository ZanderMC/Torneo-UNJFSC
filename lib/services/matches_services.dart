import 'package:supabase_flutter/supabase_flutter.dart';

class MatchesServices {
  final SupabaseClient supabase;

  MatchesServices({required this.supabase});

  Future<List<Map<String, dynamic>>> cargarPartidos() async {
    // Ordenar explícitamente los partidos por jornada y luego por ID
    final response = await supabase
        .from('matches')
        .select('*')
        .order('jornada', ascending: true)
        .order('id', ascending: true);

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
    try {
      // Limpiamos cualquier partido existente para este grupo
      // (esto evita problemas de partidos duplicados o mal generados)
      await supabase.from('matches').delete().eq('grupo_id', grupoId);

      print('Se eliminaron los partidos existentes para este grupo.');

      // Crear una lista de equipos ordenada
      List<Map<String, dynamic>> equipos = List.from(equiposDelGrupo);
      equipos.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));

      int n = equipos.length;
      print('Generando calendario para $n equipos:');

      // Si hay número impar de equipos, añadimos un equipo "fantasma"
      bool hayEquipoFantasma = n % 2 != 0;
      if (hayEquipoFantasma) {
        equipos.add({'id': 'fantasma', 'nombre': 'Descansa'});
        n = n + 1;
      }

      // Lista para guardar los partidos a generar
      final partidosAGenerar = <Map<String, dynamic>>[];

      // Algoritmo de Round Robin básico:
      // - Colocamos los equipos en un círculo
      // - El equipo 0 se queda fijo
      // - Todos los demás rotan en sentido horario
      List<int> indices = List.generate(n, (i) => i);

      // Total de jornadas necesarias (n-1)
      int numJornadas = n - 1;

      for (int jornada = 1; jornada <= numJornadas; jornada++) {
        print('\n🗓 Jornada $jornada:');

        // Conjunto para verificar que no hay duplicados en esta jornada
        Set<int> equiposEnJornada = {};

        // Generar partidos para esta jornada
        for (int i = 0; i < n / 2; i++) {
          int equipoAIdx = indices[i];
          int equipoBIdx = indices[n - 1 - i];

          // Verificar índices válidos
          if (equipoAIdx >= equipos.length || equipoBIdx >= equipos.length) {
            continue;
          }

          var equipoA = equipos[equipoAIdx];
          var equipoB = equipos[equipoBIdx];

          // Si alguno es el equipo fantasma, el otro descansa
          if (equipoA['id'] == 'fantasma') {
            print('  ${equipoB['nombre']} descansa');
            continue;
          } else if (equipoB['id'] == 'fantasma') {
            print('  ${equipoA['nombre']} descansa');
            continue;
          }

          // Verificación CRÍTICA: Asegurarse que estos equipos no están ya programados en esta jornada
          if (equiposEnJornada.contains(equipoAIdx) ||
              equiposEnJornada.contains(equipoBIdx)) {
            throw Exception(
              'ERROR CRÍTICO: Equipo repetido en jornada $jornada. ' +
                  'Equipo ${equipoA['nombre']} o ${equipoB['nombre']} ya está programado.',
            );
          }

          print('  ${equipoA['nombre']} vs ${equipoB['nombre']}');

          // Marcar estos equipos como programados en esta jornada
          equiposEnJornada.add(equipoAIdx);
          equiposEnJornada.add(equipoBIdx);

          // Agregar el partido a la lista
          partidosAGenerar.add({
            'equipo_1_id': equipoA['id'],
            'equipo_2_id': equipoB['id'],
            'grupo_id': grupoId,
            'estado': 'Por Definirse',
            'fecha': null,
            'goles_equipo_1': null,
            'goles_equipo_2': null,
            'jornada': jornada,
          });
        }

        // Rotación para la siguiente jornada:
        // El primer equipo queda fijo, los demás rotan
        if (n > 2) {
          int temp = indices[1];
          for (int i = 1; i < n - 1; i++) {
            indices[i] = indices[i + 1];
          }
          indices[n - 1] = temp;
        }
      }

      // Insertar los partidos generados en la base de datos
      if (partidosAGenerar.isNotEmpty) {
        await supabase.from('matches').insert(partidosAGenerar);
        print(
          '\n✅ Se generaron ${partidosAGenerar.length} partidos correctamente',
        );
      } else {
        print('\n⚠️ No hay partidos para generar');
      }
    } catch (e, stackTrace) {
      print('ERROR: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }
}
