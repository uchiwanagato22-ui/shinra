import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';

// ═══════════════════════════════════════════════════════
//  STORE — partage de templates (idées d'apps/missions en texte)
//  Volontairement PAS de plugins exécutables : un marketplace de code
//  tournant sur la machine d'un inconnu est un risque de sécurité, pas
//  une fonctionnalité. Voir le commentaire dans firestore_service.dart.
// ═══════════════════════════════════════════════════════

class StoreScreen extends StatefulWidget {
  final void Function(String prefill) onUseTemplate;
  const StoreScreen({super.key, required this.onUseTemplate});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface2 = Color(0xFF0D1225);

  Future<void> _publish() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final promptCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('PUBLIER UN TEMPLATE', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'Titre (ex: App de suivi de dépenses)'),
              const SizedBox(height: 10),
              _field(descCtrl, 'Description courte'),
              const SizedBox(height: 10),
              TextField(
                controller: promptCtrl,
                maxLines: 4,
                style: GoogleFonts.rajdhani(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Instruction complète à envoyer à Shinra (le vrai template)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: crimson),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || promptCtrl.text.trim().isEmpty) return;
              await FirestoreService.publishTemplate(
                titleCtrl.text.trim(),
                descCtrl.text.trim(),
                promptCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('PUBLIER', style: TextStyle(color: Colors.white)),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SHINRA STORE', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
              TextButton.icon(
                onPressed: _publish,
                icon: Icon(Icons.add, color: crimson, size: 18),
                label: Text('Publier', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('// Templates de missions partagés par la communauté (texte uniquement, jamais de code exécutable)',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.templatesStream(),
              builder: (context, snapshot) {
                final templates = snapshot.data ?? [];
                if (templates.isEmpty) {
                  return Center(
                    child: Text('Aucun template publié pour le moment. Sois le premier !',
                        style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 14)),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 2.2,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, i) => _templateCard(templates[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t['title'] ?? '', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(t['description'] ?? '',
                style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('par ${t['authorName'] ?? 'Anonyme'} · ${t['uses'] ?? 0} utilisations',
                  style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9)),
              TextButton(
                onPressed: () {
                  FirestoreService.incrementTemplateUses(t['id']);
                  widget.onUseTemplate(t['promptText'] ?? '');
                },
                child: Text('UTILISER', style: GoogleFonts.shareTechMono(color: gold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
