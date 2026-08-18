import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TechGridBackground extends StatefulWidget {
  const TechGridBackground({super.key});

  @override
  State<TechGridBackground> createState() => _TechGridBackgroundState();
}

class _TechGridBackgroundState extends State<TechGridBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: GridPainter(
            progress: _controller.value,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  GridPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Color baseColor = isDark ? AppColors.primaryBlue : AppColors.primaryBlue;
    
    final paint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.05 : 0.03)
      ..strokeWidth = 0.5;

    const spacing = 45.0;
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw pulsating intersections
    final pulsePaint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.1 : 0.08)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += spacing * 2) {
      for (double j = 0; j < size.height; j += spacing * 2) {
        double pulse = 1.0 + (0.4 * (1.0 + (progress * 2 * 3.14).remainder(3.14).abs()).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(i, j), 1.2 * pulse, pulsePaint);
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => true;
}
