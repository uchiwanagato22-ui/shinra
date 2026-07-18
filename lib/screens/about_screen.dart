import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════
//  À PROPOS — Shinra IA
//  Avatar Nagato + identité du projet + roadmap
// ═══════════════════════════════════════════════════════

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const bg = Color(0xFF030308);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  static const String appVersion = "0.1.0 — Fondation";

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _ouvrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir : $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Stack(
        children: [
          const _ParticleBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 30),
                _buildQuote(),
                const SizedBox(height: 30),
                _sectionLabel("SHINRA IA — L'AGENT"),
                const SizedBox(height: 14),
                _buildDescriptionCard(),
                const SizedBox(height: 28),
                _sectionLabel("PHILOSOPHIE — LE CHEF SHINRA"),
                const SizedBox(height: 14),
                _buildChefShinraCard(),
                const SizedBox(height: 28),
                _sectionLabel("CE QUI FONCTIONNE DÉJÀ"),
                const SizedBox(height: 14),
                _buildFeatureGrid(),
                const SizedBox(height: 28),
                _sectionLabel("FEUILLE DE ROUTE"),
                const SizedBox(height: 14),
                _buildRoadmap(),
                const SizedBox(height: 28),
                _sectionLabel("CRÉDITS & LIENS"),
                const SizedBox(height: 14),
                _buildCreditsCard(),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Shinra IA $appVersion  •  © ${DateTime.now().year} Uchiwa Nagato',
                    style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, child) {
            final glow = 0.35 + _glowAnim.value * 0.35;
            return Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: gold.withOpacity(glow), blurRadius: 40, spreadRadius: 6),
                  BoxShadow(color: crimson.withOpacity(glow * 0.5), blurRadius: 20, spreadRadius: 1),
                ],
                border: Border.all(color: crimson.withOpacity(0.6), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'lib/assets/images/nagato_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: surface2,
                    child: Icon(Icons.person, color: crimson.withOpacity(0.4), size: 60),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(colors: [crimson, gold]).createShader(bounds),
          child: Text(
            'SHINRA IA',
            style: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 6),
          ),
        ),
        const SizedBox(height: 4),
        Text('うちは 長門', style: GoogleFonts.notoSansJp(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          'Créé par Uchiwa Nagato — Nouakchott, Mauritanie',
          style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildQuote() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            '« Je ne construis pas une application. Je construis une entreprise. »',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text('孤独は俺の力だ。 — Solitude is my power.',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(color: crimson.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        'Shinra IA n\'est pas un simple chatbot : c\'est un agent de bureau autonome. '
        'Il discute, code, observe ton écran, pilote la souris et le clavier, ouvre tes '
        'logiciels (Blender, VS Code, et bientôt bien d\'autres), génère images et vidéos, '
        'et s\'appuie sur plusieurs cerveaux IA (Gemini, GPT, Claude, Mistral) selon la tâche à accomplir.\n\n'
        'L\'objectif : un vrai partenaire de travail, pas une fenêtre de chat de plus.',
        style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 14, height: 1.6),
      ),
    );
  }

  Widget _buildChefShinraCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gold.withOpacity(0.12), crimson.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: crimson.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.hub_outlined, color: crimson, size: 20),
            const SizedBox(width: 8),
            Text('Une seule IA, plusieurs cerveaux',
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(
            'Tu ne vois jamais "GPT" ou "Claude" séparément : Shinra choisit (ou tu choisis) '
            'le meilleur moteur pour chaque tâche — code, recherche, image, traduction — et '
            'te présente une seule voix, une seule identité : Shinra IA.',
            style: GoogleFonts.rajdhani(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      ("💬", "Chat multi-IA", "Gemini, OpenAI, Claude, Mistral"),
      ("🖥️", "Agent de bureau", "Ouvre apps (.exe), fichiers, clics/clavier"),
      ("🎨", "Génération d'image", "OpenAI (gpt-image-1) / Gemini (Imagen)"),
      ("🎬", "Génération vidéo", "Runway ML — texte vers vidéo"),
      ("👁️", "Vision d'écran", "Analyse en temps réel de ton écran"),
      ("🔧", "Auto-réparation", "Détecte et corrige les erreurs de code"),
      ("🔒", "Sécurité locale", "Clés API chiffrées, jeton de session"),
      ("🌐", "Navigation web", "Automatisation de navigateur intégrée"),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.6,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final (emoji, title, desc) = features[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: green.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(desc, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoadmap() {
    final items = [
      ("v0.1 — Fondation", "Multi-IA, image/vidéo réelles, agent bureau, sécurité", true),
      ("v0.5", "Système de plugins (Blender, Unity, VS Code, OBS...)", false),
      ("v0.7", "Boucle d'action complète (l'agent enchaîne plusieurs étapes seul)", false),
      ("v0.9", "Mode vocal, mémoire enrichie, Mission Control", false),
      ("v1.0 — 2026", "Version Free/Pro, personnalité évolutive de Shinra", false),
    ];
    return Column(
      children: items.map((item) {
        final (title, desc, done) = item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? green : Colors.white24, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.shareTechMono(color: done ? green : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(desc, style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreditsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Construit avec Flutter, FastAPI, et beaucoup de café à Nouakchott.',
              style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              _linkChip(Icons.code, "GitHub", () => _ouvrirUrl('https://github.com')),
              _linkChip(Icons.forum_outlined, "Discord", () => _ouvrirUrl('https://discord.com')),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('(Liens à mettre à jour dès que tes comptes sont prêts.)',
                style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _linkChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: crimson, size: 15),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(width: 3, height: 16, color: gold, margin: const EdgeInsets.only(right: 10)),
      Text(label, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    ]);
  }
}

// ── Fond à particules (repris du style Shokugeki Menu) ──
class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(painter: _ParticlePainter(_ctrl.value), size: Size.infinite),
  );
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static const crimson = Color(0xFFE1233D);

  static final _pts = List.generate(18, (i) => [
    (i * 137.5) % 100.0,
    (i * 73.3) % 100.0,
    0.2 + (i % 5) * 0.08,
    (i * 0.7) % 1.0,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final x = p[0] / 100 * size.width;
      final baseY = p[1] / 100 * size.height;
      final y = (baseY - progress * size.height * 0.4 * p[2]) % size.height;
      final o = (math.sin((progress + p[3]) * math.pi * 2) * 0.5 + 0.5) * p[2];
      canvas.drawCircle(Offset(x, y < 0 ? y + size.height : y), 1.5,
          Paint()..color = crimson.withOpacity(o * 0.5));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
