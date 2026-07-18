import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/agent_service.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface2 = Color(0xFF0D1225);

  final TextEditingController _descCtrl = TextEditingController();
  bool _generating = false;
  String? _html;
  String? _path;
  String? _status;

  Future<void> _generate() async {
    if (_descCtrl.text.trim().isEmpty) return;
    setState(() {
      _generating = true;
      _html = null;
      _status = null;
    });

    final result = await AgentService.generateWebsite(_descCtrl.text.trim());

    if (!mounted) return;
    setState(() {
      _generating = false;
      _status = result['result'];
      _html = (result['html'] ?? '').isNotEmpty ? result['html'] : null;
      _path = (result['path'] ?? '').isNotEmpty ? result['path'] : null;
    });
  }

  Future<void> _copyCode() async {
    if (_html == null) return;
    await Clipboard.setData(ClipboardData(text: _html!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié dans le presse-papiers.')));
  }

  Future<void> _openInBrowser() async {
    if (_path == null) return;
    final uri = Uri.file(_path!);
    if (!await launchUrl(uri)) {
      debugPrint('Impossible d\'ouvrir : $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GÉNÉRATION DE SITE WEB', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('// Landing page complète (HTML/CSS/JS), un seul fichier, générée par ton IA active',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 16),

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
                    controller: _descCtrl,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ex: landing page pour Shokugeki Menu, SaaS restaurant, style moderne...',
                      hintStyle: TextStyle(color: crimson.withOpacity(0.2), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _generating ? null : _generate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.2),
                      border: Border.all(color: gold),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('GÉNÉRER', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _generating
                  ? const Center(child: CircularProgressIndicator(color: crimson))
                  : _html != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text(_path ?? '', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10))),
                                TextButton.icon(
                                  onPressed: _copyCode,
                                  icon: const Icon(Icons.copy, size: 14, color: gold),
                                  label: Text('Copier', style: GoogleFonts.shareTechMono(color: gold, fontSize: 11)),
                                ),
                                TextButton.icon(
                                  onPressed: _openInBrowser,
                                  icon: const Icon(Icons.open_in_browser, size: 14, color: crimson),
                                  label: Text('Ouvrir', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 11)),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _html!,
                                  style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11, height: 1.5),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            _status ?? '// Décris le site que tu veux, Shinra s\'occupe du code',
                            style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
