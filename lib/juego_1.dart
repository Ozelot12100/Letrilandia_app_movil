import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Juego1 extends StatefulWidget {
  const Juego1({super.key});

  @override
  State<Juego1> createState() => _Juego1State();
}

class _Juego1State extends State<Juego1> {
  @override
  void initState() {
    super.initState();
  }

  void _reproducirLetra(String letra) {
    final player = AudioPlayer();
    player.play(AssetSource('audio/$letra.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    final letras = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ'.split('');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abecedario'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset('assets/fondo_pp2.png', fit: BoxFit.cover),
          ),

          // Cuadrícula de letras
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children:
                  letras.map((letra) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.primaries[letra.codeUnitAt(0) %
                                Colors.primaries.length],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 3),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () => _reproducirLetra(letra),
                      child: Text(
                        letra,
                        style: TextStyle(
                          fontSize: 32,
                          foreground:
                              Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2
                                ..color = Colors.black,
                        ),
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
