import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Juego2 extends StatefulWidget {
  const Juego2({super.key});

  @override
  State<Juego2> createState() => _Juego2State();
}

class _Juego2State extends State<Juego2> {
  @override
  void initState() {
    super.initState();
  }

  void _reproducirNumero(String numero) {
    final player = AudioPlayer();
    player.play(AssetSource('audio/$numero.mp3'));
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
