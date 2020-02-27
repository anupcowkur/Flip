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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        setState(() {
          _progress =
              details.localPosition.dx / MediaQuery.of(context).size.width;
          print(_progress);
        });
      },
      onPanEnd: (details) {
        _animateToFinalProgress();
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

  void _animateToFinalProgress() {
    if (_progress < 0.5) {
      setState(() {
        _progress = 0.0;
      });
    } else {
      setState(() {
        _progress = 1.0;
      });
    }
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
