import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'supabase_service.dart';

class Juego6 extends StatefulWidget {
  const Juego6({super.key});

  @override
  State<Juego6> createState() => _Juego6State();
}

class _Juego6State extends State<Juego6> {
  final List<String> letras = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  String letraCorrecta = '';
  List<String> opciones = [];
  int puntosAcumulados = 0;
  bool mostrandoResultado = false;
  late ConfettiController _confettiController;
  bool esPrimeraRonda = true;

  @override
  void initState() {
    super.initState();
    puntosAcumulados = 0; // Siempre iniciar en 0
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    esPrimeraRonda = true;
    _generarNuevaRonda();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generarNuevaRonda() async {
    final random = Random();
    letraCorrecta = letras[random.nextInt(letras.length)];
    opciones = [letraCorrecta];

    while (opciones.length < 4) {
      final letra = letras[random.nextInt(letras.length)];
      if (!opciones.contains(letra)) {
        opciones.add(letra);
      }
    }
    opciones.shuffle();

    setState(() {
      mostrandoResultado = false;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (esPrimeraRonda) {
      esPrimeraRonda = false;
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/seleccionar.mp3'));
      await _audioPlayer.onPlayerComplete.first;
    }
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/$letraCorrecta.mp3'));
  }

  Future<void> _reproducirIncorrecto() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/de_nuevo.mp3'));
  }

  void _verificarRespuesta(String seleccion) async {
    if (mostrandoResultado) return;
    setState(() {
      mostrandoResultado = true;
    });

    if (seleccion == letraCorrecta) {
      _confettiController.play();
      setState(() => puntosAcumulados += 10);
      await _guardarProgresoJuego6();
      if (puntosAcumulados >= 50) {
        await Future.delayed(const Duration(milliseconds: 800));
        _confettiController.stop();
        _mostrarDialogoFin();
      } else {
        await Future.delayed(const Duration(seconds: 1));
        _confettiController.stop();
        _generarNuevaRonda();
      }
    } else {
      await _reproducirIncorrecto();
      setState(() {
        mostrandoResultado = false;
      });
    }
  }

  Future<void> _guardarProgresoJuego6() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 6,
        score: 1,
        level: 1,
      );
    }
  }

  void _mostrarDialogoFin() {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Stack(
            alignment: Alignment.center,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.2,
              ),
              AlertDialog(
                title: const Text('¡Felicidades!'),
                content: const Text('¡Has completado el juego!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      _confettiController.stop();
                      Navigator.of(context).pop();
                      setState(() {
                        puntosAcumulados = 0;
                      });
                      _generarNuevaRonda();
                    },
                    child: const Text('Jugar de nuevo'),
                  ),
                  TextButton(
                    onPressed: () {
                      _confettiController.stop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salir'),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/fondo_pp2.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.2,
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 32, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                'Escucha y toca la letra correcta',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Puntos: $puntosAcumulados',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children:
                    opciones.map((letra) {
                      return GestureDetector(
                        onTap: () => _verificarRespuesta(letra),
                        child: Image.asset(
                          'assets/letras/$letra.png',
                          width: 100,
                          height: 100,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}
