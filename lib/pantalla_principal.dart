import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'juego_1.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(0.2);
      await _backgroundMusicPlayer.play(AssetSource('musica.mp3'));
    } catch (e) {
      debugPrint("Error reproduciendo música: $e");
    }
  }

  void _toggleMusic() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _isPlaying
        ? _backgroundMusicPlayer.resume()
        : _backgroundMusicPlayer.pause();
  }

  @override
  void dispose() {
    _backgroundMusicPlayer.dispose();
    super.dispose();
  }

  Widget _buildJuegoButton(String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
                      _buildJuegoButton('assets/images/juego_1_icon.png', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Juego1(),
                          ),
                        );
                      }),
                      // Aquí puedes agregar más botones de juegos
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
