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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ajustar columnas según ancho
            int crossAxisCount = (constraints.maxWidth ~/ 180).clamp(3, 8);
            double maxButtonSize = 140;
            double spacing = 16;
            double totalSpacing = spacing * (crossAxisCount + 1);
            double buttonSize = ((constraints.maxWidth - totalSpacing) /
                    crossAxisCount)
                .clamp(80, maxButtonSize);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              padding: EdgeInsets.all(spacing),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              children:
                  letras.map((letra) {
                    return Center(
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor:
                                Colors.primaries[letra.codeUnitAt(0) %
                                    Colors.primaries.length],
                            padding: EdgeInsets.zero,
                            elevation: 6,
                          ),
                          onPressed: () => _reproducirLetra(letra),
                          child: Text(
                            letra,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ),
    );
  }
}
