import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';

// ═══════════════════════════════════════════════════════
//  SHINRA STUDIO — centre de création unifié
//  V1 : redirige vers les bons outils (Image/Vidéo/Voix/Chat) au lieu de
//  dupliquer la logique. "Site web", "Anime", "Jeu" sont en préparation :
//  je ne fais jamais semblant qu'une fonctionnalité existe déjà.
// ═══════════════════════════════════════════════════════

class StudioScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  final void Function(String prefill) onPrefillChat;

  const StudioScreen({
    super.key,
    required this.onNavigate,
    required this.onPrefillChat,
  });

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _PluginChip extends StatelessWidget {
  final String label;
  const _PluginChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1225),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
      ),
      child: Text(label, style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12)),
    );
  }
}

class _StudioScreenState extends State<StudioScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  Future<void> _startNewApp() async {
    final ctrl = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVELLE APPLICATION', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          style: GoogleFonts.rajdhani(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ex: une app Flutter de suivi de dépenses avec Firebase',
            hintStyle: const TextStyle(color: Colors.white24),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('LANCER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (description == null || description.isEmpty) return;

    await FirestoreService.createMission('Créer app : $description', project: '');

    widget.onPrefillChat(
      'Crée-moi une nouvelle application : $description\n\n'
      'Commence par me proposer une architecture de fichiers, puis crée-la '
      'étape par étape avec <action>write_file</action>. Mets à jour la mission liée au fur et à mesure.',
    );
  }

  // NOTE : contrairement à "Nouvelle App", le Site Web passe par un écran
  // dédié (génération instantanée d'une seule page HTML) plutôt que par le
  // chat + confirmation à chaque fichier — inutile ici puisqu'il n'y a
  // qu'un seul fichier autonome à produire. Voir WebsiteScreen.

