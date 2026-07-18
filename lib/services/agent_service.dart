import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'auth_service.dart';

class AgentService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'online': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'online': false, 'error': e.toString()};
    }
  }

  static Future<String> _ensureToken() async {
    var token = await SettingsService.getPairingToken();
    if (token.isNotEmpty) return token;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/pair'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        token = data['token'] ?? '';
        if (token.isNotEmpty) {
          await SettingsService.setPairingToken(token);
        }
      }
    } catch (_) {
      // L'appariement échoue si le backend n'est pas lancé en local ; les
      // appels suivants renverront une erreur d'authentification claire.
    }
    return token;
  }

  static Future<Map<String, dynamic>> _postAction(
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final token = await _ensureToken();
    final response = await http
        .post(
          Uri.parse('$baseUrl/action'),
          headers: {
            'Content-Type': 'application/json',
            'X-Shinra-Token': token,
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (response.statusCode == 401) {
      // Jeton périmé/invalide : on force un ré-appariement au prochain appel.
      await SettingsService.setPairingToken('');
      return {'result': '❌ Sécurité : ré-appariement nécessaire, relance l\'action.'};
    }
    if (response.statusCode != 200) {
      return {'result': 'Erreur serveur: ${response.statusCode}'};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Exécute UNE étape de la boucle d'agent. Retourne une Map avec :
  /// - done: true si c'est la réponse finale (result contient le texte)
  /// - needs_confirmation: true si une action sensible attend l'accord de Nagato
  ///   (result = texte déjà écrit par Shinra, action_label = description humaine,
  ///   raw_action = à renvoyer tel quel à executeConfirmedAction, assistant_raw
  ///   = à remettre dans l'historique pour l'étape suivante)
  /// - sinon : action safe déjà exécutée (tool_result, assistant_raw, result)
  static Future<Map<String, dynamic>> chatStep(
    List<Map<String, String>> conversation, {
    String projectPath = '',
  }) async {
    final cfg = await SettingsService.getActiveConfig();
    if (cfg['apiKey']!.isEmpty) {
      return {'done': true, 'result': '❌ Aucune clé API configurée pour ${cfg['provider']}. Va dans Config pour l\'ajouter.'};
    }
    final formattedMessages = conversation
        .map((m) => {
              'role': m['role'] == 'user' ? 'user' : 'model',
              'content': m['content'] ?? '',
            })
        .toList();
    final idToken = await AuthService.getIdToken();
    final openaiKey = await SettingsService.getApiKey('openai');
    final geminiKey = await SettingsService.getApiKey('gemini');
    final stabilityKey = await SettingsService.getStabilityKey();
    final runwayKey = await SettingsService.getRunwayKey();
    final didKey = await SettingsService.getDidKey();
    try {
      return await _postAction({
        'action': 'chat_agent',
        'messages': formattedMessages,
        'path': projectPath,
        'provider': cfg['provider'],
        'api_key': cfg['apiKey'],
        'model': cfg['model'],
        'id_token': idToken ?? '',
        'openai_key': openaiKey,
        'gemini_key': geminiKey,
        'stability_key': stabilityKey,
        'runway_key': runwayKey,
        'did_key': didKey,
      });
    } catch (e) {
      return {'done': true, 'result': 'Impossible de joindre l\'agent Python. Lance uvicorn.'};
    }
  }

  /// À appeler après que Nagato ait confirmé (ou refusé) une action sensible.
  static Future<String> executeConfirmedAction(String rawAction, bool approved) async {
    final idToken = await AuthService.getIdToken();
    final openaiKey = await SettingsService.getApiKey('openai');
    final geminiKey = await SettingsService.getApiKey('gemini');
    final stabilityKey = await SettingsService.getStabilityKey();
    final runwayKey = await SettingsService.getRunwayKey();
    final didKey = await SettingsService.getDidKey();
    try {
      final data = await _postAction({
        'action': 'execute_confirmed_action',
        'raw_action': rawAction,
        'approved': approved,
        'id_token': idToken ?? '',
        'openai_key': openaiKey,
        'gemini_key': geminiKey,
        'stability_key': stabilityKey,
        'runway_key': runwayKey,
        'did_key': didKey,
      });
      return data['tool_result'] ?? '';
    } catch (e) {
      return 'Erreur exécution action : $e';
    }
  }

  // ── 🔥 AJOUT DES DEUX FONCTIONS ATTENDUES PAR BROWSER_SCREEN ──
  static Future<String> webSearch(String query) async {
    try {
      final data = await _postAction({
        'action': 'deep_research',
        'query': query,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion Recherche Web: $e';
    }
  }

  static Future<String> webScreenshot(String url, {String? savePath}) async {
    try {
      final data = await _postAction({
        'action': 'observe_screen',
        'path': url, // Passe l'URL ciblée par Playwright à ton module Python
        'command': savePath ?? '',
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion Capture Écran: $e';
    }
  }

  static Future<String> listDir(String path) async {
    try {
      final data = await _postAction({'action': 'list_dir', 'path': path});
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion listDir: $e';
    }
  }

  static Future<String> projectContext(String path) async {
    try {
      final data =
          await _postAction({'action': 'project_context', 'path': path});
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion contexte projet: $e';
    }
  }

  static Future<String> observeScreen({String projectPath = ''}) async {
    try {
      // La vision d'écran utilise Gemini pour le moment, quel que soit le
      // provider de chat actif.
      final apiKey = await SettingsService.getApiKey('gemini');
      final model = await SettingsService.getModel('gemini');
      if (apiKey.isEmpty) {
        return '❌ La vision d\'écran nécessite ta clé Gemini. Ajoute-la dans Config.';
      }
      final data = await _postAction({
        'action': 'observe_screen',
        'path': projectPath,
        'provider': 'gemini',
        'api_key': apiKey,
        'model': model,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion observation: $e';
    }
  }

  static Future<String> readProjectFile(
      String projectPath, String relativePath) async {
    try {
      final data = await _postAction({
        'action': 'read_project_file',
        'path': projectPath,
        'query': relativePath,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur lecture projet: $e';
    }
  }

  static Future<String> applyProjectFile(
    String projectPath,
    String relativePath,
    String content,
  ) async {
    try {
      final data = await _postAction({
        'action': 'apply_project_file',
        'path': projectPath,
        'query': relativePath,
        'content': content,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur ecriture projet: $e';
    }
  }

  static Future<String> rpaPlan(String task, {String projectPath = ''}) async {
    try {
      final data = await _postAction({
        'action': 'rpa_plan',
        'path': projectPath,
        'query': task,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur RPA: $e';
    }
  }

  static Future<String> studioFlash(String topic,
      {String projectPath = ''}) async {
    try {
      final data = await _postAction({
        'action': 'studio_flash',
        'path': projectPath,
        'query': topic,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur Studio Flash: $e';
    }
  }

  static Future<Map<String, dynamic>> creditStatus() async {
    try {
      final data = await _postAction({'action': 'credit_status'});
      return data['result'] is Map<String, dynamic>
          ? data['result'] as Map<String, dynamic>
          : {'balance': 0, 'plan': 'UNKNOWN'};
    } catch (e) {
      return {'balance': 0, 'plan': 'OFFLINE', 'error': e.toString()};
    }
  }

  /// Génère une image via OpenAI (gpt-image-1) ou Gemini (Imagen 3), selon
  /// le fournisseur choisi. Retourne {result, path}.
  static Future<Map<String, String>> generateImage(
    String prompt,
    String provider,
  ) async {
    try {
      final apiKey = await SettingsService.getApiKey(provider);
      final model = await SettingsService.getModel(provider);
      if (apiKey.isEmpty) {
        return {
          'result': '❌ Aucune clé API $provider configurée pour l\'image. Va dans Config.'
        };
      }
      final data = await _postAction(
        {
          'action': 'generate_image',
          'query': prompt,
          'provider': provider,
          'api_key': apiKey,
          'model': model,
        },
        timeout: const Duration(seconds: 120),
      );
      return {
        'result': data['result']?.toString() ?? '',
        'path': data['path']?.toString() ?? '',
      };
    } catch (e) {
      return {'result': 'Erreur connexion Image: $e'};
    }
  }

  /// Génère une vidéo via Runway ML (clé dédiée, indépendante des clés de
  /// chat). Peut prendre jusqu'à quelques minutes. Retourne {result, path}.
  static Future<Map<String, String>> generateMusic(
    String prompt, {
    int durationSeconds = 30,
  }) async {
    try {
      final apiKey = await SettingsService.getStabilityKey();
      if (apiKey.isEmpty) {
        return {'result': '❌ Aucune clé API Stability configurée pour la musique. Va dans Config.'};
      }
      final data = await _postAction(
        {
          'action': 'generate_music',
          'query': prompt,
          'api_key': apiKey,
          'duration': durationSeconds,
        },
        timeout: const Duration(seconds: 150),
      );
      return {
        'result': data['result']?.toString() ?? '',
        'path': data['path']?.toString() ?? '',
      };
    } catch (e) {
      return {'result': 'Erreur connexion Musique: $e'};
    }
  }

  static Future<Map<String, String>> generateVideo(
    String prompt, {
    int durationSeconds = 5,
  }) async {
    try {
      final apiKey = await SettingsService.getRunwayKey();
      if (apiKey.isEmpty) {
        return {
          'result': '❌ Aucune clé API Runway configurée pour la vidéo. Va dans Config.'
        };
      }
      final data = await _postAction(
        {
          'action': 'generate_video',
          'query': prompt,
          'api_key': apiKey,
          'duration': durationSeconds,
        },
        timeout: const Duration(seconds: 360),
      );
      return {
        'result': data['result']?.toString() ?? '',
        'path': data['path']?.toString() ?? '',
      };
    } catch (e) {
      return {'result': 'Erreur connexion Video: $e'};
    }
  }

  static Future<String> runCode(String command) async {
    try {
      final data =
          await _postAction({'action': 'run_code', 'command': command});
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion terminal: $e';
    }
  }

  static Future<String> generateVoice(String text, String voiceProfile) async {
    try {
      final data = await _postAction({
        'action': 'generate_voice',
        'content': text,
        'query': voiceProfile,
      });
      return data['result'] ?? '';
    } catch (e) {
      return 'Erreur connexion Voix: $e';
    }
  }

  /// Ouvre directement une application installée (ex: "Blender"), avec un
  /// fichier optionnel à charger. Utile hors du chat (bouton rapide, etc.)
  // ── 📊 MISSION CONTROL ──
  static Future<List<Map<String, dynamic>>> listMissions() async {
    final data = await _postAction({'action': 'list_missions'});
    final missions = data['missions'];
    if (missions is List) return missions.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<void> createMission(String title, {String project = '', int progress = 0, String status = 'active'}) async {
    await _postAction({
      'action': 'create_mission',
      'query': title,
      'path': project,
      'command': status,
      'duration': progress,
    });
  }

  static Future<void> updateMission(String id, {int? progress, String? status, String? title}) async {
    await _postAction({
      'action': 'update_mission',
      'query': id,
      'duration': progress,
      'command': status,
      'content': title,
    });
  }

  static Future<void> deleteMission(String id) async {
    await _postAction({'action': 'delete_mission', 'query': id});
  }

  // ── 📁 PROJECTS ──
  static Future<List<Map<String, dynamic>>> listProjects() async {
    final data = await _postAction({'action': 'list_projects'});
    final projects = data['projects'];
    if (projects is List) return projects.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<void> createProject(String name, {String path = '', String description = ''}) async {
    await _postAction({
      'action': 'create_project',
      'query': name,
      'path': path,
      'content': description,
    });
  }

  static Future<void> deleteProject(String id) async {
    await _postAction({'action': 'delete_project', 'query': id});
  }

  static Future<Map<String, String>> generateWebsite(String description) async {
    try {
      final cfg = await SettingsService.getActiveConfig();
      if (cfg['apiKey']!.isEmpty) {
        return {'result': '❌ Aucune clé API configurée pour ${cfg['provider']}. Va dans Config.'};
      }
      final data = await _postAction(
        {
          'action': 'generate_website',
          'query': description,
          'provider': cfg['provider'],
          'api_key': cfg['apiKey'],
          'model': cfg['model'],
        },
        timeout: const Duration(seconds: 120),
      );
      return {
        'result': data['result']?.toString() ?? '',
        'path': data['path']?.toString() ?? '',
        'html': data['html']?.toString() ?? '',
      };
    } catch (e) {
      return {'result': 'Erreur connexion Site Web : $e'};
    }
  }

  // ── ⚙️ AUTOMATISATION (workflows) ──
  static Future<List<Map<String, dynamic>>> listWorkflows() async {
    final data = await _postAction({'action': 'list_workflows'});
    final list = data['workflows'];
    if (list is List) return list.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<void> createWorkflow({
    required String name,
    required String watchFolder,
    required String filePattern,
    required String discordWebhook,
    required String archiveFolder,
  }) async {
    final cfg = await SettingsService.getActiveConfig();
    await _postAction({
      'action': 'create_workflow',
      'query': name,
      'watch_folder': watchFolder,
      'file_pattern': filePattern,
      'discord_webhook': discordWebhook,
      'archive_folder': archiveFolder,
      'provider': cfg['provider'],
      'api_key': cfg['apiKey'],
      'model': cfg['model'],
    });
  }

  static Future<void> deleteWorkflow(String id) async {
    await _postAction({'action': 'delete_workflow', 'workflow_id': id});
  }

  static Future<void> toggleWorkflow(String id, bool active) async {
    await _postAction({'action': 'toggle_workflow', 'workflow_id': id, 'approved': active});
  }

  static Future<String> getGreeting({String userName = 'Nagato'}) async {
    try {
      final idToken = await AuthService.getIdToken();
      final data = await _postAction({
        'action': 'get_greeting',
        'query': userName,
        'id_token': idToken ?? '',
      });
      return data['result'] ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<String> openApp(String appName, {String filePath = ''}) async {
    final data = await _postAction({
      'action': 'open_app',
      'query': appName,
      'path': filePath,
    });
    return data['result'] ?? '';
  }

  /// Cherche un fichier par mot-clé dans Bureau/Documents/Téléchargements.
  static Future<List<String>> findFile(String keyword) async {
    final data = await _postAction({'action': 'find_file', 'query': keyword});
    final matches = data['matches'];
    if (matches is List) {
      return matches.map((e) => e.toString()).toList();
    }
    return [];
  }
}