import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 대각선 패턴 그리는 CustomPainter
class DiagonalPatternPainter extends CustomPainter {
  final Color lineColor;
  final double strokeWidth;
  final double gapWidth;

  DiagonalPatternPainter({
    required this.lineColor,
    required this.strokeWidth,
    required this.gapWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 대각선 패턴 그리기 (왼쪽 상단에서 오른쪽 하단 방향)
    double gap = strokeWidth + gapWidth;
    double diagLength = size.width + size.height;

    for (double i = -diagLength; i <= diagLength; i += gap * 2) {
      // 왼쪽에서 오른쪽으로 대각선 그리기
      canvas.drawLine(Offset(i, 0), Offset(i + diagLength, diagLength), paint);

      // 오른쪽에서 왼쪽으로 대각선 그리기
      canvas.drawLine(
        Offset(size.width - i, 0),
        Offset(size.width - (i + diagLength), diagLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 그리드 패턴 배경을 그리는 CustomPainter
class GridPatternPainter extends CustomPainter {
  final Color lineColor;
  final double gridSize;

  GridPatternPainter({required this.lineColor, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    // 세로선 그리기
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // 가로선 그리기
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 도트 패턴을 그리는 CustomPainter
class DotsPatternPainter extends CustomPainter {
  final Color dotColor;
  final double dotSize;
  final double spacing;

  DotsPatternPainter({
    required this.dotColor,
    this.dotSize = 2.0,
    this.spacing = 15.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // 도트 패턴 그리기
    for (double y = 0; y < size.height; y += spacing) {
      // 홀수 행은 약간 오프셋 주기
      double xOffset = (y / spacing) % 2 == 0 ? 0 : spacing / 2;

      for (double x = xOffset; x < size.width; x += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 웨이브 패턴을 그리는 CustomPainter
class WavesPatternPainter extends CustomPainter {
  final Color lineColor;
  final double waveHeight;
  final double waveWidth;
  final double strokeWidth;

  WavesPatternPainter({
    required this.lineColor,
    this.waveHeight = 10.0,
    this.waveWidth = 20.0,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 웨이브 라인 간격
    double verticalSpacing = waveHeight * 3;

    // 여러 웨이브 라인 그리기
    for (double y = -waveHeight;
        y <= size.height + waveHeight;
        y += verticalSpacing) {
      final path = Path();
      path.moveTo(0, y);

      // 웨이브 패턴 생성
      for (double x = 0; x < size.width + waveWidth; x += waveWidth) {
        path.relativeQuadraticBezierTo(waveWidth / 2, waveHeight, waveWidth, 0);
        path.relativeQuadraticBezierTo(
            waveWidth / 2, -waveHeight, waveWidth, 0);
      }

      canvas.drawPath(path, paint);
    }

    // 수직 웨이브도 추가
    for (double x = -waveHeight;
        x <= size.width + waveHeight;
        x += verticalSpacing) {
      final path = Path();
      path.moveTo(x, 0);

      // 웨이브 패턴 생성
      for (double y = 0; y < size.height + waveWidth; y += waveWidth) {
        path.relativeQuadraticBezierTo(waveHeight, waveWidth / 2, 0, waveWidth);
        path.relativeQuadraticBezierTo(
            -waveHeight, waveWidth / 2, 0, waveWidth);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 지그재그 패턴을 그리는 CustomPainter
class ZigzagPatternPainter extends CustomPainter {
  final Color lineColor;
  final double zigHeight;
  final double zigWidth;
  final double strokeWidth;

  ZigzagPatternPainter({
    required this.lineColor,
    this.zigHeight = 8.0,
    this.zigWidth = 15.0,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 지그재그 라인 간격
    double verticalSpacing = zigHeight * 4;

    // 여러 지그재그 라인 그리기
    for (double y = 0;
        y <= size.height + verticalSpacing;
        y += verticalSpacing) {
      final path = Path();
      path.moveTo(0, y);

      // 지그재그 패턴 생성
      bool up = true;
      for (double x = 0; x < size.width + zigWidth; x += zigWidth) {
        if (up) {
          path.lineTo(x + zigWidth, y - zigHeight);
        } else {
          path.lineTo(x + zigWidth, y + zigHeight);
        }
        up = !up;
      }

      canvas.drawPath(path, paint);
    }

    // 추가적인 사선 지그재그
    for (double x = 0; x <= size.width; x += verticalSpacing) {
      final path = Path();
      path.moveTo(x, 0);

      // 지그재그 패턴 생성
      bool right = true;
      for (double y = 0; y < size.height + zigWidth; y += zigWidth) {
        if (right) {
          path.lineTo(x + zigHeight, y + zigWidth);
        } else {
          path.lineTo(x - zigHeight, y + zigWidth);
        }
        right = !right;
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 삼각형 패턴을 그리는 CustomPainter
class TrianglesPatternPainter extends CustomPainter {
  final Color triangleColor;
  final double size;
  final double opacity;

  TrianglesPatternPainter({
    required this.triangleColor,
    this.size = 30.0,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = triangleColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // 캔버스를 삼각형으로 채우기
    for (double y = 0; y < canvasSize.height + size; y += size * 0.75) {
      for (double x = 0; x < canvasSize.width + size; x += size) {
        // 오프셋 처리로 패턴 다양화
        double xOffset = (y / (size * 0.75)).floor() % 2 == 0 ? 0 : size / 2;

        // 위쪽 방향 삼각형
        drawTriangle(canvas, paint, Offset(x + xOffset, y), size / 2, true);

        // 아래쪽 방향 삼각형
        drawTriangle(
            canvas, paint, Offset(x + xOffset + size / 2, y), size / 2, false);
      }
    }
  }

  // 삼각형 그리기 함수
  void drawTriangle(
      Canvas canvas, Paint paint, Offset center, double radius, bool pointUp) {
    final path = Path();

    if (pointUp) {
      // 위쪽 방향 삼각형
      path.moveTo(center.dx, center.dy - radius);
      path.lineTo(center.dx - radius, center.dy + radius);
      path.lineTo(center.dx + radius, center.dy + radius);
    } else {
      // 아래쪽 방향 삼각형
      path.moveTo(center.dx, center.dy + radius);
      path.lineTo(center.dx - radius, center.dy - radius);
      path.lineTo(center.dx + radius, center.dy - radius);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
