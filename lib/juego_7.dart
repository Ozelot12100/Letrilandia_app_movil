import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:confetti/confetti.dart';

class Juego7 extends StatefulWidget {
  const Juego7({super.key});

  @override
  State<Juego7> createState() => _Juego7State();
}

class _Juego7State extends State<Juego7> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> letras = [
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
  // Lista de letras del abecedario
  List<String> letrasMezcladas = [];
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
      puntos = prefs.getInt('puntos_juego_7') ?? 0;
    });
  }

  Future<void> _guardarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puntos_juego_7', puntos);
  }

  Future<void> _reiniciarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puntos_juego_7', 0);
    setState(() {
      puntos = 0;
    });
  }

  void _iniciarJuego() async {
    letras.shuffle();
    letrasMezcladas = List.from(letras);
    setState(() {});
    // No reproducir audio aquí
  }

  void _verificarOrden() async {
    if (_esOrdenCorrecto()) {
      setState(() => puntos += 10);
      await _guardarPuntaje();
      await _guardarProgresoOrdenarAbecedario();
      _mostrarDialogoFin();
      return;
    } else {
      // No reproducir audio aquí
    }
  }

  bool _esOrdenCorrecto() {
    List<String> copia = List.from(letrasMezcladas);
    copia.sort();
    return ListEquality().equals(letrasMezcladas, copia);
  }

  void _cambiarPosicion(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final letra = letrasMezcladas.removeAt(oldIndex);
      letrasMezcladas.insert(newIndex, letra);
    });
    // Validar automáticamente después de cada movimiento
    if (_esOrdenCorrecto()) {
      _onOrdenCorrecto();
    }
  }

  void _onOrdenCorrecto() async {
    setState(() => puntos += 10);
    await _guardarPuntaje();
    await _guardarProgresoOrdenarAbecedario();
    _mostrarDialogoFin();
  }

  Future<void> _guardarProgresoOrdenarAbecedario() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 7,
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
            content: const Text('¡Has ordenado correctamente el abecedario!'),
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
                'Ordena las letras del abecedario',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Puntos: $puntos', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              Expanded(
                child: ReorderableListView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  children: [
                    for (final letra in letrasMezcladas)
                      Container(
                        key: ValueKey(letra),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Image.asset(
                          'assets/letras/$letra.png',
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
