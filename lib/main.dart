import 'package:flutter/material.dart';
import 'pantalla_inicio.dart';

void main() {
  runApp(LetrilandiaApp());
}

class LetrilandiaApp extends StatelessWidget {
  const LetrilandiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Letrilandia',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: PantallaInicio(),
    );
  }
}
