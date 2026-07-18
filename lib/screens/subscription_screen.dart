import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/billing_service.dart';
import '../services/firestore_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _PlanMeta {
  final String id;
  final String label;
  final String price;
  final String tagline;
  final List<String> features;
  const _PlanMeta(this.id, this.label, this.price, this.tagline, this.features);
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF00FF88);
  static const surface = Color(0xFF0B0E18);
  static const surface2 = Color(0xFF0D1225);

  String? _loadingPlan;
  int _teamSeats = 3;

  static const _plans = [
    _PlanMeta('pro', 'PRO', '19\$/mois', 'Pour un usage régulier, sans gérer ses propres clés API', [
      '500 messages/jour avec nos clés',
      'Chef Shinra : choix auto du meilleur moteur',
      'Génération image/vidéo/musique incluse',
    ]),
    _PlanMeta('max', 'MAX', '59.99\$/mois', 'Pour un usage intensif au quotidien', [
      '2000 messages/jour avec nos clés',
      'Génération prioritaire (file d\'attente courte)',
      'Tout Pro inclus',
    ]),
    _PlanMeta('team', 'TEAM', '100\$/mois (3 sièges min.)', 'Pour une équipe qui travaille ensemble sur Shinra', [
      '4000 messages/jour partagés',
      'Projets et missions partagés entre membres',
      'Tout Max inclus, par siège',
    ]),
    _PlanMeta('business', 'BUSINESS', '199\$/mois', 'Pour une entreprise qui dépend de Shinra', [
      'Messages quasi illimités',
      'Support prioritaire dédié',
      'Tout Team inclus',
    ]),
  ];

  Future<void> _upgrade(String plan) async {
    setState(() => _loadingPlan = plan);
    final seats = plan == 'team' ? _teamSeats : 1;
    final url = await BillingService.createCheckoutSession(plan: plan, seats: seats);
    if (!mounted) return;
    setState(() => _loadingPlan = null);

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer le paiement. Vérifie que le serveur Pro est en ligne.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Impossible d\'ouvrir : $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService.profileStream(),
      builder: (context, snapshot) {
        final plan = (snapshot.data?['plan'] ?? 'trial').toString();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ABONNEMENT', style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('// Plan actuel : ${plan.toUpperCase()}',
                  style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),

              if (plan == 'trial')
                _infoBanner(
                  '🎁 Essai gratuit : 5 messages/jour avec nos clés. Ajoute ta propre clé dans Config pour un usage illimité et gratuit, ou choisis un palier ci-dessous.',
                ),
              if (plan == 'free')
                _infoBanner('🔑 Tu utilises tes propres clés API — illimité, gratuit, à ton propre coût.'),

              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _plans.length,
                  itemBuilder: (context, i) => _planCard(_plans[i], plan),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoBanner(String text) => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: gold.withOpacity(0.3))),
        child: Text(text, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13)),
      );

  Widget _planCard(_PlanMeta meta, String currentPlan) {
    final isCurrent = currentPlan == meta.id;
    final loading = _loadingPlan == meta.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? green.withOpacity(0.5) : gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(meta.label, style: GoogleFonts.shareTechMono(color: gold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(width: 10),
              Text(meta.price, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              if (isCurrent) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: green.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('ACTIF', style: GoogleFonts.shareTechMono(color: green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(meta.tagline, style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          ...meta.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(Icons.check, color: gold, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f, style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 13))),
                ]),
              )),
          if (meta.id == 'team') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Sièges : ', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 18),
                  onPressed: () => setState(() => _teamSeats = (_teamSeats - 1).clamp(3, 50)),
                ),
                Text('$_teamSeats', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white38, size: 18),
                  onPressed: () => setState(() => _teamSeats = (_teamSeats + 1).clamp(3, 50)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: (isCurrent || loading) ? null : () => _upgrade(meta.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.white12 : crimson,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isCurrent ? 'PALIER ACTIF' : 'CHOISIR ${meta.label}',
                      style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
