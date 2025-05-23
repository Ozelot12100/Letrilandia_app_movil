import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'pantalla_principal.dart';
import 'creditos.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(0.3);
      await _backgroundMusicPlayer.play(AssetSource('musica.mp3'), volume: 0.3);
    } catch (e) {
      debugPrint("Error reproduciendo música: $e");
    }
  }

  Future<void> _onStartPressed() async {
    try {
      await _backgroundMusicPlayer.setVolume(0.2);
      await _effectPlayer.play(AssetSource('intro.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 3000));
      await _effectPlayer.play(AssetSource('efecto.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 800));
      await _backgroundMusicPlayer.stop(); // Detener música al cambiar pantalla

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
        );
      }
    } catch (e) {
      debugPrint("Error en efectos de sonido: $e");
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
    _effectPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/letrilandia_fondo.png',
              fit: BoxFit.cover,
            ),
          ),

          // Botón y controles
          SafeArea(
            child: Stack(
              children: [
                // Botón "¡Empezar!"
                Center(
                  child: ElevatedButton(
                    onPressed: _onStartPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.black45,
                      elevation: 6,
                    ),
                    child: Text(
                      '¡Empezar!',
                      style: GoogleFonts.baloo2(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Botón de volumen
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_off,
                      size: 32,
                      color: Colors.deepOrange,
                    ),
                    onPressed: _toggleMusic,
                  ),
                ),

                // Botón de engrane (créditos)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    color: Colors.orangeAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreditosPage(),
                        ),
                      );
                    },
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
