import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';

/// Mode vocal complet : Nagato parle (reconnaissance vocale locale, gratuite,
/// via le moteur natif de l'OS) → texte envoyé au chat → réponse de Shinra
/// → lue à voix haute (fichier généré par Kokoro côté backend local).
class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  static Future<bool> _ensureInit() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (e) => print('Erreur reconnaissance vocale : $e'),
    );
    return _initialized;
  }

  static bool get isListening => _speech.isListening;
  static bool get isAvailable => _initialized;

  /// Démarre l'écoute. [onPartialResult] reçoit le texte au fur et à mesure
  /// (utile pour afficher en direct), [onFinalResult] reçoit le texte final
  /// une fois que Nagato a fini de parler.
  static Future<bool> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onFinalResult,
    String localeId = 'fr_FR',
  }) async {
    final available = await _ensureInit();
    if (!available) return false;

    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    return true;
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static Future<void> playFile(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      print('Erreur lecture audio : $e');
    }
  }

  static Future<void> stopPlayback() async {
    await _player.stop();
  }
}
