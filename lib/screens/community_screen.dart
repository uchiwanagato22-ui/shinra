import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';

// ═══════════════════════════════════════════════════════
//  COMMUNAUTÉ — profils publics opt-in
//  Rien n'est public par défaut. L'utilisateur choisit explicitement de
//  partager un nom + une bio courte, jamais ses données privées.
// ═══════════════════════════════════════════════════════

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  bool _isPublic = false;
  bool _loading = true;
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await FirestoreService.getProfile();
    if (!mounted) return;
    setState(() {
      _isPublic = profile?['publicProfile'] == true;
      _loading = false;
    });
  }

  Future<void> _togglePublic(bool value) async {
    if (value) {
      final bio = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            backgroundColor: surface2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('PROFIL PUBLIC', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 15)),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              style: GoogleFonts.rajdhani(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Petite bio (visible par tous les utilisateurs Shinra)',
                hintStyle: const TextStyle(color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: crimson),
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('ACTIVER', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (bio == null) return;
      await FirestoreService.setProfilePublic(true, bio: bio);
    } else {
      await FirestoreService.setProfilePublic(false);
    }
    if (!mounted) return;
    setState(() => _isPublic = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: crimson));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNAUTÉ', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('// Rien n\'est partagé sans ton accord explicite', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (_isPublic ? gold : Colors.white24).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_isPublic ? Icons.public : Icons.public_off, color: _isPublic ? gold : Colors.white38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profil public', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(_isPublic ? 'Visible dans l\'annuaire communauté' : 'Privé (par défaut)',
                          style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(value: _isPublic, activeColor: gold, onChanged: _togglePublic),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('ANNUAIRE', style: GoogleFonts.shareTechMono(color: gold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.publicProfilesStream(),
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? [];
                if (profiles.isEmpty) {
                  return Center(
                    child: Text('Personne n\'a encore rendu son profil public.',
                        style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 14)),
                  );
                }
                return ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, i) {
                    final p = profiles[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: crimson.withOpacity(0.2), child: Icon(Icons.person, color: crimson)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['displayName'] ?? 'Anonyme', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.w600)),
                                if ((p['bio'] ?? '').toString().isNotEmpty)
                                  Text(p['bio'], style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
