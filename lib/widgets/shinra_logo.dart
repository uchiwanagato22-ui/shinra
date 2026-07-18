import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Logo Shinra réutilisable : un noyau géométrique avec un "S" caché dans
/// les arcs, entouré d'un anneau d'énergie. Utilisé à 3 endroits :
///  - Splash screen (grand format, animation de "réveil")
///  - À côté de "Je réfléchis..." dans le chat (petit format, pulse)
///  - Potentiellement dans l'AppBar / à propos
///
/// [active] = true → pulse en continu (Shinra travaille).
/// [active] = false → immobile, à l'arrêt.
class ShinraLogo extends StatefulWidget {
  final double size;
  final bool active;
  final double progress; // 0.0 → 1.0, pour l'animation de construction (splash)

  const ShinraLogo({
    super.key,
    this.size = 40,
    this.active = false,
    this.progress = 1.0,
  });

  @override
  State<ShinraLogo> createState() => _ShinraLogoState();
}

class _ShinraLogoState extends State<ShinraLogo> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _tapCtrl; // burst lumineux au clic
  late final Animation<double> _tapFlash;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _tapFlash = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 75),
    ]).animate(_tapCtrl);
  }

  void _onTap() {
    if (_tapCtrl.isAnimating) return; // évite le spam de clics
    _tapCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, _tapCtrl]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _ShinraLogoPainter(
              t: _ctrl.value,
              active: widget.active,
              progress: widget.progress,
              tapFlash: _tapFlash.value,
            ),
          );
        },
      ),
    );
  }
}

class _ShinraLogoPainter extends CustomPainter {
  final double t; // 0..1 boucle continue
  final bool active;
  final double progress; // 0..1 construction du logo (splash)
  final double tapFlash; // 0..1 burst lumineux temporaire au clic

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);

  _ShinraLogoPainter({required this.t, required this.active, required this.progress, this.tapFlash = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Pulsation douce quand actif (respiration du noyau)
    final pulse = active ? (0.92 + 0.08 * (0.5 + 0.5 * math.sin(t * 2 * math.pi))) : 1.0;
    final visible = progress.clamp(0.0, 1.0);

    // 4 pétales symétriques (façon diamant/boussole) qui se dessinent
    // progressivement depuis le centre vers l'extérieur — inspiré du concept
    // validé, recoloré en crimson/or pour rester cohérent avec Shokugeki.
    final petalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.10
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final baseAngle = (i * math.pi / 2) - math.pi / 4;
      final petalColor = i.isEven ? crimson : gold;
      petalPaint.shader = SweepGradient(
        colors: [petalColor.withOpacity(0.15), petalColor, petalColor.withOpacity(0.9)],
        startAngle: baseAngle,
        endAngle: baseAngle + math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.85));

      final sweep = (math.pi / 2 - 0.18) * visible;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.62 * pulse),
        baseAngle + 0.09,
        sweep,
        false,
        petalPaint,
      );
    }

    // Pointe lumineuse gauche/droite (comme le concept d'origine)
    if (visible > 0.5) {
      final tipOpacity = ((visible - 0.5) / 0.5).clamp(0.0, 1.0);
      final tipPaint = Paint()
        ..color = Colors.white.withOpacity(0.8 * tipOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx - radius * 0.98, center.dy), Offset(center.dx - radius * 0.55, center.dy), tipPaint);
      canvas.drawLine(Offset(center.dx + radius * 0.98, center.dy), Offset(center.dx + radius * 0.55, center.dy), tipPaint);
    }

    // Noyau central lumineux — le "S" caché vit dans la torsion des 4
    // pétales autour de ce point, plutôt que dessiné littéralement.
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.95 * visible), gold.withOpacity(0.85 * visible), crimson.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22));
    canvas.drawCircle(center, radius * 0.16 * pulse * visible, corePaint);

    final coreDot = Paint()..color = Colors.white.withOpacity(visible);
    canvas.drawCircle(center, radius * 0.06 * pulse * visible, coreDot);

    // Particules d'énergie en orbite quand Shinra travaille
    if (active) {
      final particlePaint = Paint()..color = gold.withOpacity(0.8);
      for (int i = 0; i < 3; i++) {
        final angle = t * 2 * math.pi + (i * 2 * math.pi / 3);
        final p = Offset(
          center.dx + math.cos(angle) * radius * 1.05,
          center.dy + math.sin(angle) * radius * 1.05,
        );
        canvas.drawCircle(p, radius * 0.035, particlePaint);
      }
    }

    // Effet lumineux au clic : un anneau d'énergie part du centre et
    // s'étend vers l'extérieur en s'estompant (comme une onde de choc).
    if (tapFlash > 0.001) {
      final burstRadius = radius * (0.2 + tapFlash * 1.3);
      final burstPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06 * (1 - tapFlash * 0.7)
        ..color = Colors.white.withOpacity((1 - tapFlash) * 0.9);
      canvas.drawCircle(center, burstRadius, burstPaint);

      final glowPaint = Paint()
        ..color = gold.withOpacity((1 - tapFlash) * 0.35);
      canvas.drawCircle(center, radius * 0.5 * (1 + tapFlash * 0.4), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShinraLogoPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.active != active || oldDelegate.progress != progress || oldDelegate.tapFlash != tapFlash;
}
