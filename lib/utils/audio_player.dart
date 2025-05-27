import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

void reproducirAudio(String letra) async {
  await player.stop();
  await player.play(AssetSource('audio/$letra.mp3'));
}
