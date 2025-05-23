import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Juego1 extends StatelessWidget {
  const Juego1({super.key});

  void _reproducirLetra(String letra) {
    final player = AudioPlayer();
    player.play(AssetSource('audio/$letra.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    final letras = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ'.split('');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego 1 - Abecedario'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo_pp2.png'),
            fit: BoxFit.cover,
          ),
        ),
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
                  ),
                  onPressed: () => _reproducirLetra(letra),
                  child: Text(
                    letra,
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
