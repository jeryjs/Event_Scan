import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static void playSuccessSound() {
    _player.play(AssetSource('sounds/success.mp3'));
  }

  static void playFailureSound() {
    _player.play(AssetSource('sounds/failure.mp3'), volume: 0.5);
  }
}
