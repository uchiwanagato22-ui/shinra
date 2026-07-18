import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/shinra_logo.dart';
import 'onboarding_screen.dart';
import '../main.dart' show AuthGate;

const _kOnboardingSeenKey = 'shinra_onboarding_seen';

/// Écran noir → un point lumineux naît → le noyau Shinra se construit
/// progressivement → "Shinra IA" apparaît. Puis redirige vers l'onboarding
/// (premier lancement uniquement) ou directement vers Login/Chat.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoProgress;
  late final Animation<double> _textOpacity;
  late final Animation<double> _dotScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

    _dotScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.25)));

    _logoProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.80, curve: Curves.easeOutCubic),
    );

    _textOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), _goNext);
      }
    });
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_kOnboardingSeenKey) ?? false;

    if (!seen) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Le point lumineux initial, avant que le noyau ne se construise
                if (_logoProgress.value < 0.05)
                  Transform.scale(
                    scale: _dotScale.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
                  ShinraLogo(size: 120, progress: _logoProgress.value, active: false),

                const SizedBox(height: 28),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: [
                      Text(
                        'SHINRA IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ton intelligence personnelle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
