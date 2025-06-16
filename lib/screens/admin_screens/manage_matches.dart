import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torneo_unjfsc/services/groups_services.dart';
import 'package:torneo_unjfsc/services/teams_services.dart';
import 'package:torneo_unjfsc/services/matches_services.dart';

class ManageMatches extends StatefulWidget {
  static const String routeName = '/admin/matches';

  const ManageMatches({Key? key}) : super(key: key);

  @override
  State<ManageMatches> createState() => _ManageMatchesState();
}

class _ManageMatchesState extends State<ManageMatches> {
  final supabase = Supabase.instance.client;

  late GroupsService _groupsService;
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
      final gruposData = await _groupsService.cargarGrupos();
      final equiposData = await _teamsService.cargarEquipos();
      final partidosData = await _matchesService.cargarPartidos();

      setState(() {
        grupos = gruposData;
        equipos = equiposData;
        partidos = partidosData;
        isLoading = false;
      });

      print('Renderizando con ${grupos.length} grupos');
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

  List<Map<String, dynamic>> _obtenerPartidosDeGrupoSeleccionado() {
    if (grupoSeleccionadoId == null) return [];

    return partidos.where((partido) {
      return partido['grupo_id'] != null &&
          partido['grupo_id'].toString() == grupoSeleccionadoId.toString();
    }).toList();
  }

  String _obtenerNombreEquipo(dynamic equipoId) {
    if (equipoId == null) return 'Equipo no asignado';

    final equipo = equipos.firstWhere(
      (e) => e['id'].toString() == equipoId.toString(),
      orElse: () => {'nombre': 'Equipo desconocido'},
    );

    return equipo['nombre'];
  }

  Future<void> _actualizarMarcador(
    Map<String, dynamic> partido,
    int golesEquipo1,
    int golesEquipo2,
  ) async {
    try {
      await supabase
          .from('matches')
          .update({
            'goles_equipo_1': golesEquipo1,
            'goles_equipo_2': golesEquipo2,
            'estado': 'Finalizado',
          })
          .eq('id', partido['id']);

      // Actualizar la lista local
      setState(() {
        final index = partidos.indexWhere((p) => p['id'] == partido['id']);
        if (index != -1) {
          partidos[index]['goles_equipo_1'] = golesEquipo1;
          partidos[index]['goles_equipo_2'] = golesEquipo2;
          partidos[index]['estado'] = 'Finalizado';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marcador actualizado correctamente')),
      );
    } catch (e) {
      print('Error al actualizar marcador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar marcador: $e')),
      );
    }
  }

  void _mostrarModalEditarMarcador(Map<String, dynamic> partido) {
    // Controladores para los campos de texto
    final golesEquipo1Controller = TextEditingController(
      text: partido['goles_equipo_1']?.toString() ?? '',
    );

    final golesEquipo2Controller = TextEditingController(
      text: partido['goles_equipo_2']?.toString() ?? '',
    );

    // Nombres de los equipos
    final nombreEquipo1 = _obtenerNombreEquipo(partido['equipo_1_id']);
    final nombreEquipo2 = _obtenerNombreEquipo(partido['equipo_2_id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Marcador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$nombreEquipo1 vs $nombreEquipo2',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(nombreEquipo1, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextField(
                        controller: golesEquipo1Controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('-', style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(nombreEquipo2, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextField(
                        controller: golesEquipo2Controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Restaurar a 0-0
              golesEquipo1Controller.text = '0';
              golesEquipo2Controller.text = '0';
            },
            child: const Text('Restaurar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Obtener valores y validar
              final goles1 = int.tryParse(golesEquipo1Controller.text) ?? 0;
              final goles2 = int.tryParse(golesEquipo2Controller.text) ?? 0;

              // Actualizar marcador
              _actualizarMarcador(partido, goles1, goles2);

              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Partidos')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGruposSelector(),
                _buildListaPartidos(_obtenerPartidosDeGrupoSeleccionado()),
              ],
            ),
    );
  }

  Widget _buildGruposSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona un grupo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var grupo in grupos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(grupo['nombre']),
                      selected: grupoSeleccionadoId == grupo['id'],
                      onSelected: (selected) {
                        if (selected) {
                          _seleccionarGrupo(grupo['id'], grupo['nombre']);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarModalEditarMarcador(partido),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
              const SizedBox(height: 8),
              Icon(Icons.edit, size: 16, color: Colors.blue[700]),
              const Text(
                "Toca para editar marcador",
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
