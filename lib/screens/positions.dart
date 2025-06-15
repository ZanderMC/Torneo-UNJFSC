import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torneo_unjfsc/services/groups_service.dart';
import 'package:torneo_unjfsc/services/teams_Services.dart';

class Positions extends StatefulWidget {
  const Positions({super.key});

  @override
  State<Positions> createState() => _PositionsState();
}

class _PositionsState extends State<Positions> {
  final supabase = Supabase.instance.client;
  late GroupsService _groupsService;
  late TeamsServices _teamsService;

  List<Map<String, dynamic>> grupos = [];
  List<Map<String, dynamic>> equipos = [];
  dynamic grupoSeleccionadoId;
  String? grupoSeleccionadoNombre;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _groupsService = GroupsService(supabase: supabase);
    _teamsService = TeamsServices(supabase: supabase);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _cargarGrupos();
      await _cargarEquipos();
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

  void _seleccionarGrupo(dynamic id, String nombre) {
    setState(() {
      grupoSeleccionadoId = id;
      grupoSeleccionadoNombre = nombre;
    });
  }

  List<Map<String, dynamic>> _obtenerEquiposDeGrupoSeleccionado() {
    return _teamsService.filtrarEquiposPorGrupo(equipos, grupoSeleccionadoId);
  }

  @override
  Widget build(BuildContext context) {
    final equiposDelGrupo = _obtenerEquiposDeGrupoSeleccionado();

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGruposTabs(),
                const SizedBox(height: 16),
                _buildTablaPosiciones(equiposDelGrupo),
              ],
            ),
    );
  }

  Widget _buildGruposTabs() {
    return Container(
      height: 50,
      child: grupos.isEmpty
          ? Center(child: Text("No hay grupos disponibles"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: grupos.length,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final grupo = grupos[index];
                final id = grupo['id'];
                final nombre = grupo['nombre'];
                final isSelected =
                    id.toString() == grupoSeleccionadoId.toString();

                return Padding(
                  padding: EdgeInsets.only(right: 8),
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

  Widget _buildTablaPosiciones(List<Map<String, dynamic>> equiposDelGrupo) {
    if (equiposDelGrupo.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            grupoSeleccionadoNombre != null
                ? "No hay equipos en el Grupo $grupoSeleccionadoNombre"
                : "Selecciona un grupo para ver su tabla de posiciones",
          ),
        ),
      );
    }

    // Ordenar equipos por puntos (esto es solo un ejemplo)
    equiposDelGrupo.sort(
      (a, b) => (b['puntos'] ?? 0).compareTo(a['puntos'] ?? 0),
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tabla de posiciones - Grupo $grupoSeleccionadoNombre",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[300]),
                  children: [
                    _buildTableCell("Pos", fontWeight: FontWeight.bold),
                    _buildTableCell("Equipo", fontWeight: FontWeight.bold),
                    _buildTableCell("PJ", fontWeight: FontWeight.bold),
                    _buildTableCell("G", fontWeight: FontWeight.bold),
                    _buildTableCell("E", fontWeight: FontWeight.bold),
                    _buildTableCell("P", fontWeight: FontWeight.bold),
                    _buildTableCell("Pts", fontWeight: FontWeight.bold),
                  ],
                ),
                ...equiposDelGrupo.asMap().entries.map((entry) {
                  final index = entry.key;
                  final equipo = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
                    ),
                    children: [
                      _buildTableCell("${index + 1}"),
                      _buildTableCell(equipo['nombre'] ?? "Sin nombre"),
                      _buildTableCell("${equipo['partidos_jugados'] ?? 0}"),
                      _buildTableCell("${equipo['partidos_ganados'] ?? 0}"),
                      _buildTableCell("${equipo['partidos_empatados'] ?? 0}"),
                      _buildTableCell("${equipo['partidos_perdidos'] ?? 0}"),
                      _buildTableCell(
                        "${equipo['puntos'] ?? 0}",
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(fontWeight: fontWeight),
        textAlign: TextAlign.center,
      ),
    );
  }
}
