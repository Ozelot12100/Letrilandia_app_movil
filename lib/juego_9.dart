import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:confetti/confetti.dart';

class Juego9 extends StatefulWidget {
  const Juego9({super.key});

  @override
  State<Juego9> createState() => _Juego9State();
}

class _Juego9State extends State<Juego9> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> numeros = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  List<String> numerosMezclados = [];
  int puntos = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _cargarPuntaje();
    _iniciarJuego();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      puntos = prefs.getInt('puntos_juego_9') ?? 0;
    });
  }

  Future<void> _guardarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puntos_juego_9', puntos);
  }

  Future<void> _reiniciarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puntos_juego_9', 0);
    setState(() {
      puntos = 0;
    });
  }

  void _iniciarJuego() async {
    numeros.shuffle();
    numerosMezclados = List.from(numeros);
    setState(() {});
  }

  void _cambiarPosicion(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final numero = numerosMezclados.removeAt(oldIndex);
      numerosMezclados.insert(newIndex, numero);
    });
    // Validar automáticamente después de cada movimiento
    if (_esOrdenCorrecto()) {
      _onOrdenCorrecto();
    }
  }

  void _onOrdenCorrecto() async {
    setState(() => puntos += 10);
    await _guardarPuntaje();
    await _guardarProgresoOrdenarNumeros();
    _mostrarDialogoFin();
  }

  bool _esOrdenCorrecto() {
    List<String> copia = List.from(numerosMezclados);
    copia.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return ListEquality().equals(numerosMezclados, copia);
  }

  Future<void> _guardarProgresoOrdenarNumeros() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 9,
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
      builder: (context) => Stack(
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
            content: const Text('¡Has ordenado correctamente los números!'),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.of(context).pop();
                  _iniciarJuego();
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
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                'Ordena los números',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Puntos: $puntos', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              Expanded(
                child: ReorderableListView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  children: [
                    for (final numero in numerosMezclados)
                      Container(
                        key: ValueKey(numero),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Image.asset(
                          'assets/numeros/$numero.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                  ],
                  onReorder: _cambiarPosicion,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}

class ListEquality {
  bool equals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
