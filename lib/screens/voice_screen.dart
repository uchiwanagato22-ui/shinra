import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';
import '../services/voice_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _generatingAudio = false;
  String _selectedVoice = '🔔 Bella (Féminin)';
  String? _serverResult;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  Future<void> _generateVoice() async {
    if (_textCtrl.text.trim().isEmpty) return;

    setState(() {
      _generatingAudio = true;
      _serverResult = null;
    });

    // Envoi du texte et du profil vocal vers l'API Python
    final result = await AgentService.generateVoice(
      _textCtrl.text.trim(),
      _selectedVoice,
    );

    setState(() {
      _generatingAudio = false;
      _serverResult = result;
    });

    if (!result.contains('❌')) {
      await VoiceService.playFile('C:/shinra_project/output/voice_01.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LABO AUDIO TTS (KOKORO-82M)',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Text('VOIX DE RÉFÉRENCE : ', style: GoogleFonts.shareTechMono(color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _selectedVoice,
                  dropdownColor: surface,
                  underline: const SizedBox(),
                  style: GoogleFonts.shareTechMono(color: crimson, fontSize: 13),
                  items: <String>[
                    '🔔 Bella (Féminin)',
                    '⚡ Adam (Masculin)',
                    '🔥 Kenji (Anime)',
                    '🔮 Yuki (Doux)'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedVoice = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _generatingAudio
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: crimson),
                          const SizedBox(height: 16),
                          Text('Synthèse vocale neuronale sur Python...', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 12)),
                        ],
                      ),
                    )
                  : _serverResult != null
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface2,
                              border: Border.all(color: crimson.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.audiotrack_rounded, color: crimson, size: 24),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    _serverResult!,
                                    style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.replay, color: crimson, size: 20),
                                  onPressed: () => VoiceService.playFile('C:/shinra_project/output/voice_01.wav'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.waves_rounded, size: 48, color: gold.withOpacity(0.15)),
                              const SizedBox(height: 10),
                              Text(
                                '// Entre un texte pour déclencher le pipeline audio',
                                style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(10),
            color: surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Écris la réplique à générer en audio...',
                      hintStyle: TextStyle(color: crimson.withOpacity(0.2), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _generatingAudio ? null : _generateVoice,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: crimson.withOpacity(0.15),
                      border: Border.all(color: crimson),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VOCALISER',
                      style: GoogleFonts.shareTechMono(color: crimson, fontSize: 13, fontWeight: FontWeight.bold),
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
}