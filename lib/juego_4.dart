import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:confetti/confetti.dart';

class Juego4 extends StatefulWidget {
  const Juego4({super.key});

  @override
  State<Juego4> createState() => _JuegoMemoramaState();
}

class _JuegoMemoramaState extends State<Juego4> {
  final List<String> letras = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
    'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
    'y', 'z',
  ];

  late List<_Carta> cartas;
  _Carta? primeraSeleccion;
  bool bloquear = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _generarCartas();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generarCartas() {
    final List<_Carta> generadas = [];
    final letrasSeleccionadas = List<String>.from(letras)..shuffle();
    final seleccionadas = letrasSeleccionadas.take(16).toList();
    for (var letra in seleccionadas) {
      generadas.add(_Carta(letra));
      generadas.add(_Carta(letra));
    }
    generadas.shuffle(Random());
    setState(() {
      cartas = generadas;
    });
  }

  Future<void> _reproducirSonido(String letra) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/$letra.mp3'));
  }

  void _seleccionarCarta(int index) async {
    if (bloquear ||
        cartas[index].descubierta ||
        index == primeraSeleccion?.index) return;

    setState(() {
      cartas[index].descubierta = true;
    });

    await _reproducirSonido(cartas[index].letra);

    if (primeraSeleccion == null) {
      primeraSeleccion = cartas[index]..index = index;
    } else {
      bloquear = true;

      if (cartas[index].letra == primeraSeleccion!.letra) {
        primeraSeleccion = null;
        bloquear = false;
        if (cartas.every((c) => c.descubierta)) {
          await _guardarProgresoMemorama();
          _mostrarDialogoFin();
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          cartas[index].descubierta = false;
          cartas[primeraSeleccion!.index!].descubierta = false;
        });
        primeraSeleccion = null;
        bloquear = false;
      }
    }
  }

  Future<void> _guardarProgresoMemorama() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 4,
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
            content: const Text('¡Has completado el memorama!'),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.of(context).pop();
                  _generarCartas();
                  primeraSeleccion = null;
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
      appBar: AppBar(
        title: const Text('Memorama de letras'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _generarCartas();
              primeraSeleccion = null;
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/fondo_pp2.png',
              fit: BoxFit.cover,
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartas.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final carta = cartas[index];
              return GestureDetector(
                onTap: () => _seleccionarCarta(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: carta.descubierta
                        ? Colors.orange[200]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                  alignment: Alignment.center,
                  child: carta.descubierta
                      ? Text(
                          carta.letra.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      : Image.asset(
                          'assets/logo.png',
                          width: 48,
                          height: 48,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Carta {
  final String letra;
  bool descubierta = false;
  int? index;

  _Carta(this.letra);
}