import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:confetti/confetti.dart';

class Juego2 extends StatefulWidget {
  const Juego2({super.key});

  @override
  State<Juego2> createState() => _Juego2State();
}

class _Juego2State extends State<Juego2> {
  final Set<String> _numerosEscuchados = {};
  bool _progresoGuardado = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _reproducirNumero(String numero) async {
    final player = AudioPlayer();
    player.play(AssetSource('audio/$numero.mp3'));
    setState(() {
      _numerosEscuchados.add(numero);
    });
    if (_numerosEscuchados.length == 10 && !_progresoGuardado) {
      _progresoGuardado = true;
      await _guardarProgreso();
      _confettiController.play();
      if (mounted) {
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
                content: const Text('¡Has escuchado todos los números del 0 al 9!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      _confettiController.stop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 2,
        score: 10,
        level: 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numeros = List.generate(10, (index) => index.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Números'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset('assets/fondo_pp2.png', fit: BoxFit.cover),
          ),

          // Cuadrícula de números
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children:
                  numeros.map((numero) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.primaries[int.parse(numero) %
                                Colors.primaries.length],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 3),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () => _reproducirNumero(numero),
                      child: Stack(
                        children: [
                          Text(
                            numero,
                            style: TextStyle(
                              fontSize: 32,
                              foreground:
                                  Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2
                                    ..color = Colors.black,
                            ),
                          ),
                          Text(
                            numero,
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
