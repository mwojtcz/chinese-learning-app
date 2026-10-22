import 'package:flutter/material.dart';

import '../models/chengyu.dart';

/// Original symbolic scenes, shared by motif; not historical reconstructions.
class ChengyuIllustration extends StatelessWidget {
  const ChengyuIllustration({
    super.key,
    required this.motif,
    required this.semanticLabel,
    this.height = 144,
  });

  final ChengyuMotif motif;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _ChengyuPainter(
                  motif,
                  colors.primary,
                  colors.tertiary,
                  colors.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChengyuPainter extends CustomPainter {
  const _ChengyuPainter(this.motif, this.ink, this.accent, this.paper);

  final ChengyuMotif motif;
  final Color ink;
  final Color accent;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    // A fixed view box preserves each scene's proportions on narrow cards.
    final scale = size.height / 160;
    canvas.translate((size.width - 280 * scale) / 2, 0);
    canvas.scale(scale);
    final brush = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final wash = Paint()..color = accent.withAlpha(46);
    canvas.drawCircle(const Offset(205, 40), 25, wash);
    canvas.drawOval(const Rect.fromLTWH(45, 132, 190, 10), wash);
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), brush);
    void path(Path path) => canvas.drawPath(path, brush);

    switch (motif) {
      case ChengyuMotif.snake:
        path(Path()
          ..moveTo(70, 110)
          ..cubicTo(20, 64, 151, 61, 116, 105)
          ..cubicTo(88, 140, 214, 136, 204, 82)
          ..quadraticBezierTo(197, 62, 180, 68));
        canvas.drawCircle(const Offset(181, 70), 3, Paint()..color = ink);
        line(175, 77, 162, 81);
        line(162, 81, 156, 75);
        line(162, 81, 156, 86);
      case ChengyuMotif.field:
        line(60, 130, 220, 130);
        for (final x in [85.0, 140.0, 195.0]) {
          line(x, 128, x, 77);
          path(Path()
            ..moveTo(x, 103)
            ..quadraticBezierTo(x - 35, 103, x - 23, 78)
            ..quadraticBezierTo(x, 78, x, 103)
            ..quadraticBezierTo(x + 3, 66, x + 25, 65)
            ..quadraticBezierTo(x + 30, 94, x, 103));
        }
        line(58, 142, 212, 142);
      case ChengyuMotif.well:
        canvas.drawOval(const Rect.fromLTWH(81, 78, 118, 35), brush);
        path(Path()
          ..moveTo(81, 95)
          ..lineTo(81, 129)
          ..quadraticBezierTo(140, 151, 199, 129)
          ..lineTo(199, 95));
        line(82, 119, 197, 119);
        line(110, 111, 110, 119);
        line(165, 120, 165, 137);
        path(Path()
          ..moveTo(140, 30)
          ..quadraticBezierTo(116, 57, 140, 63)
          ..quadraticBezierTo(164, 57, 140, 30));
      case ChengyuMotif.horse:
        path(Path()
          ..moveTo(84, 94)
          ..lineTo(168, 94)
          ..lineTo(183, 61)
          ..lineTo(180, 40)
          ..lineTo(193, 50)
          ..lineTo(207, 45)
          ..lineTo(216, 77)
          ..lineTo(197, 83)
          ..lineTo(183, 110)
          ..lineTo(178, 135)
          ..lineTo(166, 135)
          ..lineTo(165, 112)
          ..lineTo(105, 112)
          ..lineTo(99, 135)
          ..lineTo(87, 135)
          ..close());
        path(Path()..moveTo(84, 96)..quadraticBezierTo(57, 86, 63, 117));
        canvas.drawCircle(const Offset(201, 62), 2.5, Paint()..color = ink);
      case ChengyuMotif.boat:
        path(Path()
          ..moveTo(57, 105)
          ..lineTo(224, 105)
          ..lineTo(199, 130)
          ..lineTo(82, 130)
          ..close());
        line(138, 104, 138, 31);
        path(Path()..moveTo(145, 37)..lineTo(195, 94)..lineTo(145, 94)..close());
        for (final x in [45.0, 105.0, 165.0]) {
          path(Path()..moveTo(x, 143)..quadraticBezierTo(x + 22, 134, x + 44, 143));
        }
      case ChengyuMotif.bell:
        path(Path()
          ..moveTo(90, 112)
          ..quadraticBezierTo(106, 100, 106, 73)
          ..cubicTo(106, 33, 174, 33, 174, 73)
          ..quadraticBezierTo(174, 100, 190, 112)
          ..close());
        canvas.drawCircle(const Offset(140, 123), 8, brush);
        canvas.drawArc(const Rect.fromLTWH(132, 30, 16, 18), 3.14, 3.14, false, brush);
        line(74, 64, 60, 55);
        line(70, 91, 52, 91);
        line(207, 64, 221, 55);
        line(211, 91, 229, 91);
      case ChengyuMotif.dragon:
        path(Path()
          ..moveTo(55, 126)
          ..cubicTo(154, 140, 50, 57, 137, 65)
          ..cubicTo(176, 70, 144, 114, 183, 108)
          ..quadraticBezierTo(205, 100, 193, 75)
          ..lineTo(215, 68)
          ..lineTo(209, 49)
          ..lineTo(186, 43)
          ..lineTo(174, 25));
        line(185, 44, 194, 23);
        line(200, 83, 222, 87);
        line(222, 87, 235, 80);
        canvas.drawCircle(const Offset(201, 57), 3, Paint()..color = accent);
        for (final x in [93.0, 114.0, 135.0]) {
          line(x, 63, x - 4, 51);
        }
      case ChengyuMotif.music:
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(60, 96, 160, 29), const Radius.circular(12)),
          brush,
        );
        for (var i = 0; i < 5; i++) {
          line(73, 103 + i * 3.0, 208, 103 + i * 3.0);
        }
        line(122, 73, 122, 32);
        line(122, 32, 170, 24);
        line(170, 24, 170, 63);
        canvas.drawOval(const Rect.fromLTWH(108, 65, 15, 10), brush);
        canvas.drawOval(const Rect.fromLTWH(156, 55, 15, 10), brush);
      case ChengyuMotif.mountain:
        path(Path()
          ..moveTo(32, 134)
          ..lineTo(104, 39)
          ..lineTo(150, 102)
          ..lineTo(190, 58)
          ..lineTo(251, 134)
          ..close());
        path(Path()..moveTo(82, 68)..lineTo(104, 80)..lineTo(119, 60));
        path(Path()..moveTo(161, 91)..lineTo(190, 104)..lineTo(211, 85));
        path(Path()..moveTo(123, 150)..quadraticBezierTo(144, 137, 157, 119));
      case ChengyuMotif.bow:
        path(Path()..moveTo(97, 29)..quadraticBezierTo(167, 80, 97, 131));
        line(97, 29, 97, 131);
        line(70, 80, 220, 80);
        line(220, 80, 206, 69);
        line(220, 80, 206, 91);
        line(71, 80, 59, 70);
        line(71, 80, 59, 90);
      case ChengyuMotif.forest:
        for (final x in [62.0, 214.0]) {
          line(x, 130, x, 45);
          path(Path()
            ..moveTo(x - 22, 82)
            ..lineTo(x, 34)
            ..lineTo(x + 22, 82)
            ..close());
        }
        path(Path()
          ..moveTo(105, 114)
          ..lineTo(101, 80)
          ..lineTo(119, 91)
          ..lineTo(141, 91)
          ..lineTo(158, 80)
          ..lineTo(154, 114)
          ..lineTo(130, 132)
          ..close());
        path(Path()..moveTo(105, 114)..lineTo(130, 118)..lineTo(154, 114));
        canvas.drawCircle(const Offset(130, 120), 3, Paint()..color = ink);
        canvas.drawCircle(const Offset(115, 104), 2, Paint()..color = ink);
        canvas.drawCircle(const Offset(144, 104), 2, Paint()..color = ink);
    }
  }

  @override
  bool shouldRepaint(covariant _ChengyuPainter oldDelegate) =>
      oldDelegate.motif != motif ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent ||
      oldDelegate.paper != paper;
}
