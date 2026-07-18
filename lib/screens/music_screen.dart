import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';
import '../services/voice_service.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _promptCtrl = TextEditingController();
  bool _generating = false;
  int _duration = 30;
  String? _statusResult;
  String? _generatedMusicPath;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface2 = Color(0xFF0D1225);

  Future<void> _startGeneration() async {
    if (_promptCtrl.text.trim().isEmpty) return;

    setState(() {
      _generating = true;
      _statusResult = null;
      _generatedMusicPath = null;
    });

    final result = await AgentService.generateMusic(
      _promptCtrl.text.trim(),
      durationSeconds: _duration,
    );

    if (!mounted) return;
    setState(() {
      _generating = false;
      _statusResult = result['result'];
      final path = result['path'];
      if (path != null && path.isNotEmpty) {
        _generatedMusicPath = path;
      }
    });

    if (_generatedMusicPath != null) {
      await VoiceService.playFile(_generatedMusicPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GÉNÉRATION MUSICALE', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
          const SizedBox(height: 5),
          Text('// Stability AI (Stable Audio) — génération réelle, lecture automatique',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 15),

          Row(
            children: [
              Text('DURÉE : ', style: GoogleFonts.shareTechMono(color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 10),
              ...[15, 30, 60].map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${d}s', style: GoogleFonts.shareTechMono(fontSize: 12)),
                      selected: _duration == d,
                      selectedColor: gold.withOpacity(0.4),
                      backgroundColor: surface2,
                      labelStyle: TextStyle(color: _duration == d ? Colors.white : Colors.white54),
                      onSelected: (_) => setState(() => _duration = d),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 15),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                border: Border.all(color: gold.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _generating
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: crimson),
                          const SizedBox(height: 16),
                          Text('Composition en cours...', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 13)),
                        ],
                      ),
                    )
                  : _generatedMusicPath != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_note, color: gold, size: 48),
                              const SizedBox(height: 12),
                              Text('Musique prête (lecture en cours) !', style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(_generatedMusicPath!,
                                  style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 14),
                              IconButton(
                                icon: const Icon(Icons.replay, color: crimson, size: 28),
                                onPressed: () => VoiceService.playFile(_generatedMusicPath!),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Text(
                            _statusResult ?? '// Décris l\'ambiance musicale à générer',
                            style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gold.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ex: musique lo-fi calme pour session de code nocturne...',
                      hintStyle: TextStyle(color: gold.withOpacity(0.3), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _startGeneration(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _generating ? null : _startGeneration,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: crimson.withOpacity(0.2),
                      border: Border.all(color: crimson),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('GÉNÉRER',
                        style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
