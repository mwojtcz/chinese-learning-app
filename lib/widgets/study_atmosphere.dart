import 'package:flutter/material.dart';

import '../models/app_language.dart';

class StudyAtmosphere extends StatelessWidget {
  const StudyAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _StudyDoodles(Theme.of(context).colorScheme),
        child: child,
      );
}

class StudyEncouragement extends StatelessWidget {
  const StudyEncouragement({super.key, required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomRight: Radius.circular(22),
          bottomLeft: Radius.circular(6),
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
              child: Text('🐼 ✨', style: TextStyle(fontSize: 28))),
          const SizedBox(height: 8),
          Text(
            language.text(
              'Małe kroki, wielkie odkrycia.',
              '小小进步，大大发现。',
              '小小進步，大大發現。',
            ),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            language.text(
              'Panda też kiedyś nie znała tego słowa.',
              '熊猫也曾不认识这个词。',
              '熊貓也曾不認識這個詞。',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _StudyDoodles extends CustomPainter {
  const _StudyDoodles(this.colors);

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()..color = colors.primary.withValues(alpha: .045);
    final ink = Paint()
      ..color = colors.primary.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width - 16, 50), 105, wash);
    canvas.drawCircle(Offset(8, size.height - 28), 84, wash);
    for (final point in [
      Offset(size.width - 42, 40),
      Offset(22, size.height * .42),
      Offset(size.width - 30, size.height * .7),
    ]) {
      final star = Path()
        ..moveTo(point.dx, point.dy - 8)
        ..quadraticBezierTo(point.dx + 1, point.dy - 1, point.dx + 8, point.dy)
        ..quadraticBezierTo(point.dx + 1, point.dy + 1, point.dx, point.dy + 8)
        ..quadraticBezierTo(point.dx - 1, point.dy + 1, point.dx - 8, point.dy)
        ..quadraticBezierTo(point.dx - 1, point.dy - 1, point.dx, point.dy - 8);
      canvas.drawPath(star, ink);
    }
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width - 22 - (i % 2) * 10, size.height - 30 - i * 12),
        1.8,
        wash..color = colors.secondary.withValues(alpha: .18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StudyDoodles oldDelegate) =>
      oldDelegate.colors != colors;
}
