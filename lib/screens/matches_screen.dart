import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torneo_unjfsc/services/groups_services.dart';
import 'package:torneo_unjfsc/services/teams_services.dart';
import 'package:torneo_unjfsc/services/matches_services.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final supabase = Supabase.instance.client;
  late GroupsService _groupsService;
  late TeamsServices _teamsService;
  late MatchesServices _matchesService;

  List<Map<String, dynamic>> grupos = [];
  List<Map<String, dynamic>> equipos = [];
  List<Map<String, dynamic>> partidos = [];
  dynamic grupoSeleccionadoId;
  String? grupoSeleccionadoNombre;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _groupsService = GroupsService(supabase: supabase);
    _teamsService = TeamsServices(supabase: supabase);
    _matchesService = MatchesServices(supabase: supabase);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _cargarGrupos();
      await _cargarEquipos();
      await _cargarPartidos();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cargarGrupos() async {
    try {
      final gruposCargados = await _groupsService.cargarGrupos();

      setState(() {
        grupos = gruposCargados;

        if (grupos.isNotEmpty && grupoSeleccionadoId == null) {
          grupoSeleccionadoId = grupos.first["id"];
          grupoSeleccionadoNombre = grupos.first["nombre"];
        }
      });
    } catch (e) {
      print("ERROR al cargar grupos: $e");
    }
  }

  Future<void> _cargarEquipos() async {
    try {
      final equiposCargados = await _teamsService.cargarEquipos();
      setState(() {
        equipos = equiposCargados;
      });
    } catch (e) {
      print("ERROR al cargar equipos: $e");
    }
  }

  Future<void> _cargarPartidos() async {
    try {
      final partidosCargados = await _matchesService.cargarPartidos();
      setState(() {
        partidos = partidosCargados;
      });
    } catch (e) {
      print("ERROR al cargar partidos: $e");
    }
  }

  void _seleccionarGrupo(dynamic id, String nombre) {
    setState(() {
      grupoSeleccionadoId = id;
      grupoSeleccionadoNombre = nombre;
    });
  }

  List<Map<String, dynamic>> _obtenerEquiposDeGrupoSeleccionado() {
    if (grupoSeleccionadoId == null) return [];

    return equipos.where((equipo) {
      return equipo['grupo_id'] != null &&
          equipo['grupo_id'].toString() == grupoSeleccionadoId.toString();
    }).toList();
  }

  List<Map<String, dynamic>> _obtenerPartidosDeGrupoSeleccionado() {
    final equiposDelGrupo = _obtenerEquiposDeGrupoSeleccionado();
    return _matchesService.filtrarPartidosPorGrupo(partidos, equiposDelGrupo);
  }

  String _obtenerNombreEquipo(dynamic equipoId) {
    if (equipoId == null) return 'Desconocido';

    final equipo = equipos.firstWhere(
      (e) => e['id'].toString() == equipoId.toString(),
      orElse: () => {'nombre': 'Desconocido'},
    );
    return equipo['nombre'];
  }

  @override
  Widget build(BuildContext context) {
    final partidosDelGrupo = _obtenerPartidosDeGrupoSeleccionado();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildGruposTabs(),
                  const SizedBox(height: 16),
                  _buildListaPartidos(partidosDelGrupo),
                ],
              ),
      ),
    );
  }

  Widget _buildGruposTabs() {
    return Container(
      height: 50,
      child: grupos.isEmpty
          ? const Center(child: Text("No hay grupos disponibles"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: grupos.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final grupo = grupos[index];
                final id = grupo['id'];
                final nombre = grupo['nombre'];
                final isSelected =
                    id.toString() == grupoSeleccionadoId.toString();

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () => _seleccionarGrupo(id, nombre),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                    ),
                    child: Text("Grupo $nombre"),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildListaPartidos(List<Map<String, dynamic>> partidos) {
    if (partidos.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            grupoSeleccionadoNombre != null
                ? "No hay partidos programados para el Grupo $grupoSeleccionadoNombre"
                : "Selecciona un grupo para ver sus partidos",
          ),
        ),
      );
    }

    // Agrupar partidos por jornada
    Map<dynamic, List<Map<String, dynamic>>> partidosPorJornada = {};

    for (var partido in partidos) {
      final jornada = partido['jornada'] ?? 'Sin Jornada';
      if (!partidosPorJornada.containsKey(jornada)) {
        partidosPorJornada[jornada] = [];
      }
      partidosPorJornada[jornada]!.add(partido);
    }

    // Ordenar las jornadas numéricamente
    List<dynamic> jornadas = partidosPorJornada.keys.toList()
      ..sort((a, b) {
        if (a == 'Sin Jornada') return 1;
        if (b == 'Sin Jornada') return -1;
        return a.compareTo(b);
      });

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jornadas.length,
        itemBuilder: (context, jornadaIndex) {
          final jornada = jornadas[jornadaIndex];
          final partidosDeJornada = partidosPorJornada[jornada]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  jornada == 'Sin Jornada'
                      ? "Partidos sin jornada asignada"
                      : "🗓 Jornada $jornada",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...partidosDeJornada
                  .map((partido) => _buildTarjetaPartido(partido))
                  .toList(),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTarjetaPartido(Map<String, dynamic> partido) {
    final equipoLocal = _obtenerNombreEquipo(partido['equipo_1_id']);
    final equipoVisitante = _obtenerNombreEquipo(partido['equipo_2_id']);

    String fecha = "Sin programar";
    if (partido['fecha'] != null) {
      try {
        final fechaPartido = DateTime.parse(partido['fecha']);
        // Formato simple sin necesidad de importar intl
        fecha =
            "${fechaPartido.day}/${fechaPartido.month}/${fechaPartido.year}";
      } catch (e) {
        fecha = "Fecha no disponible";
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(fecha),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    equipoLocal,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      partido['goles_equipo_1'] != null &&
                          partido['goles_equipo_2'] != null
                      ? Text(
                          "${partido['goles_equipo_1']} - ${partido['goles_equipo_2']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : const Text(
                          "vs",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    equipoVisitante,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (partido['estado'] != null) ...[
              const SizedBox(height: 8),
              Text(
                partido['estado'],
                style: TextStyle(
                  color: partido['estado'] == 'Finalizado'
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
