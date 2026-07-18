import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _cmdCtrl = TextEditingController();
  final ScrollController _terminalScroll = ScrollController();
  final List<String> _terminalLogs = [
    "// SHINRA.IA SYSTEM TERMINAL v3.0",
    "// Initialisation des sous-processus Python...",
    "// Prêt à exécuter vos commandes système."
  ];
  bool _executing = false;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface = Color(0xFF0B0E18);

  Future<void> _executeCommand() async {
    final command = _cmdCtrl.text.trim();
    if (command.isEmpty) return;

    _cmdCtrl.clear();
    setState(() {
      _terminalLogs.add("\nsh@shinra:~# $command");
      _executing = true;
    });
    _scrollToBottom();

    // Appel direct de la fonction run_code de ton tools.py !
    final output = await AgentService.runCode(command);

    setState(() {
      _terminalLogs.add(output);
      _executing = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_terminalScroll.hasClients) {
        _terminalScroll.animateTo(
          _terminalScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
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
            'TERMINAL SUBSYSTÈME',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 15),

          // Zone d'affichage des logs du terminal
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                border: Border.all(color: gold.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _terminalScroll,
                itemCount: _terminalLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      _terminalLogs[index],
                      style: GoogleFonts.shareTechMono(
                        color: _terminalLogs[index].startsWith("sh@shinra") 
                            ? crimson 
                            : const Color(0xFFC0D0E8),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (_executing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(color: gold, strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Exécution du sous-processus en cours...',
                    style: GoogleFonts.shareTechMono(color: gold, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Barre d'entrée des commandes
          Container(
            color: surface,
            child: Row(
              children: [
                Text(
                  ' shinra_core> ',
                  style: GoogleFonts.shareTechMono(color: gold, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _cmdCtrl,
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _executeCommand(),
                    decoration: InputDecoration(
                      hintText: 'Entrez une commande (ex: dir, ipconfig, echo...)',
                      hintStyle: TextStyle(color: crimson.withOpacity(0.2), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: crimson),
                  onPressed: _executeCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}