import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  void _abrirCorreo() async {
    final Uri correoUri = Uri(
      scheme: 'mailto',
      path: 'egroj1897@gmail.com',
      query: 'subject=Contacto desde Letrilandia',
    );

    if (await canLaunchUrl(correoUri)) {
      await launchUrl(correoUri);
    } else {
      throw 'No se pudo abrir el cliente de correo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 14, 16, 16), // Fondo
      appBar: AppBar(
        title: const Text('Créditos'),
        backgroundColor: const Color.fromARGB(
          255,
          14,
          16,
          16,
        ), //Fondo barra superior
        foregroundColor: const Color.fromRGBO(
          255,
          255,
          255,
          1,
        ), //Letras barra superior
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen centrada
            Image.asset(
              'assets/creditos_1.png',
              width: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),

            // Texto y botón de correo
            const Text(
              'Dudas y aclaraciones: ',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            GestureDetector(
              onTap: _abrirCorreo,
              child: const Text(
                'egroj1897@gmail.com',
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
