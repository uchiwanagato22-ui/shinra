import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Client du backend Pro hébergé (Cloud Run). Utilisé uniquement pour les
/// utilisateurs dont le plan Firestore n'est pas "free" — eux n'ont pas
/// besoin de mettre leurs propres clés API, c'est Nagato qui les fournit
/// côté serveur, protégées derrière la vérification d'abonnement.
///
/// ⚠️ Le mode Pro ne couvre QUE le chat/code (ce qui peut tourner sur un
/// serveur distant). Le contrôle du PC (ouvrir une app, exécuter du code,
/// vision d'écran) reste forcément local : un serveur cloud ne peut pas
/// piloter la souris de l'utilisateur. Ces fonctions restent sur le backend
/// local (FastAPI) même pour un abonné Pro.
class ProService {
  // ⚠️ À remplacer par l'URL réelle après `gcloud run deploy`
  // (le terminal affichera un lien du type https://shinra-pro-backend-xxxxx.a.run.app).
  // Laisser vide ou à 'NOT_CONFIGURED' désactive silencieusement le mode Pro
  // sans faire planter l'app — l'utilisateur utilisera ses propres clés API.
  static const String proBaseUrl = 'NOT_CONFIGURED';

  /// Retourne true si le backend Pro est configuré et accessible.
  static bool get isConfigured =>
      proBaseUrl.isNotEmpty &&
      proBaseUrl != 'NOT_CONFIGURED' &&
      !proBaseUrl.contains('REMPLACE_MOI');

  static Future<String> sendChat(
    List<Map<String, String>> conversation, {
    String taskHint = '',
  }) async {
    if (!isConfigured) {
      return '⚙️ Mode Pro non configuré. Utilise tes propres clés API dans Config pour un accès illimité.';
    }

    final idToken = await AuthService.getIdToken();
    if (idToken == null) {
      return '❌ Connecte-toi pour utiliser le mode Pro.';
    }
    try {
      final response = await http
          .post(
            Uri.parse('$proBaseUrl/pro/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'messages': conversation
                  .map((m) => {
                        'role': m['role'] == 'user' ? 'user' : 'model',
                        'content': m['content']
                      })
                  .toList(),
              'task_hint': taskHint,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 429) {
        return '⏱️ ${data['detail'] ?? 'Quota Pro atteint pour aujourd\'hui.'}';
      }
      if (response.statusCode == 403) {
        return '🔒 ${data['detail'] ?? 'Abonnement Pro requis.'}';
      }
      if (response.statusCode != 200) {
        return '❌ Erreur serveur Pro (${response.statusCode}).';
      }
      return data['result'] ?? 'Pas de réponse du serveur Pro.';
    } catch (e) {
      return '❌ Impossible de joindre le serveur Pro : $e';
    }
  }
}
