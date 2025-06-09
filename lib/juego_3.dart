import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:confetti/confetti.dart';

class Juego3 extends StatefulWidget {
  const Juego3({super.key});

  @override
  State<Juego3> createState() => _Juego3State();
}

class _Juego3State extends State<Juego3> {
  final List<String> letrasDisponibles = [
    'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'
  ];
  final Set<String> letrasCompletadas = {};
  bool _progresoGuardado = false;
  late ConfettiController _confettiController;

  late String letraActual;
  final List<String> piezas = [];
  final Map<int, String?> posiciones = {0: null, 1: null, 2: null, 3: null};

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _seleccionarLetraAleatoria();
  }

  void _seleccionarLetraAleatoria() {
    final letrasRestantes = letrasDisponibles.where((l) => !letrasCompletadas.contains(l)).toList();
    if (letrasRestantes.isEmpty) {
      _mostrarAnimacionFinal();
      return;
    }
    final random = Random();
    letraActual = letrasRestantes[random.nextInt(letrasRestantes.length)];
    piezas.clear();
    for (int i = 1; i <= 4; i++) {
      piezas.add('${letraActual}_$i.png');
    }
    piezas.shuffle();
    posiciones.updateAll((key, value) => null);
  }

  //Reproduce y espera a que termine el audio
  Future<void> _reproducirYEsperar(String archivo) async {
    final completer = Completer<void>();
    await _audioPlayer.stop();
    final subscription = _audioPlayer.onPlayerComplete.listen((event) {
      completer.complete();
    });
    await _audioPlayer.play(AssetSource(archivo));
    await completer.future;
    await subscription.cancel();
  }

  void verificarCompletado() async {
    bool completo = true;
    for (int i = 0; i < piezas.length; i++) {
      if (posiciones[i] != '${letraActual}_${i + 1}.png') {
        completo = false;
        break;
      }
    }

    if (completo) {
      letrasCompletadas.add(letraActual);
      await _guardarProgreso();
      await _reproducirYEsperar('audio/$letraActual.mp3');
      await _reproducirYEsperar('audio/excelente.mp3');

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
              content: Text('¡Completaste el rompecabezas de la letra ${letraActual.toUpperCase()}!'),
              actions: [
                TextButton(
                  onPressed: () {
                    _confettiController.stop();
                    Navigator.of(context).pop();
                    setState(() {
                      _seleccionarLetraAleatoria();
                    });
                  },
                  child: const Text('Siguiente'),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 3,
        score: letrasCompletadas.length,
        level: 1,
      );
    }
  }

  void _mostrarAnimacionFinal() {
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
            numberOfParticles: 40,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.18,
          ),
          AlertDialog(
            title: const Text('¡Increíble!'),
            content: const Text('¡Completaste todos los rompecabezas del abecedario!'),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  setState(() {
                    letrasCompletadas.clear();
                    _seleccionarLetraAleatoria();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Jugar de nuevo'),
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
      appBar: AppBar(
        title: const Text('Rompecabezas de letras'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fondo_pp2.png', fit: BoxFit.cover),
          ),
          Column(
            children: [
              const SizedBox(height: 20),
              Text(
                letrasCompletadas.length < 26
                  ? "Arma el rompecabezas de la letra: ${letraActual.toUpperCase()}\nLetras completadas: ${letrasCompletadas.length}/26"
                  : "¡Has completado todas las letras!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 49, 49, 49)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    return DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.teal, width: 3),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: posiciones[index] == null
                              ? const Icon(Icons.help_outline, size: 48, color: Colors.teal)
                              : _buildPuzzlePiece(letraActual, posiciones[index]!),
                        );
                      },
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        setState(() {
                          posiciones[index] = details.data;
                          verificarCompletado();
                        });
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.teal.shade100, width: 2),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: piezas.map((pieza) {
                    return Draggable<String>(
                      data: pieza,
                      feedback: _buildPuzzlePiece(letraActual, pieza, dragging: true),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildPuzzlePiece(letraActual, pieza),
                      ),
                      child: _buildPuzzlePiece(letraActual, pieza),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzlePiece(String letra, String pieza, {bool dragging = false}) {
    return FutureBuilder(
      future: rootBundle.load('assets/rompecabezas/$letra/$pieza'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: dragging ? Curves.elasticOut : Curves.easeIn,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: dragging
                  ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)]
                  : [],
            ),
            child: Image.asset(
              'assets/rompecabezas/$letra/$pieza',
              height: 80,
              fit: BoxFit.contain,
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: const Icon(Icons.error, color: Colors.red, size: 40),
          );
        } else {
          return const SizedBox(height: 80, width: 80);
        }
      },
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
