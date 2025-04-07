import 'package:flutter/material.dart';

class CustomBarChart extends StatelessWidget {
  final Map<String, int> data;

  const CustomBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 200, 
        maxWidth: double.infinity, 
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: BarChartPainter(data),
          );
        },
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final Map<String, int> data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.blue;
    double barWidth = size.width / (data.length * 2);
    double maxDataValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();

    double xPos = 0;

    TextStyle labelStyle = const TextStyle(fontSize: 12, color: Colors.black);
    TextStyle valueStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black);

    data.forEach((key, value) {
      double barHeight = (value / maxDataValue) * size.height;
      
      Rect rect = Rect.fromLTWH(xPos, size.height - barHeight, barWidth, barHeight);
      RRect roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(roundedRect, paint);

      TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: key,
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '...',
      )..layout(maxWidth: barWidth);

      if (labelPainter.width > barWidth) {
        labelPainter = TextPainter(
          text: TextSpan(
            text: '${key.substring(0, (barWidth ~/ labelStyle.fontSize!) - 3)}...',
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: barWidth);
      }

      labelPainter.paint(
        canvas,
        Offset(xPos + barWidth / 2 - labelPainter.width / 2, size.height + 4),
      );

      TextPainter valuePainter = TextPainter(
        text: TextSpan(text: value.toString(), style: valueStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth);

      valuePainter.paint(
        canvas,
        Offset(xPos + barWidth / 2 - valuePainter.width / 2, size.height - barHeight - 20),
      );

      xPos += barWidth * 2; 
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
