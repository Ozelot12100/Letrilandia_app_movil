import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'juego_1.dart';
import 'juego_2.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  bool _isPlaying = true;

  void _toggleMusic() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Widget _buildJuegoButton(
    String imagePath,
    String audioIntro,
    Widget juegoDestino,
  ) {
    return GestureDetector(
      onTap: () async {
        final player = AudioPlayer();
        try {
          await player.play(AssetSource(audioIntro));
          await Future.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => juegoDestino),
          );
        } catch (e) {
          debugPrint("Error al reproducir audio: $e");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.deepOrange, width: 4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fondo_pp2.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_off,
                      size: 32,
                      color: Colors.deepOrange,
                    ),
                    onPressed: _toggleMusic,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(20),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildJuegoButton(
                        'assets/images/juego_1_icon.png',
                        'audio/seleccionar.mp3',
                        const Juego1(),
                      ),
                      _buildJuegoButton(
                        'assets/images/juego_2_icon.png',
                        'audio/numero.mp3',
                        const Juego2(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
