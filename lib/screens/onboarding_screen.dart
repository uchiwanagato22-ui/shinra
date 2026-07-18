import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/shinra_logo.dart';
import '../main.dart' show AuthGate;

const _kOnboardingSeenKey = 'shinra_onboarding_seen';
const crimson = Color(0xFFE1233D);
const gold = Color(0xFFD4AF37);

class _OnboardPage {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardPage(this.icon, this.title, this.description);
}

const _pages = [
  _OnboardPage(
    Icons.auto_awesome,
    'Une seule intelligence',
    'Chat, images, vidéo, voix, musique, code — Shinra rassemble tout sous une seule identité. Tu ne gères plus dix outils différents.',
  ),
  _OnboardPage(
    Icons.smart_toy_outlined,
    'Des agents qui agissent',
    'Shinra ne se contente pas de répondre. Il peut exécuter des missions à plusieurs étapes, avec ta confirmation à chaque action importante.',
  ),
  _OnboardPage(
    Icons.devices_outlined,
    'Partout avec toi',
    'PC pour les tâches lourdes, mobile pour rester connecté. Même compte, même mémoire, où que tu sois.',
  ),
  _OnboardPage(
    Icons.workspace_premium_outlined,
    'Prêt à commencer ?',
    'Essaie gratuitement, puis passe Pro quand tu veux plus de puissance.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Passer', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == 0)
                          const ShinraLogo(size: 90, progress: 1.0, active: true)
                        else
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: crimson.withOpacity(0.5), width: 1.5),
                            ),
                            child: Icon(p.icon, color: gold, size: 38),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? gold : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: crimson,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLast
                      ? _finish
                      : () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
                  child: Text(
                    isLast ? 'Commencer' : 'Suivant',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
