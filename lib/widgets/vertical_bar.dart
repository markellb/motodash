import 'dart:math' as math;
import 'package:flutter/material.dart';

class VerticalBar extends StatelessWidget {
  final double minValue;
  final double maxValue;
  final double currentValue;
  final Color activeColor;
  final Color inactiveColor;
  final int segmentCount;
  final double segmentHeight;
  final double segmentWidth;
  final double segmentSpacing;
  final bool isLeft;
  final double curveRadius;

  const VerticalBar({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.segmentCount = 20,
    this.segmentHeight = 8.0,
    this.segmentWidth = 20.0,
    this.segmentSpacing = 2.0,
    this.isLeft = true,
    this.curveRadius = 40.0,
  });

  double _normalizeValue(double value) {
    if (value < minValue) return 0.0;
    if (value > maxValue) return 1.0;
    return (value - minValue) / (maxValue - minValue);
  }

  Offset _calculatePointOnCurve(double t, Size size) {
    final double normalizedT = t;
    final double startY = size.height;
    final double endY = 0.0;
    final double y = startY - (startY - endY) * normalizedT;
    final double curveAmount = curveRadius;
    final double progress = normalizedT;
    double x;
    if (progress < 0.25) {
      final double localT = progress / 0.25;
      final double angle = (1 - localT) * (math.pi / 2);
      x = isLeft
          ? curveAmount * (1 - math.cos(angle))
          : size.width - curveAmount * (1 - math.cos(angle));
    } else if (progress > 0.75) {
      final double localT = (progress - 0.75) / 0.25;
      final double angle = localT * (math.pi / 2);
      x = isLeft
          ? curveAmount * (1 - math.cos(angle))
          : size.width - curveAmount * (1 - math.cos(angle));
    } else {
      x = isLeft ? 0.0 : size.width;
    }
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _VerticalBarPainter(
            minValue: minValue,
            maxValue: maxValue,
            currentValue: currentValue,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            segmentCount: segmentCount,
            segmentHeight: segmentHeight,
            segmentWidth: segmentWidth,
            segmentSpacing: segmentSpacing,
            isLeft: isLeft,
            curveRadius: curveRadius,
            normalizeValue: _normalizeValue,
            calculatePointOnCurve: _calculatePointOnCurve,
          ),
        );
      },
    );
  }
}

class _VerticalBarPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final double currentValue;
  final Color activeColor;
  final Color inactiveColor;
  final int segmentCount;
  final double segmentHeight;
  final double segmentWidth;
  final double segmentSpacing;
  final bool isLeft;
  final double curveRadius;
  final double Function(double) normalizeValue;
  final Offset Function(double, Size) calculatePointOnCurve;

  _VerticalBarPainter({
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.segmentCount,
    required this.segmentHeight,
    required this.segmentWidth,
    required this.segmentSpacing,
    required this.isLeft,
    required this.curveRadius,
    required this.normalizeValue,
    required this.calculatePointOnCurve,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double normalizedValue = normalizeValue(currentValue);
    final int activeSegments = (normalizedValue * segmentCount).round();

    for (int i = 0; i < segmentCount; i++) {
      final bool isActive = i < activeSegments;
      final Color segmentColor = isActive ? activeColor : inactiveColor;

      final double t = i / (segmentCount - 1);
      final Offset center = calculatePointOnCurve(t, size);

      final Paint paint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.fill;

      final Rect rect = Rect.fromCenter(
        center: center,
        width: segmentWidth,
        height: segmentHeight,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_VerticalBarPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.segmentCount != segmentCount ||
        oldDelegate.segmentHeight != segmentHeight ||
        oldDelegate.segmentWidth != segmentWidth ||
        oldDelegate.segmentSpacing != segmentSpacing ||
        oldDelegate.isLeft != isLeft ||
        oldDelegate.curveRadius != curveRadius;
  }
}
