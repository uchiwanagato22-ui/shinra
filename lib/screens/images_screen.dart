import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';
import '../services/settings_service.dart';

class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  final TextEditingController _promptCtrl = TextEditingController();

  bool _generating = false;
  String _provider = 'openai';
  String? _statusResult;
  String? _generatedImagePath;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface2 = Color(0xFF0D1225);

  static const _imageProviders = {
    'openai': 'OpenAI (gpt-image-1)',
    'gemini': 'Google Gemini (Imagen 3)',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferredProvider();
  }

  Future<void> _loadPreferredProvider() async {
    // On propose par défaut le provider de chat actif s'il supporte l'image.
    final active = await SettingsService.getActiveProvider();
    if (!mounted) return;
    if (_imageProviders.containsKey(active)) {
      setState(() => _provider = active);
    }
  }

  Future<void> _generateImage() async {
    if (_promptCtrl.text.trim().isEmpty) return;

    setState(() {
      _generating = true;
      _statusResult = null;
      _generatedImagePath = null;
    });

    final result = await AgentService.generateImage(_promptCtrl.text.trim(), _provider);

    if (!mounted) return;
    setState(() {
      _generating = false;
      _statusResult = result['result'];
      final path = result['path'];
      if (path != null && path.isNotEmpty) {
        _generatedImagePath = path;
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
            'GÉNÉRATION D\'IMAGE',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 5),
          Text(
            '// Vraie génération via l\'API du fournisseur choisi (clé configurée dans Config)',
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Text('FOURNISSEUR : ', style: GoogleFonts.shareTechMono(color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _provider,
                  dropdownColor: const Color(0xFF0B0E18),
                  underline: const SizedBox(),
                  style: GoogleFonts.shareTechMono(color: crimson, fontSize: 13),
                  items: _imageProviders.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _provider = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _generating
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: gold),
                          const SizedBox(height: 20),
                          Text('Génération en cours...', style: GoogleFonts.shareTechMono(color: gold, fontSize: 12)),
                        ],
                      ),
                    )
                  : _generatedImagePath != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Center(child: Image.file(File(_generatedImagePath!), fit: BoxFit.contain)),
                            ),
                            Positioned(
                              bottom: 10, left: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: Colors.black87,
                                child: Text(
                                  _statusResult ?? '',
                                  style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.brush_outlined, size: 48, color: crimson.withOpacity(0.1)),
                              const SizedBox(height: 10),
                              Text(
                                _statusResult ?? '// Aucune image générée pour le moment',
                                style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
                      hintText: 'Décris l\'image à générer...',
                      hintStyle: TextStyle(color: crimson.withOpacity(0.2), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _generateImage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _generating ? null : _generateImage,
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
