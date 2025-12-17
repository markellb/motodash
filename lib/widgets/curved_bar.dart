import 'package:flutter/material.dart';

class CurvedBar extends StatelessWidget {
  final double minValue;
  final double maxValue;
  final double currentValue;
  final Color activeColor;
  final Color inactiveColor;
  final int segmentCount;
  final double segmentSize;
  final double curveHeight;

  const CurvedBar({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.segmentCount = 20,
    this.segmentSize = 8.0,
    this.curveHeight = 100.0,
  });

  double _normalizeValue(double value) {
    if (value < minValue) return 0.0;
    if (value > maxValue) return 1.0;
    return (value - minValue) / (maxValue - minValue);
  }

  Offset _calculatePointOnCurve(double t, Size size) {
    final double startX = 0.0;
    final double startY = size.height;
    final double endX = size.width;
    final double endY = 0.0;
    final double controlX = size.width * 0.5;
    final double controlY = -curveHeight;
    final double x = (1 - t) * (1 - t) * startX +
        2 * (1 - t) * t * controlX +
        t * t * endX;
    final double y = (1 - t) * (1 - t) * startY +
        2 * (1 - t) * t * controlY +
        t * t * endY;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CurvedBarPainter(
            minValue: minValue,
            maxValue: maxValue,
            currentValue: currentValue,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            segmentCount: segmentCount,
            segmentSize: segmentSize,
            curveHeight: curveHeight,
            normalizeValue: _normalizeValue,
            calculatePointOnCurve: _calculatePointOnCurve,
          ),
        );
      },
    );
  }
}

class _CurvedBarPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final double currentValue;
  final Color activeColor;
  final Color inactiveColor;
  final int segmentCount;
  final double segmentSize;
  final double curveHeight;
  final double Function(double) normalizeValue;
  final Offset Function(double, Size) calculatePointOnCurve;

  _CurvedBarPainter({
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.segmentCount,
    required this.segmentSize,
    required this.curveHeight,
    required this.normalizeValue,
    required this.calculatePointOnCurve,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double normalizedValue = normalizeValue(currentValue);
    final int activeSegments = (normalizedValue * segmentCount).round();

    for (int i = 0; i < segmentCount; i++) {
      final double t = i / (segmentCount - 1);
      final Offset center = calculatePointOnCurve(t, size);
      final bool isActive = i < activeSegments;
      final Color segmentColor = isActive ? activeColor : inactiveColor;

      final Paint paint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.fill;

      final Rect rect = Rect.fromCenter(
        center: center,
        width: segmentSize,
        height: segmentSize,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_CurvedBarPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.segmentCount != segmentCount ||
        oldDelegate.segmentSize != segmentSize ||
        oldDelegate.curveHeight != curveHeight;
  }
}

