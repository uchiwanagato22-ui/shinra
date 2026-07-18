import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final TextEditingController _promptCtrl = TextEditingController();
  bool _generating = false;
  int _duration = 5;
  String? _statusResult;
  String? _generatedVideoPath;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface2 = Color(0xFF0D1225);

  Future<void> _startGeneration() async {
    if (_promptCtrl.text.trim().isEmpty) return;

    setState(() {
      _generating = true;
      _statusResult = null;
      _generatedVideoPath = null;
    });

    final result = await AgentService.generateVideo(
      _promptCtrl.text.trim(),
      durationSeconds: _duration,
    );

    if (!mounted) return;
    setState(() {
      _generating = false;
      _statusResult = result['result'];
      final path = result['path'];
      if (path != null && path.isNotEmpty) {
        _generatedVideoPath = path;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GÉNÉRATION VIDÉO (RUNWAY ML)',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 5),
          Text(
            '// Vraie génération text-to-video. Peut prendre 1 à 5 minutes.',
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Text('DURÉE : ', style: GoogleFonts.shareTechMono(color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 10),
              ...[5, 10].map((d) => Padding(
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
                          Text('Génération vidéo en cours (jusqu\'à 5 min)...',
                              style: GoogleFonts.shareTechMono(color: crimson, fontSize: 13)),
                        ],
                      ),
                    )
                  : _generatedVideoPath != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.movie_creation_outlined, color: crimson, size: 48),
                              const SizedBox(height: 12),
                              Text('Vidéo prête !', style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(_generatedVideoPath!,
                                  style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : Center(
                          child: Text(
                            _statusResult ?? '// Décris la scène à générer et clique sur Générer',
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
              border: Border.all(color: crimson.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Décris la scène vidéo à générer...',
                      hintStyle: TextStyle(color: crimson.withOpacity(0.2), fontSize: 14),
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
                      color: gold.withOpacity(0.2),
                      border: Border.all(color: gold),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GÉNÉRER',
                      style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
