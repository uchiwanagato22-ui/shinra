import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';

// ═══════════════════════════════════════════════════════
//  AUTOMATISATION — "Si nouveau fichier -> résumer -> Discord -> archiver"
//  V1 scopée à un seul type de workflow concret (celui du plan de Nagato),
//  pas un moteur générique. Tourne en tâche de fond côté backend local tant
//  que le serveur est lancé.
// ═══════════════════════════════════════════════════════

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  List<Map<String, dynamic>> _workflows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final workflows = await AgentService.listWorkflows();
    if (!mounted) return;
    setState(() {
      _workflows = workflows;
      _loading = false;
    });
  }

  Future<void> _createWorkflow() async {
    final nameCtrl = TextEditingController();
    final folderCtrl = TextEditingController(text: 'C:/Users/Nagato/Downloads');
    final patternCtrl = TextEditingController(text: '*.pdf');
    final discordCtrl = TextEditingController();
    final archiveCtrl = TextEditingController(text: 'C:/Users/Nagato/Downloads/archive');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVELLE AUTOMATISATION', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Nom (ex: Résumé factures)'),
              const SizedBox(height: 10),
              _field(folderCtrl, 'Dossier à surveiller'),
              const SizedBox(height: 10),
              _field(patternCtrl, 'Motif de fichier (ex: *.pdf)'),
              const SizedBox(height: 10),
              _field(discordCtrl, 'Webhook Discord (optionnel)'),
              const SizedBox(height: 10),
              _field(archiveCtrl, 'Dossier d\'archive'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: crimson),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || folderCtrl.text.trim().isEmpty) return;
              await AgentService.createWorkflow(
                name: nameCtrl.text.trim(),
                watchFolder: folderCtrl.text.trim(),
                filePattern: patternCtrl.text.trim(),
                discordWebhook: discordCtrl.text.trim(),
                archiveFolder: archiveCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('CRÉER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        style: GoogleFonts.rajdhani(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: const OutlineInputBorder(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: crimson));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AUTOMATISATION', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
              TextButton.icon(
                onPressed: _createWorkflow,
                icon: Icon(Icons.add, color: crimson, size: 18),
                label: Text('Nouvelle règle', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('// "Si nouveau fichier détecté -> résumer avec l\'IA -> notifier Discord -> archiver"',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 20),
          Expanded(
            child: _workflows.isEmpty
                ? Center(
                    child: Text('Aucune automatisation active pour le moment.',
                        style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 14)),
                  )
                : ListView(children: _workflows.map(_workflowCard).toList()),
          ),
        ],
      ),
    );
  }

  Widget _workflowCard(Map<String, dynamic> w) {
    final active = w['active'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (active ? green : Colors.white24).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(active ? Icons.bolt : Icons.pause_circle_outline, color: active ? green : Colors.white38, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(w['name'] ?? '', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
              Switch(
                value: active,
                activeColor: green,
                onChanged: (v) async {
                  await AgentService.toggleWorkflow(w['id'], v);
                  _refresh();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                onPressed: () async {
                  await AgentService.deleteWorkflow(w['id']);
                  _refresh();
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '${w['watch_folder']} (${w['file_pattern']}) → ${(w['discord_webhook'] ?? '').toString().isNotEmpty ? 'Discord' : 'pas de notif'} → ${w['archive_folder']}',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
