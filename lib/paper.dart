import 'dart:ui';

import 'package:flutter/cupertino.dart';

class Paper extends StatefulWidget {
  @required
  final Color color;

  const Paper({Key key, this.color}) : super(key: key);

  @override
  _PaperState createState() => _PaperState();
}

class _PaperState extends State<Paper> {
  double _progress = 0.0;
  double _initial = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _initial = details.globalPosition.dx;
      },
      onPanUpdate: (details) {
        double distance = details.globalPosition.dx - _initial;
        double percentageAddition = distance / 200;
        setState(() {
          _progress = (_progress + percentageAddition).clamp(0.0, 100.0);
          //Todo: make this work
        });
      },
      onPanEnd: (details) {
        _initial = 0.0;
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: CustomPaint(
          foregroundPainter:
              PaperPainter(color: this.widget.color, progress: _progress),
        ),
      ),
    );
  }
}

class PaperPainter extends CustomPainter {
  @required
  final Color color;
  @required
  final double progress;

  PaperPainter({this.color, this.progress});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Paint paint = new Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTRB(0, 0, canvasSize.width, canvasSize.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