  Future<void> _startAnime() async {
    final ctrl = TextEditingController();
    final folderCtrl = TextEditingController(text: 'C:/shinra_project/output/anime_project');
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVELLE COURTE ANIMATION', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: gold.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(
                '⚠️ Résultat réel : un diaporama narré (images + voix + musique), pas une animation avec mouvement des personnages.',
                style: GoogleFonts.rajdhani(color: gold, fontSize: 12),
              ),
            ),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: courte histoire d\'un ninja solitaire qui retrouve son clan',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: folderCtrl,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Dossier de destination',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: crimson),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('LANCER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (description == null || description.isEmpty) return;
    final folder = folderCtrl.text.trim().isEmpty ? 'C:/shinra_project/output/anime_project' : folderCtrl.text.trim();

    await FirestoreService.createMission('Créer animation : $description', project: '');

    widget.onPrefillChat(
      'Crée-moi une courte animation façon anime : $description\n\n'
      'Procède étape par étape, en mettant à jour la mission liée à chaque étape :\n'
      '1. Écris un court scénario (5-8 scènes) avec <action>write_file</action> dans "$folder/scenario.txt".\n'
      '2. Pour chaque scène, génère une image avec <action>generate_image</action> (style anime), sauvegardée dans "$folder/scene_N.png".\n'
      '3. Génère une narration vocale du scénario avec <action>generate_voice</action> (si disponible) ou signale-le si l\'action n\'existe pas encore côté chat.\n'
      '4. Génère une musique d\'ambiance adaptée avec <action>generate_music</action> si une clé Stability est configurée.\n'
      '5. Assemble le tout en vidéo avec <action>assemble_video|$folder/animation_finale.mp4|scene_1.png,scene_2.png,...|chemin_audio</action>.\n'
      '6. Termine par <action>open_app|chrome|$folder/animation_finale.mp4</action> pour que je la voie.\n'
      'Annonce clairement chaque étape terminée avant de passer à la suivante.',
    );
  }

  Future<void> _startGame() async {
    final ctrl = TextEditingController();
    final folderCtrl = TextEditingController(text: 'C:/shinra_project/output/mini_jeu');
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVEAU MINI-JEU', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: gold.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(
                '⚠️ Résultat réel : un mini-jeu HTML5/Canvas jouable dans le navigateur (type Pong/Flappy/Plateforme simple), pas un jeu Unity/Unreal complet.',
                style: GoogleFonts.rajdhani(color: gold, fontSize: 12),
              ),
            ),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: un jeu où un ninja saute par-dessus des obstacles',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: folderCtrl,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Dossier de destination',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: crimson),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('LANCER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (description == null || description.isEmpty) return;
    final folder = folderCtrl.text.trim().isEmpty ? 'C:/shinra_project/output/mini_jeu' : folderCtrl.text.trim();

    await FirestoreService.createMission('Créer mini-jeu : $description', project: '');

    widget.onPrefillChat(
      'Crée-moi un mini-jeu jouable dans le navigateur : $description\n\n'
      'Procède étape par étape, en mettant à jour la mission liée à chaque étape :\n'
      '1. Rédige un mini game-design (mécanique, contrôles, condition de victoire/défaite) dans "$folder/game_design.txt" avec <action>write_file</action>.\n'
      '2. Génère 1 ou 2 images de sprite/décor avec <action>generate_image</action> si utile.\n'
      '3. Écris un "$folder/index.html" autonome (HTML/CSS/JS Canvas intégrés, aucune dépendance externe) avec <action>write_file</action> qui implémente le jeu, en intégrant les images générées si possible.\n'
      '4. Ouvre-le dans le navigateur avec <action>open_app|chrome|$folder/index.html</action> pour que je teste.\n'
      'Annonce clairement chaque étape terminée avant de passer à la suivante.',
    );
  }

  Future<void> _startLogo() async {
    final ctrl = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVEAU LOGO', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          autofocus: true,
          style: GoogleFonts.rajdhani(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ex: Shinra IA, minimaliste, crimson et gold, style tech',
            hintStyle: const TextStyle(color: Colors.white24),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('CRÉER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (description == null || description.isEmpty) return;
    // On redirige vers l'écran Image existant (pas de duplication de logique).
    widget.onNavigate(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHINRA STUDIO', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('// Le centre de création — choisis ce que tu veux faire naître aujourd\'hui',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _studioCard('💻', 'Nouvelle App', 'Flutter, web, script...', green, _startNewApp),
                _studioCard('🎨', 'Image', 'OpenAI / Gemini', crimson, () => widget.onNavigate(1)),
                _studioCard('🎬', 'Vidéo', 'Runway ML', gold, () => widget.onNavigate(2)),
                _studioCard('🎙️', 'Voix', 'Synthèse vocale', crimson, () => widget.onNavigate(3)),
                _studioCard('🖼️', 'Logo', 'Identité visuelle', gold, _startLogo),
                _studioCard('🌐', 'Site Web', 'Landing page instantanée', gold, () => widget.onNavigate(12)),
                _studioCard('🎵', 'Musique', 'Stability AI', gold, () => widget.onNavigate(14)),
                _studioCard('🎞️', 'Anime', 'Diaporama narré + voix + musique', crimson, _startAnime),
                _studioCard('🎮', 'Jeu vidéo', 'Mini-jeu HTML5 jouable', gold, _startGame),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('PLUGINS DISPONIBLES POUR L\'AGENT', style: GoogleFonts.shareTechMono(color: gold, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _PluginChip('🎨 Blender'),
              _PluginChip('💻 VS Code'),
              _PluginChip('🐳 Docker'),
              _PluginChip('🎥 OBS Studio'),
              _PluginChip('🎮 Unity'),
            ],
          ),
          const SizedBox(height: 6),
          Text('// Demande-le simplement dans le chat, ex: "ouvre mon projet Blender" ou "liste mes conteneurs Docker"',
              style: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _studioCard(String emoji, String title, String subtitle, Color color, VoidCallback? onTap) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const Spacer(),
              Text(title, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
