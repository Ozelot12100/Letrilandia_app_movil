import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'creditos.dart';
import 'login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'estadisticas_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final children = await SupabaseService().getChildren();
    final savedId = prefs.getString('selected_child_id');
    setState(() {
      _children = children;
      _selectedChildId = savedId ?? (children.isNotEmpty ? children.first['id'] as String : null);
      _loading = false;
    });
  }

  Future<void> _saveSelectedChildId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_child_id', id);
    setState(() {
      _selectedChildId = id;
    });
  }

  Future<void> _addOrEditChild({Map<String, dynamic>? child}) async {
    final nameController = TextEditingController(text: child?['name'] ?? '');
    DateTime? birthdate = child != null ? DateTime.parse(child['birthdate']) : null;
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(child == null ? 'Agregar niño' : 'Editar niño'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fecha de nacimiento:'),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                birthdate == null
                                    ? 'Seleccionar'
                                    : '${birthdate!.day}/${birthdate!.month}/${birthdate!.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: birthdate ?? DateTime(2018),
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    birthdate = picked;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || birthdate == null) {
                      setStateDialog(() {
                        error = 'Completa todos los campos';
                      });
                      return;
                    }
                    try {
                      if (child == null) {
                        final id = await SupabaseService().addChild(
                          name: nameController.text.trim(),
                          birthdate: birthdate!,
                        );
                        await _saveSelectedChildId(id);
                        await _loadChildren();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Niño agregado correctamente.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        await SupabaseService().updateChild(
                          childId: child['id'],
                          name: nameController.text.trim(),
                          birthdate: birthdate!,
                        );
                        await _loadChildren();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Niño editado correctamente.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      setStateDialog(() {
                        error = 'Error: ${e.toString()}';
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar niño'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: '¿Seguro que deseas eliminar a '),
              TextSpan(
                text: child['name'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const TextSpan(text: '? Esta acción eliminará TODOS los datos y progreso de este niño y no se puede deshacer.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final lastSelected = await SupabaseService().getLastSelectedChild();
      if (lastSelected == child['id']) {
        await SupabaseService().saveLastSelectedChild(null);
      }
      final prefs = await SharedPreferences.getInstance();
      if (_selectedChildId == child['id']) {
        await prefs.remove('selected_child_id');
      }
      await SupabaseService().deleteChild(child['id']);
      await _loadChildren();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Niño eliminado correctamente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      final children = await SupabaseService().getChildren();
      if (children.isEmpty && mounted) {
        await _showAddChildDialogBloqueante();
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<String?> _showChangePinDialog(BuildContext context) async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    String? savedPin = await SupabaseService().getParentPin();
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Cambiar PIN de padres'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: 'PIN actual'),
                    ),
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: 'Nuevo PIN (4-6 dígitos)'),
                    ),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: 'Confirmar nuevo PIN'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (currentPinController.text != savedPin) {
                      setStateDialog(() { error = 'El PIN actual es incorrecto.'; });
                      return;
                    }
                    if (newPinController.text.length < 4 || newPinController.text.length > 6) {
                      setStateDialog(() { error = 'El nuevo PIN debe tener entre 4 y 6 dígitos.'; });
                      return;
                    }
                    if (newPinController.text != confirmController.text) {
                      setStateDialog(() { error = 'Los nuevos PIN no coinciden.'; });
                      return;
                    }
                    await SupabaseService().saveParentPin(newPinController.text);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('parent_pin', newPinController.text);
                    Navigator.of(context).pop(newPinController.text);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddChildDialogBloqueante() async {
    while (true) {
      await showDialog(
        context: context,
        barrierDismissible: false, // No se puede cerrar tocando fuera
        builder: (context) => WillPopScope(
          onWillPop: () async => false, // No se puede cerrar con back
          child: AlertDialog(
            title: const Text('Registrar niño'),
            content: const Text('Debes registrar al menos un niño para usar la app.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await _addOrEditChild();
                  final children = await SupabaseService().getChildren();
                  if (children.isNotEmpty) {
                    Navigator.of(context).pop();
                  }
                  // Si sigue vacío, el modal no se cierra y se repite el ciclo
                },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      );
      final children = await SupabaseService().getChildren();
      if (children.isNotEmpty) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.orange.withOpacity(0.95),
        elevation: 4,
        title: Text(
          'Configuración para padres',
          style: GoogleFonts.baloo2(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/fondo_pp2.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Gestión de niños
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  color: Colors.white.withOpacity(0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.family_restroom, color: Colors.orange, size: 32),
                            const SizedBox(width: 10),
                            Text('Gestión de niños', style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButton<String>(
                          value: _selectedChildId,
                          isExpanded: true,
                          dropdownColor: Colors.orange[50],
                          style: GoogleFonts.baloo2(fontSize: 18, color: Colors.deepOrange),
                          items: _children.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['id'] as String,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange[200],
                                    child: Icon(Icons.child_care, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(c['name'] ?? 'Sin nombre'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              await _saveSelectedChildId(value);
                              await SupabaseService().saveLastSelectedChild(value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _addOrEditChild(),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text('Agregar', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                            if (_selectedChildId != null) ...[
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final child = _children.firstWhere((c) => c['id'] == _selectedChildId);
                                  _addOrEditChild(child: child);
                                },
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: Text('Editar', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final child = _children.firstWhere((c) => c['id'] == _selectedChildId);
                                  _deleteChild(child);
                                },
                                icon: const Icon(Icons.delete, color: Colors.white),
                                label: Text('Eliminar', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Progreso y estadísticas
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart, color: Colors.deepPurple, size: 32),
                            const SizedBox(width: 10),
                            Text('Progreso y estadísticas', style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const EstadisticasPage()));
                              },
                              icon: const Icon(Icons.bar_chart, color: Colors.white),
                              label: Text('Ver estadísticas', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (_selectedChildId != null) {
                                  final games = await SupabaseService().getGames();
                                  List<int> selectedGameIds = [];
                                  bool selectAll = false;
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setStateDialog) {
                                          return AlertDialog(
                                            title: const Text('Selecciona los juegos a reiniciar'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CheckboxListTile(
                                                    value: selectAll,
                                                    onChanged: (value) {
                                                      setStateDialog(() {
                                                        selectAll = value ?? false;
                                                        if (selectAll) {
                                                          selectedGameIds = games.map<int>((g) => g['id'] as int).toList();
                                                        } else {
                                                          selectedGameIds.clear();
                                                        }
                                                      });
                                                    },
                                                    title: const Text('Seleccionar todos'),
                                                  ),
                                                  const Divider(),
                                                  ...games.map((g) => CheckboxListTile(
                                                        value: selectedGameIds.contains(g['id']),
                                                        onChanged: (value) {
                                                          setStateDialog(() {
                                                            if (value == true) {
                                                              selectedGameIds.add(g['id'] as int);
                                                              if (selectedGameIds.length == games.length) selectAll = true;
                                                            } else {
                                                              selectedGameIds.remove(g['id'] as int);
                                                              selectAll = false;
                                                            }
                                                          });
                                                        },
                                                        title: Text(g['name'] ?? 'Juego'),
                                                      )),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: selectedGameIds.isEmpty
                                                    ? null
                                                    : () => Navigator.of(context).pop(selectedGameIds),
                                                child: const Text('Reiniciar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ).then((result) async {
                                    if (result is List<int> && result.isNotEmpty) {
                                      for (final gameId in result) {
                                        await SupabaseService().wipeChildGame(_selectedChildId!, gameId);
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Progreso de los juegos reiniciado.')),
                                        );
                                      }
                                    }
                                  });
                                }
                              },
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: Text('Reiniciar progreso', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Seguridad
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.teal, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              String? newPin = await _showChangePinDialog(context);
                              if (newPin != null) {
                                await prefs.setString('parent_pin', newPin);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PIN actualizado correctamente.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.lock, color: Colors.white),
                            label: Text('Cambiar PIN de padres', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Información y sesión
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditosPage()));
                          },
                          icon: const Icon(Icons.info_outline, color: Colors.white),
                          label: Text('Créditos', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('¿Cerrar sesión?'),
                                content: const Text('¿Seguro que deseas cerrar sesión? Tendrás que volver a iniciar sesión para jugar.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _signOut();
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: Text('Cerrar sesión', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 