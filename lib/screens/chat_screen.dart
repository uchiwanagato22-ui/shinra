import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/agent_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../services/pro_service.dart';
import '../services/voice_service.dart';
import '../services/firestore_service.dart';
import '../widgets/shinra_logo.dart';
import 'browser_screen.dart';
import 'about_screen.dart';
import 'dashboard_screen.dart';
import 'studio_screen.dart';
import 'subscription_screen.dart';
import 'automation_screen.dart';
import 'music_screen.dart';
import 'store_screen.dart';
import 'community_screen.dart';
import 'website_screen.dart';
import 'config_screen.dart';
import 'files_screen.dart';
import 'images_screen.dart';
import 'terminal_screen.dart';
import 'video_screen.dart';
import 'voice_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatCtrl = TextEditingController();
  final TextEditingController _projectCtrl = TextEditingController(
    text: 'C:/Users/uchiwa nagato/shinra_ia',
  );
  final TextEditingController _fileCtrl =
      TextEditingController(text: 'lib/main.dart');
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _taskCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, String>> _messages = [];

  int _currentScreenIndex = 9;
  bool _loading = false;
  String _thinkingPhrase = 'Je réfléchis...';
  static const List<String> _thinkingPhrases = [
    'Je réfléchis...',
    'Laisse-moi regarder ça.',
    'Je prépare la meilleure solution.',
    'Analyse en cours...',
    'Hmph... je vois plusieurs possibilités.',
    'Intéressant... un instant.',
  ];
  static const List<String> _codePhrases = [
    'Je code...',
    'J\'écris la fonction.',
    'Je débogue ça.',
    'Compilation mentale en cours...',
  ];
  static const List<String> _imagePhrases = [
    'Je génère l\'image...',
    'Je peins les détails.',
    'Composition en cours...',
  ];
  static const List<String> _videoPhrases = [
    'Je génère la vidéo...',
    'Montage en cours...',
    'Je construis les scènes.',
  ];
  static const List<String> _musicPhrases = [
    'Je compose la musique...',
    'Je règle le rythme.',
    'Je mixe les pistes...',
  ];
  static const List<String> _researchPhrases = [
    'Je fais des recherches...',
    'J\'explore les sources.',
    'Je vérifie les faits...',
  ];

  String _pickThinkingPhrase(String userText) {
    final text = userText.toLowerCase();
    List<String> pool = _thinkingPhrases;
    if (RegExp(r'\b(code|bug|fonction|flutter|python|erreur|compile|script|dart)\b').hasMatch(text)) {
      pool = _codePhrases;
    } else if (RegExp(r'\b(image|photo|dessine|illustration|logo)\b').hasMatch(text)) {
      pool = _imagePhrases;
    } else if (RegExp(r'\b(vidéo|video|clip|montage)\b').hasMatch(text)) {
      pool = _videoPhrases;
    } else if (RegExp(r'\b(musique|son|chanson|mélodie|beat)\b').hasMatch(text)) {
      pool = _musicPhrases;
    } else if (RegExp(r'\b(cherche|recherche|analyse|vérifie)\b').hasMatch(text)) {
      pool = _researchPhrases;
    }
    return (List<String>.from(pool)..shuffle()).first;
  }
  String _projectContext = '';
  Map<String, dynamic> _health = {'online': false};
  Map<String, dynamic> _credits = {'balance': 0, 'plan': 'OFFLINE'};
  String _activeProvider = 'gemini';
  String _userPlan = 'free';
  bool _isListening = false;
  bool _voiceModeOn = false;

  static const Map<String, String> _providerLabels = {
    'gemini': 'GEMINI',
    'openai': 'OPENAI',
    'claude': 'CLAUDE',
    'mistral': 'MISTRAL',
  };

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const red = Color(0xFFFF4D6D);
  static const bg = Color(0xFF07090F);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);
  static const ink = Color(0xFFC0D0E8);

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _loadGreeting();
  }

  Future<void> _loadGreeting() async {
    final greeting = await AgentService.getGreeting();
    if (!mounted) return;
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': greeting.isNotEmpty
            ? greeting
            : 'Shinra IA en ligne. Choisis un dossier projet, synchronise le contexte, puis donne un ordre.',
      });
    });
  }

  Future<void> _refreshAll() async {
    final health = await AgentService.healthCheck();
    final credits = await AgentService.creditStatus();
    final provider = await SettingsService.getActiveProvider();
    final profile = await FirestoreService.getProfile();
    if (!mounted) return;
    setState(() {
      _health = health;
      _credits = credits;
      _activeProvider = provider;
      _userPlan = (profile?['plan'] ?? 'free').toString();
    });
    await _loadProjectContext(silent: true);
  }

  Future<void> _loadProjectContext({bool silent = false}) async {
    final path = _projectCtrl.text.trim();
    if (path.isEmpty) return;
    final context = await AgentService.projectContext(path);
    if (!mounted) return;
    setState(() {
      _projectContext = context;
      if (!silent) {
        _messages.add({
          'role': 'assistant',
          'content': 'Contexte projet synchronise.\n$context'
        });
      }
    });
    _scrollDown();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await VoiceService.stopListening();
      setState(() => _isListening = false);
      return;
    }
    final started = await VoiceService.startListening(
      onPartialResult: (text) => setState(() => _chatCtrl.text = text),
      onFinalResult: (text) {
        setState(() {
          _chatCtrl.text = text;
          _isListening = false;
        });
        if (text.trim().isNotEmpty) _send();
      },
    );
    if (!mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone indisponible ou permission refusée.')),
      );
      return;
    }
    setState(() => _isListening = true);
  }

  Future<void> _speakIfVoiceModeOn(String text) async {
    if (!_voiceModeOn || text.trim().isEmpty) return;
    final toSpeak = text.length > 600 ? '${text.substring(0, 600)}...' : text;
    final voiceProfile = await SettingsService.getVoiceProfile();
    final result = await AgentService.generateVoice(toSpeak, voiceProfile);
    if (result.contains('❌')) return;
    await VoiceService.playFile('C:/shinra_project/output/voice_01.wav');
  }

  Future<void> _send() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
      _thinkingPhrase = _pickThinkingPhrase(text);
    });
    _scrollDown();

    final conversation = _messages
        .map((m) => {'role': m['role'] ?? 'user', 'content': m['content'] ?? ''})
        .toList();
    final projectPath = _projectCtrl.text.trim();

    final cfg = await SettingsService.getActiveConfig();
    final hasOwnKey = cfg['apiKey']!.isNotEmpty;

    // Règle : Pro (et paliers au-dessus) passent TOUJOURS par le serveur de
    // Nagato. En "trial", si l'utilisateur a déjà ajouté sa propre clé, on le
    // laisse en mode local illimité (gratuit, sur son propre budget) plutôt
    // que de gaspiller son quota d'essai. Sans clé perso en trial : on utilise
    // les clés de Nagato via le serveur, mais avec un quota de 5 messages/jour.
    final usesCloudBackend = _userPlan == 'pro' ||
        _userPlan == 'team' ||
        _userPlan == 'business' ||
        _userPlan == 'enterprise' ||
        (_userPlan == 'trial' && !hasOwnKey);

    if (usesCloudBackend) {
      final result = await ProService.sendChat(conversation, taskHint: projectPath.isNotEmpty ? 'code' : '');
      final credits = await AgentService.creditStatus();
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': result});
        _credits = credits;
        _loading = false;
      });
      _scrollDown();
      _speakIfVoiceModeOn(result);
      return;
    }

    final narration = <String>[];
    String? lastAgent;

    for (int i = 0; i < 6; i++) {
      final step = await AgentService.chatStep(conversation, projectPath: projectPath);
      final stepText = (step['result'] ?? '').toString().trim();
      if (stepText.isNotEmpty) narration.add(stepText);
      if (step['agent'] != null) lastAgent = step['agent'].toString();

      if (step['done'] == true) break;

      final assistantRaw = (step['assistant_raw'] ?? '').toString();

      if (step['needs_confirmation'] == true) {
        final approved = await _askConfirmation((step['action_label'] ?? '').toString());
        final toolResult = await AgentService.executeConfirmedAction(
          (step['raw_action'] ?? '').toString(),
          approved,
        );
        conversation.add({'role': 'model', 'content': assistantRaw});
        conversation.add({
          'role': 'user',
          'content': '[RÉSULTAT DE L\'ACTION]\n$toolResult\n\nContinue la tâche si nécessaire, ou termine par <action>done</action> si c\'est fini.',
        });
        if (!approved) narration.add('🚫 Action refusée : ${step['action_label']}');
      } else {
        final toolResult = (step['tool_result'] ?? '').toString();
        conversation.add({'role': 'model', 'content': assistantRaw});
        conversation.add({
          'role': 'user',
          'content': '[RÉSULTAT DE L\'ACTION]\n$toolResult\n\nContinue la tâche si nécessaire, ou termine par <action>done</action> si c\'est fini.',
        });
      }

      if (i == 5) {
        narration.add('⏱️ Limite de 6 étapes atteinte pour cette tâche. Dis-moi si je dois continuer.');
      }
    }

    final credits = await AgentService.creditStatus();
    if (!mounted) return;
    final finalNarration = narration.isNotEmpty ? narration.join('\n\n') : 'Shinra n\'a rien renvoyé cette fois-ci.';
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': finalNarration,
        if (lastAgent != null) 'agent': lastAgent!,
      });
      _credits = credits;
      _loading = false;
    });
    _scrollDown();
    _speakIfVoiceModeOn(finalNarration);
  }

  /// Popup de confirmation avant toute action sensible (écrire un fichier,
  /// exécuter une commande, ouvrir une app). Nagato garde toujours la main.
  Future<bool> _askConfirmation(String actionLabel) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1225),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          Text('CONFIRMATION REQUISE',
              style: GoogleFonts.shareTechMono(color: Colors.orangeAccent, fontSize: 13)),
        ]),
        content: Text(
          'Shinra veut faire ceci :\n\n$actionLabel',
          style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Refuser', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: crimson.withOpacity(0.85)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('AUTORISER', style: GoogleFonts.shareTechMono(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _observeScreen() async {
    setState(() => _loading = true);
    final result =
        await AgentService.observeScreen(projectPath: _projectCtrl.text.trim());
    final credits = await AgentService.creditStatus();
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': result});
      _credits = credits;
      _loading = false;
    });
    _scrollDown();
  }

  Future<void> _readFile() async {
    final result = await AgentService.readProjectFile(
      _projectCtrl.text.trim(),
      _fileCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _contentCtrl.text = result;
      _messages.add({
        'role': 'assistant',
        'content': 'Fichier charge: ${_fileCtrl.text.trim()}'
      });
    });
  }

  Future<void> _applyFile() async {
    final result = await AgentService.applyProjectFile(
      _projectCtrl.text.trim(),
      _fileCtrl.text.trim(),
      _contentCtrl.text,
    );
    final credits = await AgentService.creditStatus();
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': result});
      _credits = credits;
    });
    _scrollDown();
  }

  Future<void> _makeRpaPlan() async {
    final task = _taskCtrl.text.trim();
    if (task.isEmpty) return;
    final result =
        await AgentService.rpaPlan(task, projectPath: _projectCtrl.text.trim());
    if (!mounted) return;
    setState(() => _messages.add({'role': 'assistant', 'content': result}));
    _scrollDown();
  }

  Future<void> _studioFlash() async {
    final topic = _taskCtrl.text.trim();
    if (topic.isEmpty) return;
    setState(() => _loading = true);
    final result = await AgentService.studioFlash(topic,
        projectPath: _projectCtrl.text.trim());
    final credits = await AgentService.creditStatus();
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': result});
      _credits = credits;
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _serviceOnline(String key) {
    final services = _health['services'];
    if (services is Map && services[key] is bool) return services[key] as bool;
    return _health['online'] == true && key == 'fastapi';
  }

  Widget _getMainContent() {
    switch (_currentScreenIndex) {
      case 0:
        return _buildAgentWorkspace();
      case 1:
        return const ImagesScreen();
      case 2:
        return const VideoScreen();
      case 3:
        return const VoiceScreen();
      case 4:
        return const FilesScreen();
      case 5:
        return const TerminalScreen();
      case 6:
        return const BrowserScreen();
      case 7:
        return const ConfigScreen();
      case 8:
        return const AboutScreen();
      case 9:
        return DashboardScreen(health: _health, credits: _credits, activeProvider: _activeProvider);
      case 10:
        return StudioScreen(
          onNavigate: (index) => setState(() => _currentScreenIndex = index),
          onPrefillChat: (text) {
            _chatCtrl.text = text;
            setState(() => _currentScreenIndex = 0);
          },
        );
      case 11:
        return const SubscriptionScreen();
      case 12:
        return const WebsiteScreen();
      case 13:
        return const AutomationScreen();
      case 14:
        return const MusicScreen();
      case 15:
        return StoreScreen(
          onUseTemplate: (text) {
            _chatCtrl.text = text;
            setState(() => _currentScreenIndex = 0);
          },
        );
      case 16:
        return const CommunityScreen();
      default:
        return _buildAgentWorkspace();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                _buildProjectBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_currentScreenIndex),
                      child: _getMainContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 216,
      color: surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      const BoxDecoration(color: crimson, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'SHINRA.IA',
                  style: GoogleFonts.shareTechMono(
                      color: crimson, fontSize: 13, letterSpacing: 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _navItem(Icons.space_dashboard_outlined, 'Dashboard', 9),
          _navItem(Icons.auto_awesome_outlined, 'Studio', 10),
          _navItem(Icons.dashboard_outlined, 'OS-Agent', 0),
          _navItem(Icons.image_outlined, 'Images', 1),
          _navItem(Icons.videocam_outlined, 'Video', 2),
          _navItem(Icons.mic_outlined, 'Voix', 3),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Color(0xFF1A2A3A)),
          ),
          _navItem(Icons.folder_outlined, 'Fichiers', 4),
          _navItem(Icons.terminal, 'Terminal', 5),
          _navItem(Icons.language, 'Chrome', 6),
          _navItem(Icons.settings_outlined, 'Config', 7),
          _navItem(Icons.info_outline, 'About', 8),
          _navItem(Icons.workspace_premium_outlined, 'Abonnement', 11),
          _navItem(Icons.bolt_outlined, 'Automatisation', 13),
          _navItem(Icons.music_note_outlined, 'Musique', 14),
          _navItem(Icons.store_outlined, 'Store', 15),
          _navItem(Icons.people_outline, 'Communauté', 16),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _statusRow('FastAPI', _serviceOnline('fastapi')),
                _statusRow(_providerLabels[_activeProvider] ?? _activeProvider, _health['online'] == true),
                _statusRow('Kokoro (voix)', _serviceOnline('kokoro')),
                const SizedBox(height: 10),
                if (FirebaseAuth.instance.currentUser?.email != null)
                  Text(
                    FirebaseAuth.instance.currentUser!.email!,
                    style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => AuthService.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.white38, size: 14),
                  label: Text('Déconnexion',
                      style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      color: surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('// SHINRA OS-AGENT v4',
              style: GoogleFonts.shareTechMono(
                  color: crimson, fontSize: 11, letterSpacing: 2)),
          const Spacer(),
          _pill('PLAN ${_credits['plan'] ?? 'OFFLINE'}', gold),
          const SizedBox(width: 8),
          _pill('${_credits['balance'] ?? 0} CREDITS', green),
          const SizedBox(width: 8),
          _pill('${_providerLabels[_activeProvider] ?? _activeProvider.toUpperCase()} AGENT', crimson),
          const SizedBox(width: 8),
          _pill(
            _userPlan == 'trial' ? 'ESSAI' : (_userPlan == 'free' ? 'FREE' : _userPlan.toUpperCase()),
            _userPlan == 'trial' ? gold : (_userPlan == 'free' ? Colors.white38 : green),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _voiceModeOn = !_voiceModeOn),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _voiceModeOn ? gold.withOpacity(0.15) : Colors.transparent,
                border: Border.all(color: _voiceModeOn ? gold : Colors.white24),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_voiceModeOn ? Icons.volume_up : Icons.volume_off,
                    color: _voiceModeOn ? gold : Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text('VOIX', style: GoogleFonts.shareTechMono(color: _voiceModeOn ? gold : Colors.white38, fontSize: 10)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Rafraichir',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh, color: crimson, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF080C15),
        border: Border(bottom: BorderSide(color: Color(0xFF142238))),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open, color: crimson, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: _singleLineField(
              controller: _projectCtrl,
              hint: 'Dossier projet actif',
              onSubmitted: (_) => _loadProjectContext(),
            ),
          ),
          const SizedBox(width: 8),
          _iconButton(
              Icons.sync, crimson, _loadProjectContext, 'Synchroniser contexte'),
          _iconButton(Icons.visibility_outlined, gold, _observeScreen,
              'Observer mon ecran'),
        ],
      ),
    );
  }

  Widget _buildAgentWorkspace() {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildChatPanel()),
        Container(width: 1, color: const Color(0xFF142238)),
        SizedBox(width: 360, child: _buildActionPanel()),
      ],
    );
  }

  Widget _buildChatPanel() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(14),
            itemCount: _messages.length,
            itemBuilder: (_, index) => TweenAnimationBuilder<double>(
              key: ValueKey('msg_$index'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 8),
                  child: child,
                ),
              ),
              child: _bubble(_messages[index]),
            ),
          ),
        ),
        if (_loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShinraLogo(size: 16, active: true, progress: 1.0),
                const SizedBox(width: 8),
                Text(_thinkingPhrase,
                    style: GoogleFonts.shareTechMono(
                        color: crimson.withOpacity(0.55), fontSize: 10)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          color: surface,
          child: Row(
            children: [
              _squareButton(
                _isListening ? Icons.mic : Icons.mic_none,
                _isListening ? gold : crimson,
                _toggleListening,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  style:
                      GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
                  onSubmitted: (_) => _send(),
                  decoration: _inputDecoration(
                    _isListening ? 'Je t\'écoute...' : 'Donne un ordre a Shinra...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _squareButton(Icons.send_rounded, crimson, _send),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel() {
    return Container(
      color: const Color(0xFF080B13),
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: [
          _sectionTitle('Dashboard'),
          _metricRow('Credits', '${_credits['balance'] ?? 0}', green),
          _metricRow(
              'Projet',
              _projectContext.isEmpty ? 'non synchronise' : 'contexte actif',
              crimson),
          _metricRow('Agent', _health['online'] == true ? 'online' : 'offline',
              _health['online'] == true ? green : red),
          const SizedBox(height: 18),
          _sectionTitle('Mode Projet'),
          _singleLineField(
              controller: _fileCtrl, hint: 'Chemin relatif: lib/main.dart'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _commandButton(
                      'Lire', Icons.file_open_outlined, _readFile)),
              const SizedBox(width: 8),
              Expanded(
                  child: _commandButton(
                      'Appliquer', Icons.save_outlined, _applyFile)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            minLines: 8,
            maxLines: 14,
            style: GoogleFonts.shareTechMono(
                color: Colors.white, fontSize: 11, height: 1.25),
            decoration: _inputDecoration('Contenu a injecter dans le fichier'),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Vision / RPA / Studio'),
          TextField(
            controller: _taskCtrl,
            minLines: 2,
            maxLines: 4,
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration('Tache RPA ou sujet Studio Flash'),
          ),
          const SizedBox(height: 8),
          _commandButton(
              'Observer mon ecran', Icons.visibility_outlined, _observeScreen),
          const SizedBox(height: 8),
          _commandButton(
              'Plan RPA apprentissage', Icons.touch_app_outlined, _makeRpaPlan),
          const SizedBox(height: 8),
          _commandButton(
              'Studio Flash', Icons.movie_creation_outlined, _studioFlash),
          const SizedBox(height: 18),
          _sectionTitle('Contexte'),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF050811),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _projectContext.isEmpty
                  ? 'Aucun contexte charge.'
                  : _projectContext.split('\n').take(28).join('\n'),
              style: GoogleFonts.shareTechMono(
                  color: Colors.white54, fontSize: 10, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, String> msg) {
    final user = msg['role'] == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.58),
        decoration: BoxDecoration(
          color: user ? const Color(0xFF0A1828) : surface2,
          border: Border.all(
              color: user ? crimson.withOpacity(0.45) : gold.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!user && (msg['agent'] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg['agent']!,
                  style: GoogleFonts.shareTechMono(color: gold.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            SelectableText(
              msg['content'] ?? '',
              style: GoogleFonts.rajdhani(
                  color: user ? crimson : ink, fontSize: 15, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentScreenIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0D1F2E) : Colors.transparent,
        border: active ? Border.all(color: crimson.withOpacity(0.3)) : Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: crimson.withOpacity(0.06),
          splashColor: crimson.withOpacity(0.15),
          onTap: () {
            setState(() => _currentScreenIndex = index);
            SettingsService.getActiveProvider()
                .then((p) { if (mounted) setState(() => _activeProvider = p); });
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: 22,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: active ? crimson : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListTile(
                  dense: true,
                  leading: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: active ? 1.08 : 1.0,
                    child: Icon(icon,
                        color: active ? crimson : const Color(0xFF3A6A7A), size: 18),
                  ),
                  title: Text(label,
                      style: GoogleFonts.rajdhani(
                          color: active ? crimson : const Color(0xFF3A6A7A),
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String label, bool on) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: on ? green : red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.shareTechMono(
                  color: on ? green : red, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: GoogleFonts.shareTechMono(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: GoogleFonts.shareTechMono(
              color: gold, fontSize: 12, letterSpacing: 1.5)),
    );
  }

  Widget _metricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.rajdhani(color: Colors.white60, fontSize: 14)),
          const Spacer(),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.shareTechMono(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _singleLineField({
    required TextEditingController controller,
    required String hint,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
      onSubmitted: onSubmitted,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: crimson.withOpacity(0.25), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF050811),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: crimson.withOpacity(0.18))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: crimson.withOpacity(0.18))),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: crimson)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  Widget _iconButton(
      IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
    );
  }

  Widget _squareButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _commandButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: crimson),
        label: Text(label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: crimson.withOpacity(0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: const Color(0xFF07111C),
        ),
      ),
    );
  }
}
