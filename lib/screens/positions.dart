import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torneo_unjfsc/services/groups_services.dart';
import 'package:torneo_unjfsc/services/teams_services.dart';
import 'package:torneo_unjfsc/services/matches_services.dart';

class Positions extends StatefulWidget {
  static const String routeName = '/positions';

  const Positions({Key? key}) : super(key: key);

  @override
  State<Positions> createState() => _PositionsState();
}

class _PositionsState extends State<Positions> {
  final supabase = Supabase.instance.client;

  late GroupsServices _groupsService;
  late TeamsServices _teamsService;
  late MatchesServices _matchesService;

  List<Map<String, dynamic>> grupos = [];
  List<Map<String, dynamic>> equipos = [];
  List<Map<String, dynamic>> partidos = [];

  bool isLoading = true;

  dynamic grupoSeleccionadoId;
  String? grupoSeleccionadoNombre;

  @override
  void initState() {
    super.initState();
    _groupsService = GroupsServices(supabase: supabase);
    _teamsService = TeamsServices(supabase: supabase);
    _matchesService = MatchesServices(supabase: supabase);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
    });

    try {
      final gruposData = await _groupsService.cargarGrupos();
      final equiposData = await _teamsService.cargarEquipos();
      final partidosData = await _matchesService.cargarPartidos();

      setState(() {
        grupos = gruposData;
        equipos = equiposData;
        partidos = partidosData;
        isLoading = false;
      });

      // Si hay grupos, seleccionar el primero por defecto
      if (grupos.isNotEmpty) {
        _seleccionarGrupo(grupos[0]['id'], grupos[0]['nombre']);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  void _seleccionarGrupo(dynamic id, String nombre) {
    setState(() {
      grupoSeleccionadoId = id;
      grupoSeleccionadoNombre = nombre;
    });
  }

  List<Map<String, dynamic>> _obtenerEquiposDeGrupo(dynamic grupoId) {
    return equipos.where((equipo) {
      return equipo['grupo_id'] != null &&
          equipo['grupo_id'].toString() == grupoId.toString();
    }).toList();
  }

  List<Map<String, dynamic>> _obtenerPartidosFinalizadosDeGrupo(
    dynamic grupoId,
  ) {
    return partidos.where((partido) {
      return partido['grupo_id'] != null &&
          partido['grupo_id'].toString() == grupoId.toString() &&
          partido['estado'] == 'Finalizado';
    }).toList();
  }

  List<Map<String, dynamic>> _calcularTablaDeposiciones(dynamic grupoId) {
    final equiposDelGrupo = _obtenerEquiposDeGrupo(grupoId);
    final partidosFinalizados = _obtenerPartidosFinalizadosDeGrupo(grupoId);

    // Crear estructura inicial para cada equipo
    final Map<dynamic, Map<String, dynamic>> estadisticasEquipos = {};

    for (var equipo in equiposDelGrupo) {
      estadisticasEquipos[equipo['id']] = {
        'id': equipo['id'],
        'nombre': equipo['nombre'],
        'jugados': 0,
        'ganados': 0,
        'empatados': 0,
        'perdidos': 0,
        'goles_favor': 0,
        'goles_contra': 0,
        'diferencia_goles': 0,
        'puntos': 0,
      };
    }

    // Calcular estadísticas basadas en partidos finalizados
    for (var partido in partidosFinalizados) {
      final equipo1Id = partido['equipo_1_id'];
      final equipo2Id = partido['equipo_2_id'];
      final goles1 = partido['goles_equipo_1'] ?? 0;
      final goles2 = partido['goles_equipo_2'] ?? 0;

      // Verificar que los equipos existan en nuestras estadísticas
      if (!estadisticasEquipos.containsKey(equipo1Id) ||
          !estadisticasEquipos.containsKey(equipo2Id)) {
        continue;
      }

      // Actualizar estadísticas del equipo 1
      estadisticasEquipos[equipo1Id]?['jugados'] += 1;
      estadisticasEquipos[equipo1Id]?['goles_favor'] += goles1;
      estadisticasEquipos[equipo1Id]?['goles_contra'] += goles2;

      // Actualizar estadísticas del equipo 2
      estadisticasEquipos[equipo2Id]?['jugados'] += 1;
      estadisticasEquipos[equipo2Id]?['goles_favor'] += goles2;
      estadisticasEquipos[equipo2Id]?['goles_contra'] += goles1;

      // Determinar resultado (victoria, empate, derrota)
      if (goles1 > goles2) {
        // Equipo 1 gana
        estadisticasEquipos[equipo1Id]?['ganados'] += 1;
        estadisticasEquipos[equipo1Id]?['puntos'] += 2; // 2 puntos por victoria

        estadisticasEquipos[equipo2Id]?['perdidos'] += 1;
        // 0 puntos por derrota
      } else if (goles1 < goles2) {
        // Equipo 2 gana
        estadisticasEquipos[equipo2Id]?['ganados'] += 1;
        estadisticasEquipos[equipo2Id]?['puntos'] += 2; // 2 puntos por victoria

        estadisticasEquipos[equipo1Id]?['perdidos'] += 1;
        // 0 puntos por derrota
      } else {
        // Empate
        estadisticasEquipos[equipo1Id]?['empatados'] += 1;
        estadisticasEquipos[equipo1Id]?['puntos'] += 1; // 1 punto por empate

        estadisticasEquipos[equipo2Id]?['empatados'] += 1;
        estadisticasEquipos[equipo2Id]?['puntos'] += 1; // 1 punto por empate
      }
    }

    // Calcular diferencia de goles
    for (var equipo in estadisticasEquipos.values) {
      equipo['diferencia_goles'] =
          equipo['goles_favor'] - equipo['goles_contra'];
    }

    // Convertir a lista y ordenar por puntos (y si hay empate, por diferencia de goles)
    final listaEquipos = estadisticasEquipos.values.toList();
    listaEquipos.sort((a, b) {
      // Primero ordenar por puntos (descendente)
      final comparacionPuntos = b['puntos'].compareTo(a['puntos']);
      if (comparacionPuntos != 0) return comparacionPuntos;

      // Si hay empate en puntos, ordenar por diferencia de goles (descendente)
      final comparacionDiferencia = b['diferencia_goles'].compareTo(
        a['diferencia_goles'],
      );
      if (comparacionDiferencia != 0) return comparacionDiferencia;

      // Si hay empate en diferencia, ordenar por goles a favor (descendente)
      return b['goles_favor'].compareTo(a['goles_favor']);
    });

    return listaEquipos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGruposTabs(),
                if (grupoSeleccionadoId != null)
                  _buildTablaDeposiciones(
                    _calcularTablaDeposiciones(grupoSeleccionadoId),
                  ),
              ],
            ),
    );
  }

  Widget _buildGruposTabs() {
    return Container(
      height: 60,
      child: grupos.isEmpty
          ? const Center(child: Text("No hay grupos disponibles"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: grupos.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemBuilder: (context, index) {
                final grupo = grupos[index];
                final id = grupo['id'];
                final nombre = grupo['nombre'];
                final isSelected =
                    id.toString() == grupoSeleccionadoId.toString();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _seleccionarGrupo(id, nombre),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                    ),
                    child: Text(" $nombre"),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTablaDeposiciones(List<Map<String, dynamic>> tablaEquipos) {
    if (tablaEquipos.isEmpty) {
      return Expanded(
        child: Center(
          child: Text('No hay equipos en el Grupo $grupoSeleccionadoNombre'),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tabla de Posiciones -  $grupoSeleccionadoNombre',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTabla(tablaEquipos),
            const SizedBox(height: 16),
            const Text(
              'Sistema de puntuación:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Victoria: 2 puntos'),
            const Text('• Empate: 1 punto'),
            const Text('• Derrota: 0 puntos'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabla(List<Map<String, dynamic>> tablaEquipos) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Encabezado de la tabla simplificada
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 40,
                  child: Text(
                    'Pos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Equipo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'PJ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'DG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'Pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filas de equipos simplificadas (sin resaltado especial)
          ...tablaEquipos.asMap().entries.map((entry) {
            final index = entry.key;
            final equipo = entry.value;
            final posicion = index + 1;

            // Color de fondo alternado para mejor legibilidad
            final backgroundColor = index % 2 == 0
                ? Colors.white
                : Colors.grey[50];

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                // Borde inferior para todas las filas excepto la última
                border: index < tablaEquipos.length - 1
                    ? Border(bottom: BorderSide(color: Colors.grey[300]!))
                    : null,
              ),
              child: Row(
                children: [
                  // Posición (sin resaltado especial)
                  SizedBox(width: 40, child: Text('$posicion')),
                  // Nombre del equipo (sin resaltado especial)
                  Expanded(
                    flex: 4,
                    child: Text(
                      equipo['nombre'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${equipo['jugados']}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${equipo['diferencia_goles']}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: equipo['diferencia_goles'] > 0
                            ? Colors.green
                            : equipo['diferencia_goles'] < 0
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${equipo['puntos']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
