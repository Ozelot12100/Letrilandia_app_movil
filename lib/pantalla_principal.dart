import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'juego_1.dart';
import 'juego_2.dart';
import 'configuracion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'juego_3.dart';
import 'juego_4.dart';
import 'juego_5.dart';
import 'juego_6.dart';
import 'juego_7.dart';
import 'juego_8.dart';
import 'juego_9.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  bool _isPlaying = true;
  List<Map<String, dynamic>> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await SupabaseService().getGames();
    setState(() {
      _games = games;
      _loading = false;
    });
  }

  void _toggleMusic() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 2 : 3;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fondo_pp2.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.volume_up : Icons.volume_off,
                          size: 32,
                          color: Colors.deepOrange,
                        ),
                        onPressed: _toggleMusic,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 28),
                        color: Colors.orangeAccent,
                        onPressed: () async {
                          // Obtener el PIN desde Supabase
                          String? pin = await SupabaseService().getParentPin();
                          if (pin == null) {
                            String? newPin = await _showCreatePinDialog(
                              context,
                            );
                            if (newPin != null) {
                              await SupabaseService().saveParentPin(newPin);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'parent_pin',
                                newPin,
                              ); // opcional: caché local
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ConfiguracionPage(),
                                ),
                              );
                            }
                          } else {
                            String? enteredPin = await _showEnterPinDialog(
                              context,
                            );
                            if (enteredPin == pin) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ConfiguracionPage(),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _loading
                    ? const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.all(16),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                        children: _games.map(_buildJuegoButton).toList(),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuegoButton(Map<String, dynamic> game) {
    Widget? juegoDestino;
    String imagePath = 'assets/images/juego_1_icon.png';
    String audioIntro = 'audio/seleccionar.mp3';
    switch (game['id']) {
      case 1:
        juegoDestino = const Juego1();
        imagePath = 'assets/images/juego_1_icon.png';
        audioIntro = 'audio/seleccionar.mp3';
        break;
      case 2:
        juegoDestino = const Juego2();
        imagePath = 'assets/images/juego_2_icon.png';
        audioIntro = 'audio/numero.mp3';
        break;
      case 3:
        juegoDestino = const Juego3();
        imagePath = 'assets/images/juego_3_icon.png';
        audioIntro = 'audio/rompecabezas.mp3';
        break;
      case 4:
        juegoDestino = const Juego4();
        imagePath = 'assets/images/juego_4_icon.png';
        audioIntro = 'audio/memorama.mp3';
        break;
      case 6:
        juegoDestino = const Juego6();
        imagePath = 'assets/images/juego_6_icon.png';
        audioIntro = '';
        break;
      case 7:
        juegoDestino = const Juego7();
        imagePath = 'assets/images/juego_7_icon.png';
        audioIntro = 'audio/ordenar_abecedario.mp3';
        break;
      case 8:
        juegoDestino = const Juego8();
        imagePath = 'assets/images/juego_8_icon.png';
        audioIntro = 'audio/memorama.mp3';
        break;
      case 9:
        juegoDestino = const Juego9();
        imagePath = 'assets/images/juego_9_icon.png';
        audioIntro = 'audio/ordenar_numeros.mp3';
        break;
      default:
        return const SizedBox();
    }
    return GestureDetector(
      onTap: () async {
        final player = AudioPlayer();
        try {
          if (audioIntro.isNotEmpty) {
            await player.play(AssetSource(audioIntro));
            await Future.delayed(const Duration(milliseconds: 700));
          }
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => juegoDestino!),
          );
        } catch (e) {
          debugPrint("Error al reproducir audio: $e");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          border: Border.all(color: Colors.deepOrange, width: 4),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 6),
            ),
          ],
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
        ),
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
                    decoration: const InputDecoration(
                      labelText: 'Nuevo PIN (4-6 dígitos)',
                    ),
                  ),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar PIN',
                    ),
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
                    if (pinController.text.length < 4 ||
                        pinController.text.length > 6) {
                      setStateDialog(() {
                        error = 'El PIN debe tener entre 4 y 6 dígitos.';
                      });
                      return;
                    }
                    if (pinController.text != confirmController.text) {
                      setStateDialog(() {
                        error = 'Los PIN no coinciden.';
                      });
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
}
