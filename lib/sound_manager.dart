import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  // On crée une instance statique pour qu'elle soit accessible partout
  static final AudioPlayer _player = AudioPlayer();

  // Fonction simple pour jouer un son
  static Future<void> play(String fileName) async {
    // On arrête le son précédent s'il y en a un (pour éviter la cacophonie)
    // Si tu veux que les sons se superposent, enlève la ligne .stop()
    await _player.stop(); 
    
    // On joue le fichier situé dans assets/sounds/
    await _player.play(AssetSource('sounds/$fileName'));
  }
}