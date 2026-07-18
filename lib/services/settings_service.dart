import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stocke les clés API et préférences de l'utilisateur EN LOCAL sur son
/// appareil, de façon chiffrée (Keychain sur iOS/macOS, Keystore sur Android,
/// DPAPI sur Windows). Rien n'est jamais envoyé à un serveur autre que
/// l'appel direct au fournisseur d'IA choisi (Google, OpenAI, Anthropic,
/// Mistral, Runway) au moment de la requête.
class SettingsService {
  static const _storage = FlutterSecureStorage();

  static const _keyActiveProvider = 'shinra_active_provider';
  static const providers = ['gemini', 'openai', 'claude', 'mistral'];

  static Future<void> setActiveProvider(String provider) =>
      _storage.write(key: _keyActiveProvider, value: provider);

  static Future<String> getActiveProvider() async =>
      await _storage.read(key: _keyActiveProvider) ?? 'gemini';

  static Future<void> setApiKey(String provider, String key) =>
      _storage.write(key: 'shinra_key_$provider', value: key.trim());

  static Future<String> getApiKey(String provider) async =>
      await _storage.read(key: 'shinra_key_$provider') ?? '';

  static Future<void> setModel(String provider, String model) =>
      _storage.write(key: 'shinra_model_$provider', value: model.trim());

  static Future<String> getModel(String provider) async =>
      await _storage.read(key: 'shinra_model_$provider') ?? '';

  // Runway (vidéo) est un fournisseur à part, indépendant du chat.
  static Future<void> setRunwayKey(String key) =>
      _storage.write(key: 'shinra_key_runway', value: key.trim());

  static Future<String> getRunwayKey() async =>
      await _storage.read(key: 'shinra_key_runway') ?? '';

  static Future<void> setStabilityKey(String key) =>
      _storage.write(key: 'shinra_key_stability', value: key.trim());

  static Future<String> getStabilityKey() async =>
      await _storage.read(key: 'shinra_key_stability') ?? '';

  static Future<void> setDidKey(String key) =>
      _storage.write(key: 'shinra_key_did', value: key.trim());

  static Future<String> getDidKey() async =>
      await _storage.read(key: 'shinra_key_did') ?? '';

  /// Renvoie {provider, apiKey, model} du fournisseur actuellement actif,
  /// prêt à être injecté dans une requête vers le backend.
  static Future<Map<String, String>> getActiveConfig() async {
    final provider = await getActiveProvider();
    final apiKey = await getApiKey(provider);
    final model = await getModel(provider);
    return {'provider': provider, 'apiKey': apiKey, 'model': model};
  }

  static Future<void> setPairingToken(String token) =>
      _storage.write(key: 'shinra_pairing_token', value: token);

  static Future<String> getPairingToken() async =>
      await _storage.read(key: 'shinra_pairing_token') ?? '';

  static Future<void> setVoiceProfile(String profile) =>
      _storage.write(key: 'shinra_voice_profile', value: profile);

  static Future<String> getVoiceProfile() async =>
      await _storage.read(key: 'shinra_voice_profile') ?? '⚡ Adam (Masculin)';

  static Future<Map<String, String>> getAllKeys() async {
    final result = <String, String>{};
    for (final p in providers) {
      result[p] = await getApiKey(p);
    }
    result['runway'] = await getRunwayKey();
    return result;
  }
}
