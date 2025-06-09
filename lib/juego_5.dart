import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class Juego5 extends StatefulWidget {
  const Juego5({super.key});

  @override
  State<Juego5> createState() => _Juego5State();
}

class _Juego5State extends State<Juego5> {
  final List<String> letras = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
  ];

  String letraActual = '';
  List<Offset> puntos = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  int puntosAcumulados = 0;
  bool instruccionReproducida = false;

  @override
  void initState() {
    super.initState();
    _elegirNuevaLetra();
    _cargarPuntaje();
    _reproducirInstruccion();
  }

  Future<void> _cargarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      puntosAcumulados = prefs.getInt('puntaje_juego5') ?? 0;
    });
  }

  Future<void> _guardarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puntaje_juego5', puntosAcumulados);
  }

  Future<void> _reiniciarPuntaje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('puntaje_juego5');
    setState(() {
      puntosAcumulados = 0;
    });
  }

  void _elegirNuevaLetra() {
    final random = Random();
    setState(() {
      letraActual = letras[random.nextInt(letras.length)];
      puntos.clear();
    });
  }

  void _reproducirInstruccion() async {
    if (!instruccionReproducida) {
      instruccionReproducida = true;
      // No reproducir audio aquí
    }
  }

  Future<void> _reproducirLetra(String letra) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/$letra.mp3'));
  }

  Future<void> _reproducirIncorrecto() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/de_nuevo.mp3'));
  }

  void _validarDibujo() async {
    if (puntos.length >= 10) {
      // No reproducir audio aquí
      setState(() {
        puntosAcumulados += 10;
      });
      await _guardarPuntaje();
      await _guardarProgresoDibujar();
      _mostrarDialogoFin();
      return;
    } else {
      // No reproducir audio aquí
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Intenta de nuevo')));
    }
  }

  Future<void> _guardarProgresoDibujar() async {
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      await SupabaseService().saveProgress(
        childId: childId,
        gameId: 5,
        score: 1,
        level: 1,
      );
    }
  }

  void _mostrarDialogoFin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades!'),
        content: const Text('¡Has dibujado la letra correctamente!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _elegirNuevaLetra();
            },
            child: const Text('Jugar de nuevo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/fondo_pp2.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Dibuja la letra',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                letraActual.toUpperCase(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Puntos: $puntosAcumulados',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _reiniciarPuntaje,
                child: const Text(
                  'Reiniciar puntaje',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        RenderBox box = context.findRenderObject() as RenderBox;
                        Offset puntoLocal = box.globalToLocal(
                          details.globalPosition,
                        );
                        setState(() {
                          puntos.add(puntoLocal);
                        });
                      },
                      onPanEnd: (_) {
                        puntos.add(Offset.zero);
                      },
                      child: CustomPaint(painter: DibujoPainter(puntos)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => puntos.clear()),
                    icon: const Icon(Icons.clear),
                    label: const Text('Borrar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _validarDibujo,
                    icon: const Icon(Icons.check),
                    label: const Text('Listo'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class DibujoPainter extends CustomPainter {
  final List<Offset> puntos;
  DibujoPainter(this.puntos);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < puntos.length - 1; i++) {
      if (puntos[i] != Offset.zero && puntos[i + 1] != Offset.zero) {
        canvas.drawLine(puntos[i], puntos[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DibujoPainter oldDelegate) => true;
}
