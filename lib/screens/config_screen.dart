import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ProviderMeta {
  final String id;
  final String label;
  final String defaultModel;
  final String hint;
  final String getKeyUrl;

  const _ProviderMeta(this.id, this.label, this.defaultModel, this.hint, this.getKeyUrl);
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _outputDirCtrl = TextEditingController(text: "C:/shinra_project/output");

  final Map<String, TextEditingController> _keyCtrls = {};
  final Map<String, TextEditingController> _modelCtrls = {};
  final Map<String, bool> _obscured = {};
  final _runwayKeyCtrl = TextEditingController();
  final _stabilityKeyCtrl = TextEditingController();
  final _didKeyCtrl = TextEditingController();
  bool _runwayObscured = true;
  bool _stabilityObscured = true;
  bool _didObscured = true;

  String _activeProvider = 'gemini';
  String _voiceProfile = '⚡ Adam (Masculin)';
  bool _isSaving = false;
  bool _loading = true;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  static const _providers = [
    _ProviderMeta('gemini', 'Google Gemini', 'gemini-1.5-flash-latest',
        'Vision d\'écran + chat + génération d\'image (Imagen)', 'aistudio.google.com/apikey'),
    _ProviderMeta('openai', 'OpenAI (GPT / Codex)', 'gpt-4o-mini',
        'Chat + génération de code + génération d\'image (gpt-image-1)', 'platform.openai.com/api-keys'),
    _ProviderMeta('claude', 'Anthropic Claude', 'claude-sonnet-4-5',
        'Chat + édition/génération de code avancée', 'console.anthropic.com/settings/keys'),
    _ProviderMeta('mistral', 'Mistral AI', 'mistral-large-latest',
        'Chat + génération de code', 'console.mistral.ai/api-keys'),
  ];

  @override
  void initState() {
    super.initState();
    for (final p in _providers) {
      _keyCtrls[p.id] = TextEditingController();
      _modelCtrls[p.id] = TextEditingController();
      _obscured[p.id] = true;
    }
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final activeProvider = await SettingsService.getActiveProvider();
    for (final p in _providers) {
      final key = await SettingsService.getApiKey(p.id);
      final model = await SettingsService.getModel(p.id);
      _keyCtrls[p.id]!.text = key;
      _modelCtrls[p.id]!.text = model.isEmpty ? p.defaultModel : model;
    }
    _runwayKeyCtrl.text = await SettingsService.getRunwayKey();
    _stabilityKeyCtrl.text = await SettingsService.getStabilityKey();
    _didKeyCtrl.text = await SettingsService.getDidKey();
    final voiceProfile = await SettingsService.getVoiceProfile();
    if (!mounted) return;
    setState(() {
      _activeProvider = activeProvider;
      _voiceProfile = voiceProfile;
      _loading = false;
    });
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);

    await SettingsService.setActiveProvider(_activeProvider);
    for (final p in _providers) {
      await SettingsService.setApiKey(p.id, _keyCtrls[p.id]!.text);
      await SettingsService.setModel(p.id, _modelCtrls[p.id]!.text);
    }
    await SettingsService.setRunwayKey(_runwayKeyCtrl.text);
    await SettingsService.setStabilityKey(_stabilityKeyCtrl.text);
    await SettingsService.setDidKey(_didKeyCtrl.text);
    await SettingsService.setVoiceProfile(_voiceProfile);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: surface2,
        content: Text(
          '// CLÉS SAUVEGARDÉES LOCALEMENT (CHIFFRÉES SUR CET APPAREIL)',
          style: GoogleFonts.shareTechMono(color: green, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: crimson));
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PANNEAU DE CONFIGURATION IA',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 5),
          Text(
            '// Tes clés API restent sur ton appareil, chiffrées. Jamais envoyées ailleurs\n'
            '// qu\'au fournisseur d\'IA choisi, au moment de chaque requête.',
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle("FOURNISSEUR ACTIF POUR LE CHAT"),
                _buildProviderSelector(),

                const SizedBox(height: 25),
                _buildSectionTitle("CLÉS API PAR FOURNISSEUR"),
                ..._providers.map(_buildProviderKeyCard),

                const SizedBox(height: 25),
                _buildSectionTitle("VOIX DE SHINRA (MODE VOCAL)"),
                _buildVoiceSelector(),

                const SizedBox(height: 25),
                _buildSectionTitle("GÉNÉRATION VIDÉO (RUNWAY ML)"),
                _buildRunwayCard(),

                const SizedBox(height: 25),
                _buildSectionTitle("GÉNÉRATION MUSICALE (STABILITY AI)"),
                _buildStabilityCard(),

                const SizedBox(height: 25),
                _buildSectionTitle("AVATAR PARLANT (D-ID)"),
                _buildDidCard(),

                const SizedBox(height: 25),
                _buildSectionTitle("STOCKAGE LOCAL"),
                _buildInputField("DOSSIER DE SORTIE DES RENDUS (IMAGES/MP4)", _outputDirCtrl, Icons.folder_special_outlined),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfiguration,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, color: Colors.white),
              label: Text(
                _isSaving ? 'SAUVEGARDE...' : 'SAUVEGARDER LA CONFIGURATION',
                style: GoogleFonts.shareTechMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _providers.map((p) {
          final active = _activeProvider == p.id;
          return RadioListTile<String>(
            value: p.id,
            groupValue: _activeProvider,
            activeColor: crimson,
            dense: true,
            onChanged: (v) => setState(() => _activeProvider = v!),
            title: Text(p.label,
                style: GoogleFonts.rajdhani(
                    color: active ? crimson : Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(p.hint, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProviderKeyCard(_ProviderMeta p) {
    final hasKey = _keyCtrls[p.id]!.text.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasKey ? green.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasKey ? Icons.check_circle : Icons.circle_outlined,
                  color: hasKey ? green : Colors.white24, size: 16),
              const SizedBox(width: 8),
              Text(p.label,
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(p.getKeyUrl, style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.hint, style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _keyCtrls[p.id],
                  obscureText: _obscured[p.id]!,
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Colle ta clé API ${p.label} ici',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF050811),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscured[p.id]! ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38, size: 16),
                      onPressed: () => setState(() => _obscured[p.id] = !_obscured[p.id]!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _modelCtrls[p.id],
                  style: GoogleFonts.shareTechMono(color: crimson, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Modèle',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF050811),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector() {
    const voices = ['🔔 Bella (Féminin)', '⚡ Adam (Masculin)', '🔥 Kenji (Anime)', '🔮 Yuki (Doux)'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: voices.map((v) {
        final selected = _voiceProfile == v;
        return GestureDetector(
          onTap: () => setState(() => _voiceProfile = v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? gold.withOpacity(0.15) : surface2,
              border: Border.all(color: selected ? gold : Colors.white10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(v, style: GoogleFonts.rajdhani(color: selected ? gold : Colors.white70, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRunwayCard() {
    final hasKey = _runwayKeyCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasKey ? green.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasKey ? Icons.check_circle : Icons.circle_outlined,
                  color: hasKey ? green : Colors.white24, size: 16),
              const SizedBox(width: 8),
              Text('Runway ML', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('runwayml.com/api', style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Clé séparée dédiée à la génération vidéo (indépendante du chat).',
              style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _runwayKeyCtrl,
            obscureText: _runwayObscured,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Colle ta clé API Runway ici',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF050811),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              suffixIcon: IconButton(
                icon: Icon(_runwayObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 16),
                onPressed: () => setState(() => _runwayObscured = !_runwayObscured),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityCard() {
    final hasKey = _stabilityKeyCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasKey ? green.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasKey ? Icons.check_circle : Icons.circle_outlined,
                  color: hasKey ? green : Colors.white24, size: 16),
              const SizedBox(width: 8),
              Text('Stability AI', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('platform.stability.ai', style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Clé séparée dédiée à la génération musicale (Stable Audio).',
              style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _stabilityKeyCtrl,
            obscureText: _stabilityObscured,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Colle ta clé API Stability ici',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF050811),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              suffixIcon: IconButton(
                icon: Icon(_stabilityObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 16),
                onPressed: () => setState(() => _stabilityObscured = !_stabilityObscured),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDidCard() {
    final hasKey = _didKeyCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasKey ? green.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasKey ? Icons.check_circle : Icons.circle_outlined,
                  color: hasKey ? green : Colors.white24, size: 16),
              const SizedBox(width: 8),
              Text('D-ID', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('studio.d-id.com', style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Clé séparée dédiée à l\'avatar parlant (image + texte → vidéo avec synchronisation labiale).',
              style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _didKeyCtrl,
            obscureText: _didObscured,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Colle ta clé API D-ID ici',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF050811),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              suffixIcon: IconButton(
                icon: Icon(_didObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 16),
                onPressed: () => setState(() => _didObscured = !_didObscured),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.shareTechMono(color: gold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.shareTechMono(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, color: crimson.withOpacity(0.5), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
