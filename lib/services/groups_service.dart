import 'package:supabase_flutter/supabase_flutter.dart';

class GroupsService {
  final SupabaseClient supabase;

  GroupsService({required this.supabase});

  Future<List<Map<String, dynamic>>> cargarGrupos() async {
    final response = await supabase.from('grupos').select();

    // Convertir a List<Map<String, dynamic>> para unificar el formato
    final grupos = List<Map<String, dynamic>>.from(response);

    // Ordenar por número para mostrarlos en orden
    grupos.sort((a, b) {
      // Extraer el número del nombre (si existe)
      int numA = _extraerNumeroDeGrupo(a['nombre'].toString());
      int numB = _extraerNumeroDeGrupo(b['nombre'].toString());
      return numA.compareTo(numB);
    });

    return grupos;
  }

  // Método auxiliar para extraer el número de un nombre de grupo
  int _extraerNumeroDeGrupo(String nombre) {
    // Si el formato es "Grupo X" o solo "X", intentar extraer X como número
    if (nombre.startsWith('Grupo ')) {
      final numStr = nombre.substring(6); // Omitir "Grupo "
      return int.tryParse(numStr) ?? 0;
    } else {
      return int.tryParse(nombre) ?? 0;
    }
  }

  Future<Map<String, dynamic>> crearGrupo() async {
    // Generar el siguiente nombre de grupo (1, 2, 3, etc.)
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
      return 'Grupo 1';
    }

    // Extraer los números de los grupos existentes
    List<int> numerosUsados = grupos
        .map((g) => _extraerNumeroDeGrupo(g['nombre'].toString()))
        .toList();

    // Ordenar para facilitar la búsqueda del primer número faltante
    numerosUsados.sort();

    // Encontrar el primer número que falta en la secuencia
    int siguienteNumero = 1;
    for (int i = 0; i < numerosUsados.length; i++) {
      if (numerosUsados[i] == siguienteNumero) {
        siguienteNumero++;
      } else if (numerosUsados[i] > siguienteNumero) {
        // Encontramos un hueco en la secuencia
        break;
      }
    }

    return 'Grupo $siguienteNumero';
  }
}
