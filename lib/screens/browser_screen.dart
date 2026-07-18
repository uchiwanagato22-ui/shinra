import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _urlCtrl = TextEditingController(text: "https://www.google.com");
  bool _browsing = false;
  String _browserStatus = "Navigateur Playwright actif // Prêt à exécuter";
  String? _screenshotPath;
  String _searchResults = "";

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  Future<void> _launchBrowserAction(String actionType) async {
    final target = _urlCtrl.text.trim();
    if (target.isEmpty) return;

    setState(() {
      _browsing = true;
      _browserStatus = "Playwright lance une instance Chromium (headless=True)...";
      _searchResults = "";
      _screenshotPath = null;
    });

    if (actionType == 'search') {
      // Exécution d'une vraie recherche Google via ton script browser_tools.py !
      final result = await AgentService.webSearch(target);
      setState(() {
        _browsing = false;
        _searchResults = result;
        _browserStatus = "Recherche effectuée avec succès via Chromium.";
      });
    } else {
      // Exécution d'une vraie capture d'écran de l'URL cible
      const defaultPath = "C:/shinra_project/output/screenshot.png";
      final result = await AgentService.webScreenshot(target, savePath: defaultPath);
      setState(() {
        _browsing = false;
        _browserStatus = result;
        if (!result.contains('❌') && !result.toLowerCase().contains('erreur')) {
          _screenshotPath = defaultPath;
        }
      });
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
            'NAVIGATEUR AUTOMATISÉ (PLAYWRIGHT)',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 15),

          // Barre d'adresse URL / Recherche
          Container(
            padding: const EdgeInsets.all(8),
            color: surface,
            child: Row(
              children: [
                const Icon(Icons.language, color: gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _launchBrowserAction('open'),
                    decoration: InputDecoration(
                      hintText: 'Entre une URL (ex: github.com) ou une recherche Google...',
                      hintStyle: TextStyle(color: crimson.withOpacity(0.2), fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: "Rechercher sur Google",
                  icon: const Icon(Icons.search, color: crimson),
                  onPressed: _browsing ? null : () => _launchBrowserAction('search'),
                ),
                IconButton(
                  tooltip: "Faire une capture de la page",
                  icon: const Icon(Icons.open_in_browser, color: gold),
                  onPressed: _browsing ? null : () => _launchBrowserAction('open'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Statut de la session Playwright
          Text(
            '// STATUS: $_browserStatus',
            style: GoogleFonts.shareTechMono(color: _browsing ? gold : Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 15),

          // Zone d'affichage des résultats ou de la capture
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _browsing
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: gold),
                          const SizedBox(height: 16),
                          Text('Pilotage de Chromium headless en arrière-plan...', style: GoogleFonts.shareTechMono(color: gold, fontSize: 12)),
                        ],
                      ),
                    )
                  : _searchResults.isNotEmpty
                      ? SingleChildScrollView(
                          child: SelectableText(
                            _searchResults,
                            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 14, height: 1.5),
                          ),
                        )
                      : _screenshotPath != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, color: crimson, size: 48),
                                const SizedBox(height: 15),
                                Text(
                                  '📸 CAPTURE D\'ÉCRAN ENREGISTRÉE AVEC SUCCÈS',
                                  style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _screenshotPath!,
                                  style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 48, color: crimson.withOpacity(0.1)),
                                  const SizedBox(height: 10),
                                  Text(
                                    '// Aucune session web active ou capture disponible',
                                    style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}