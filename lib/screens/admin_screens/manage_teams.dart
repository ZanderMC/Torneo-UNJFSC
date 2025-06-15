import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import 'package:torneo_unjfsc/services/groups_services.dart';
import 'package:torneo_unjfsc/services/matches_services.dart';
import 'package:torneo_unjfsc/services/teams_services.dart';

class ManageTeams extends StatefulWidget {
  const ManageTeams({super.key});

  @override
  State<ManageTeams> createState() => _ManageTeamsState();
}

// Agregar este método para generar partidos
class _ManageTeamsState extends State<ManageTeams> {
  final supabase = Supabase.instance.client;
  late GroupsService _groupsService;
  late TeamsServices _teamsService;
  late MatchesServices _matchesService;
  bool isGenerating = false;
  List<Map<String, dynamic>> grupos = [];
  List<Map<String, dynamic>> equipos = [];
  final TextEditingController _equipoController = TextEditingController();

  // Cambiamos el tipo a dynamic para manejar tanto int como string
  dynamic grupoSeleccionadoId;
  String? grupoSeleccionadoNombre;

  @override
  void initState() {
    super.initState();
    _groupsService = GroupsService(supabase: supabase);
    _teamsService = TeamsServices(supabase: supabase);
    _matchesService = MatchesServices(supabase: supabase); // Agregar esta línea
    _cargarDatos();
  }

  Future<void> _generarPartidosGrupo() async {
    if (grupoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un grupo primero')),
      );
      return;
    }

    final equiposDelGrupo = _obtenerEquiposDeGrupoSeleccionado();

    if (equiposDelGrupo.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se necesitan al menos 2 equipos para generar partidos',
          ),
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar partidos'),
        content: Text(
          'Se generarán todos los partidos para el Grupo $grupoSeleccionadoNombre ' +
              'con formato todos contra todos.\n\n' +
              'Esta acción no duplicará partidos existentes.\n\n' +
              '¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      isGenerating = true;
    });

    try {
      await _matchesService.generarPartidosTodosContraTodos(
        grupoSeleccionadoId,
        equiposDelGrupo,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partidos generados correctamente')),
      );
    } catch (e) {
      print("ERROR al generar partidos: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar partidos: $e')));
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  Future<void> _cargarDatos() async {
    await _cargarGrupos();
    await _cargarEquipos();
  }

  Future<void> _cargarGrupos() async {
    try {
      final gruposCargados = await _groupsService.cargarGrupos();

      setState(() {
        grupos = gruposCargados;
        print("Grupos cargados: $grupos");

        if (grupos.isNotEmpty && grupoSeleccionadoId == null) {
          grupoSeleccionadoId = grupos.first["id"];
          grupoSeleccionadoNombre = grupos.first["nombre"];
          print(
            "Grupo seleccionado: ID=$grupoSeleccionadoId (${grupoSeleccionadoId.runtimeType}), Nombre=$grupoSeleccionadoNombre",
          );
        }
      });
    } catch (e, stackTrace) {
      print("ERROR al cargar grupos: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar los grupos: $e")),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al cargar equipos: $e")));
      }
    }
  }

  List<Map<String, dynamic>> _obtenerEquiposDeGrupoSeleccionado() {
    if (grupoSeleccionadoId == null) return [];

    // Usar filtrarEquiposPorGrupo del servicio de equipos
    return _teamsService.filtrarEquiposPorGrupo(equipos, grupoSeleccionadoId);
  }

  Future<void> _crearGrupo() async {
    try {
      final nuevoGrupo = await _groupsService.crearGrupo();

      await _cargarDatos();

      final nuevoNombre = nuevoGrupo['nombre'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Grupo \"$nuevoNombre\" creado")));
    } catch (e) {
      print("ERROR al crear grupo: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al crear el grupo: $e")));
    }
  }

  Future<void> _agregarEquipo() async {
    final nombre = _equipoController.text.trim();
    if (nombre.isEmpty) return;

    if (grupoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Primero selecciona o crea un grupo")),
      );
      return;
    }

    try {
      await _teamsService.agregarEquipo(nombre, grupoSeleccionadoId);

      _equipoController.clear();
      await _cargarEquipos();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Equipo \"$nombre\" añadido")));
    } catch (e) {
      print("ERROR al agregar equipo: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al agregar equipo: $e")));
    }
  }

  void _seleccionarGrupo(dynamic id, String nombre) {
    setState(() {
      grupoSeleccionadoId = id;
      grupoSeleccionadoNombre = nombre;
      print(
        "Grupo seleccionado: ID=$id (tipo: ${id.runtimeType}), Nombre=$nombre",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final equiposDelGrupo = _obtenerEquiposDeGrupoSeleccionado();

    print("Renderizando con ${grupos.length} grupos");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grupos y Equipos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarDatos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Actualizando datos...")),
              );
            },
            tooltip: "Actualizar datos",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: _crearGrupo,
                icon: const Icon(Icons.add),
                label: const Text("Crear Nuevo Grupo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Text(
                    "Grupos:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Text("(${grupos.length} grupos)"),
                ],
              ),
              const SizedBox(height: 10),

              grupos.isEmpty
                  ? const Text("No hay grupos creados. Crea uno para comenzar.")
                  : SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: grupos.length,
                        itemBuilder: (context, index) {
                          final grupo = grupos[index];
                          final bool isSelected =
                              grupoSeleccionadoId == grupo["id"];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: () => _seleccionarGrupo(
                                grupo["id"],
                                grupo["nombre"],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade200,
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : Colors.black,
                                elevation: isSelected ? 4 : 1,
                              ),
                              child: Text(grupo["nombre"]),
                            ),
                          );
                        },
                      ),
                    ),

              const SizedBox(height: 30),

              if (grupoSeleccionadoId != null) ...[
                Text(
                  "Equipos en $grupoSeleccionadoNombre",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _equipoController,
                        decoration: const InputDecoration(
                          labelText: "Nombre del equipo",
                          border: OutlineInputBorder(),
                          hintText: "Ej: Barcelona FC",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _agregarEquipo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("A�adir"),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  "Total de equipos en este grupo: ${equiposDelGrupo.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                equiposDelGrupo.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "No hay equipos en este grupo. A�ade uno para comenzar.",
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: equiposDelGrupo.length,
                        itemBuilder: (context, index) {
                          final equipo = equiposDelGrupo[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    equipo["nombre"],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await supabase
                                          .from("teams")
                                          .delete()
                                          .eq("id", equipo["id"]);
                                      await _cargarEquipos();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: isGenerating ? null : _generarPartidosGrupo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                icon: isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.sports_soccer),
                label: Text(
                  isGenerating ? "Generando partidos..." : "GENERAR ENCUENTROS",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
