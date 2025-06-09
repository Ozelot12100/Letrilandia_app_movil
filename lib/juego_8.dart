import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:confetti/confetti.dart';

class Juego8 extends StatefulWidget {
  const Juego8({super.key});

  @override
  State<Juego8> createState() => _JuegoMemoramaNumerosState();
}

class _JuegoMemoramaNumerosState extends State<Juego8> {
  final List<String> numeros = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  late List<_CartaNumero> cartas;
  _CartaNumero? primeraSeleccion;
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
    final List<_CartaNumero> generadas = [];
    // Selecciona 16 números aleatorios (si hay menos de 16, usa todos)
    final numerosSeleccionados = List<String>.from(numeros)..shuffle();
    final seleccionados = numerosSeleccionados.take(16).toList();
    for (var numero in seleccionados) {
      generadas.add(_CartaNumero(numero));
      generadas.add(_CartaNumero(numero));
    }
    generadas.shuffle(Random());
    setState(() {
      cartas = generadas;
    });
  }

  Future<void> _reproducirSonido(String numero) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/$numero.mp3'));
  }

  void _seleccionarCarta(int index) async {
    if (bloquear ||
        cartas[index].descubierta ||
        index == primeraSeleccion?.index)
      return;

    setState(() {
      cartas[index].descubierta = true;
    });

    await _reproducirSonido(cartas[index].numero);

    if (primeraSeleccion == null) {
      primeraSeleccion = cartas[index]..index = index;
    } else {
      bloquear = true;

      if (cartas[index].numero == primeraSeleccion!.numero) {
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
        gameId: 8,
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
            content: const Text('¡Has completado el memorama de números!'),
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
        title: const Text('Memorama de números'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => setState(() {
                  _generarCartas();
                  primeraSeleccion = null;
                }),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fondo_pp2.png', fit: BoxFit.cover),
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
                    color:
                        carta.descubierta
                            ? Colors.lightGreen[200]
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                  alignment: Alignment.center,
                  child:
                      carta.descubierta
                          ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/numeros/${carta.numero}.png',
                              fit: BoxFit.contain,
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

class _CartaNumero {
  final String numero;
  bool descubierta = false;
  int? index;

  _CartaNumero(this.numero);
}
