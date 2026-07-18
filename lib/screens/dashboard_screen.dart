import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> health;
  final Map<String, dynamic> credits;
  final String activeProvider;

  const DashboardScreen({
    super.key,
    required this.health,
    required this.credits,
    required this.activeProvider,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const orange = Color(0xFFFFA500);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return green;
      case 'pending':
        return Colors.white38;
      default:
        return orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.autorenew;
    }
  }

  Future<void> _showCreateMissionDialog() async {
    final titleCtrl = TextEditingController();
    final projectCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVELLE MISSION', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: Corriger les bugs Shokugeki Menu',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: projectCtrl,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Projet lié (optionnel)',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await FirestoreService.createMission(titleCtrl.text.trim(), project: projectCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('CRÉER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    final nameCtrl = TextEditingController();
    final pathCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('NOUVEAU PROJET', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nom du projet',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pathCtrl,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Chemin du dossier',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await FirestoreService.createProject(nameCtrl.text.trim(), path: pathCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('CRÉER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.missionsStream(),
      builder: (context, missionsSnap) {
        final missions = missionsSnap.data ?? [];
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.projectsStream(),
          builder: (context, projectsSnap) {
            final projects = projectsSnap.data ?? [];
            final activeMissions = missions.where((m) => m['status'] != 'done').length;
            final doneMissions = missions.where((m) => m['status'] == 'done').length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  Text('DASHBOARD', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
                  const SizedBox(width: 10),
                  Icon(Icons.cloud_done_outlined, color: green.withOpacity(0.6), size: 16),
                ]),
                const SizedBox(height: 4),
                Text('// Synchronisé en temps réel via Firestore',
                    style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _statCard('CRÉDITS', '${widget.credits['balance'] ?? 0}', Icons.bolt, crimson),
                    const SizedBox(width: 12),
                    _statCard('MISSIONS ACTIVES', '$activeMissions', Icons.rocket_launch_outlined, orange),
                    const SizedBox(width: 12),
                    _statCard('TERMINÉES', '$doneMissions', Icons.check_circle_outline, green),
                    const SizedBox(width: 12),
                    _statCard('PROJETS', '${projects.length}', Icons.folder_outlined, gold),
                  ],
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('MISSION CONTROL'),
                    TextButton.icon(
                      onPressed: _showCreateMissionDialog,
                      icon: Icon(Icons.add, color: crimson, size: 18),
                      label: Text('Nouvelle mission', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (missions.isEmpty)
                  _emptyState('Aucune mission en cours. Crée-en une pour commencer à suivre ton travail.')
                else
                  ...missions.map(_missionCard),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('PROJETS'),
                    TextButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: Icon(Icons.add, color: gold, size: 18),
                      label: Text('Nouveau projet', style: GoogleFonts.shareTechMono(color: gold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (projects.isEmpty)
                  _emptyState('Aucun projet enregistré. Ajoute Shokugeki Menu ou Shinra IA pour commencer.')
                else
                  ...projects.map(_projectCard),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Row(children: [
        Container(width: 3, height: 16, color: gold, margin: const EdgeInsets.only(right: 10)),
        Text(title, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ]);

  Widget _emptyState(String text) => Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
        child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 13)),
      );

  Widget _missionCard(Map<String, dynamic> m) {
    final progress = (m['progress'] ?? 0) as int;
    final status = (m['status'] ?? 'active') as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor(status).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: _statusColor(status), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(m['title'] ?? '', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text('$progress%', style: GoogleFonts.shareTechMono(color: _statusColor(status), fontSize: 12)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                color: surface2,
                onSelected: (v) async {
                  if (v == 'done') {
                    await FirestoreService.updateMission(m['id'], progress: 100, status: 'done');
                  } else if (v == 'delete') {
                    await FirestoreService.deleteMission(m['id']);
                  } else if (v == 'progress') {
                    final newProgress = (progress + 25).clamp(0, 100);
                    await FirestoreService.updateMission(m['id'], progress: newProgress);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'progress', child: Text('+25% progression')),
                  const PopupMenuItem(value: 'done', child: Text('Marquer terminée')),
                  const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          if ((m['project'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 24),
              child: Text(m['project'], style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10)),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress / 100),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation(_statusColor(status)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, color: gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? '', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                if ((p['path'] ?? '').toString().isNotEmpty)
                  Text(p['path'], style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
            onPressed: () => FirestoreService.deleteProject(p['id']),
          ),
        ],
      ),
    );
  }
}
