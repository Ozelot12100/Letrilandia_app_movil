import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'pantalla_principal.dart';
import 'creditos.dart';
import 'supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'configuracion_page.dart';
import 'login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  bool _isPlaying = true;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
    _loadSelectedChildId();
  }

  Future<void> _loadSelectedChildId() async {
    final prefs = await SharedPreferences.getInstance();
    final children = await SupabaseService().getChildren();
    if (children.isEmpty && mounted) {
      await _showAddChildDialogBloqueante();
    } else {
      // Obtener el último niño seleccionado desde Supabase
      String? lastSelected = await SupabaseService().getLastSelectedChild();
      // Validar que el niño siga existiendo
      if (lastSelected != null && children.any((c) => c['id'] == lastSelected)) {
        setState(() {
          _selectedChildId = lastSelected;
        });
        await prefs.setString('selected_child_id', lastSelected);
      } else {
        // Si no hay uno guardado o el guardado ya no existe, seleccionar el primero
        String idToUse = children.first['id'] as String;
        setState(() {
          _selectedChildId = idToUse;
        });
        await prefs.setString('selected_child_id', idToUse);
        await SupabaseService().saveLastSelectedChild(idToUse);
      }
    }
  }

  Future<void> _saveSelectedChildId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_child_id', id);
    setState(() {
      _selectedChildId = id;
    });
    await SupabaseService().saveLastSelectedChild(id);
  }

  Future<void> _showAddChildDialog() async {
    final nameController = TextEditingController();
    DateTime? birthdate;
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Registrar niño'),
              content: Column(
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
                                initialDate: DateTime(2018),
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
                      final id = await SupabaseService().addChild(
                        name: nameController.text.trim(),
                        birthdate: birthdate!,
                      );
                      await _saveSelectedChildId(id);
                      Navigator.of(context).pop();
                    } catch (e) {
                      setStateDialog(() {
                        error = 'Error: ${e.toString()}';
                      });
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

  Future<String?> _showSelectChildDialog(List<Map<String, dynamic>> children) async {
    String? selectedId = children.first['id'] as String;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona un niño'),
          content: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            items: children.map((c) {
              return DropdownMenuItem<String>(
                value: c['id'] as String,
                child: Text(c['name'] ?? 'Sin nombre'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedId = value;
                // Forzar rebuild para reflejar selección
                (context as Element).markNeedsBuild();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedId);
              },
              child: const Text('Seleccionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(0.3);
      await _backgroundMusicPlayer.play(AssetSource('musica.mp3'), volume: 0.3);
    } catch (e) {
      debugPrint("Error reproduciendo música: $e");
    }
  }

  Future<void> _onStartPressed() async {
    try {
      await _backgroundMusicPlayer.setVolume(0.2);
      await _effectPlayer.play(AssetSource('intro.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 3000));
      await _effectPlayer.play(AssetSource('efecto.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 800));
      await _backgroundMusicPlayer.stop(); // Detener música al cambiar pantalla

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
        );
      }
    } catch (e) {
      debugPrint("Error en efectos de sonido: $e");
    }
  }

  void _toggleMusic() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _isPlaying
        ? _backgroundMusicPlayer.resume()
        : _backgroundMusicPlayer.pause();
  }

  @override
  void dispose() {
    _backgroundMusicPlayer.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/letrilandia_fondo.png',
              fit: BoxFit.cover,
            ),
          ),

          // Botón y controles
          SafeArea(
            child: Stack(
              children: [
                // Botón "¡Empezar!"
                Center(
                  child: ElevatedButton(
                    onPressed: _onStartPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.black45,
                      elevation: 6,
                    ),
                    child: Text(
                      '¡Empezar!',
                      style: GoogleFonts.baloo2(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Botón de volumen
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_off,
                      size: 32,
                      color: Colors.deepOrange,
                    ),
                    onPressed: _toggleMusic,
                  ),
                ),

                // Botón de engrane (configuración protegida por PIN)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    color: Colors.orangeAccent,
                    onPressed: () async {
                      // Obtener el PIN desde Supabase
                      String? pin = await SupabaseService().getParentPin();
                      if (pin == null) {
                        // Crear PIN
                        String? newPin = await _showCreatePinDialog(context);
                        if (newPin != null) {
                          await SupabaseService().saveParentPin(newPin);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('parent_pin', newPin); // opcional: caché local
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConfiguracionPage(),
                            ),
                          );
                        }
                      } else {
                        // Pedir PIN
                        String? enteredPin = await _showEnterPinDialog(context);
                        if (enteredPin == pin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                              builder: (context) => const ConfiguracionPage(),
                        ),
                      );
                        } else if (enteredPin != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN incorrecto')),
                          );
                        }
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

  Future<String?> _showCreatePinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear PIN de padres'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
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
                    decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (pinController.text.length < 4 || pinController.text.length > 6) {
                      setStateDialog(() { error = 'El PIN debe tener entre 4 y 6 dígitos.'; });
                      return;
                    }
                    if (pinController.text != confirmController.text) {
                      setStateDialog(() { error = 'Los PIN no coinciden.'; });
                      return;
                    }
                    Navigator.of(context).pop(pinController.text);
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

  Future<String?> _showEnterPinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingresa el PIN de padres'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(pinController.text);
              },
              child: const Text('Aceptar'),
            ),
          ],
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
                },
                child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () async {
                  await _showAddChildDialog();
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
}
