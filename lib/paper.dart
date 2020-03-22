import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

enum InitialPanDirection { UNINITIALIZED, RIGHT, LEFT }

class Paper extends StatefulWidget {
  @required
  final Color color;

  const Paper({Key key, this.color}) : super(key: key);

  @override
  _PaperState createState() => _PaperState();
}

class _PaperState extends State<Paper> with SingleTickerProviderStateMixin {
  double _progress = 1.0;
  InitialPanDirection _initialPanDirection = InitialPanDirection.UNINITIALIZED;

  AnimationController controller;
  Animation curve;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    curve = CurvedAnimation(parent: controller, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        setState(() {
          if (_initialPanDirection == InitialPanDirection.UNINITIALIZED) {
            _initialPanDirection = getInitialPanDirection(details);
          }

          // Disallow page turns that go from left to right. We want
          // the paper to only go right to left.
          if (_initialPanDirection != InitialPanDirection.LEFT) {
            return;
          }

          _progress =
              details.localPosition.dx / MediaQuery.of(context).size.width;
        });
      },
      onPanEnd: (details) {
        _animateToFinalProgress();
        _resetInitialPanDirection();
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

  InitialPanDirection getInitialPanDirection(DragUpdateDetails details) {
    if (details.delta.dx > 0) {
      return _initialPanDirection = InitialPanDirection.RIGHT;
    }
    return _initialPanDirection = InitialPanDirection.LEFT;
  }

  void _animateToFinalProgress() {
    var tweenEnd = _progress < 0.1 ? -1.0 : 1.0;

    Animation curve =
        CurvedAnimation(parent: controller, curve: Curves.easeOut);

    animation = Tween<double>(begin: _progress, end: tweenEnd).animate(curve)
      ..addListener(() {
        setState(() {
          _progress = animation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });

    controller.reset();
    controller.forward();
  }

  void _resetInitialPanDirection() {
    setState(() {
      _initialPanDirection = InitialPanDirection.UNINITIALIZED;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
    // Determines the strength of the fold/bend on a 0-1 range
    var strength = 1 - progress;

    // Width of the folded paper
    var foldWidth = (canvasSize.width * 0.5) * (1 - progress);

    // X position of the folded paper
    var foldX = canvasSize.width * progress + foldWidth;

    // How far outside of the book the paper is bent due to perspective
    var verticalPerspectiveDent = 20 * strength;

    // The maximum widths of the three shadows used
    var paperShadowWidth =
        (canvasSize.width * 0.5) * max(min(1 - progress, 0.5), 0);
    var rightShadowWidth =
        (canvasSize.width * 0.5) * max(min(strength, 0.5), 0);
    var leftShadowWidth = (canvasSize.width * 0.5) * max(min(strength, 0.5), 0);

    drawLeftSharpShadow(strength, canvas, foldX, foldWidth,
        verticalPerspectiveDent, canvasSize);
    drawLeftDropShadow(
        foldX, foldWidth, leftShadowWidth, canvasSize, strength, canvas);
    drawFoldedPaperWithShadow(foldX, paperShadowWidth, canvasSize,
        verticalPerspectiveDent, foldWidth, canvas);
    if (progress > -1.0) {
      drawRightDropShadow(
          foldX, rightShadowWidth, canvasSize, strength, canvas);
    }
  }

  void drawLeftSharpShadow(double strength, Canvas canvas, double foldX,
      double foldWidth, double verticalPerspectiveDent, Size canvasSize) {
    Paint leftShadowPaint = new Paint()
      ..color = Color.fromRGBO(0, 0, 0, 0.05 * strength)
      ..strokeWidth = 30 * strength
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(foldX - foldWidth, -verticalPerspectiveDent * 0.5),
        Offset(foldX - foldWidth,
            canvasSize.height + (verticalPerspectiveDent * 0.5)),
        leftShadowPaint);
  }

  void drawLeftDropShadow(double foldX, double foldWidth,
      double leftShadowWidth, Size canvasSize, double strength, Canvas canvas) {
    var leftDropShadowRect = Rect.fromLTRB(foldX - foldWidth - leftShadowWidth,
        0, foldX - foldWidth, canvasSize.height);

    final Gradient leftDropShadowGradient = new LinearGradient(
      colors: <Color>[
        Color.fromRGBO(0, 0, 0, 0),
        Color.fromRGBO(0, 0, 0, strength * 0.15),
      ],
      stops: [
        0.0,
        1.0,
      ],
    );

    Paint leftDropShadowPaint = Paint()
      ..shader = leftDropShadowGradient.createShader(leftDropShadowRect);
    canvas.drawRect(leftDropShadowRect, leftDropShadowPaint);
  }

  void drawRightDropShadow(double foldX, double rightShadowWidth,
      Size canvasSize, double strength, Canvas canvas) {
    var rightDropShadowRect =
        Rect.fromLTRB(foldX, 0, foldX + rightShadowWidth, canvasSize.height);

    final Gradient rightDropShadowGradient = new LinearGradient(
      colors: <Color>[
        Color.fromRGBO(0, 0, 0, strength * 0.2),
        Color.fromRGBO(0, 0, 0, 0),
      ],
      stops: [
        0.0,
        0.8,
      ],
    );

    Paint rightDropShadowPaint = Paint()
      ..shader = rightDropShadowGradient.createShader(rightDropShadowRect);

    canvas.drawRect(rightDropShadowRect, rightDropShadowPaint);
  }

  void drawFoldedPaperWithShadow(
      double foldX,
      double paperShadowWidth,
      Size canvasSize,
      double verticalPerspectiveDent,
      double foldWidth,
      Canvas canvas) {
    // Gradient applied to the folded paper (highlights & shadows)
    final LinearGradient foldGradient = new LinearGradient(
      colors: <Color>[
        Color(0xFFFAFAFA),
        Color(0xFFEEEEEE),
        Color(0xFFFAFAFA),
        Color(0xFFE2E2E2),
      ],
      stops: [0.35, 0.73, 0.9, 1.0],
    );

    var foldedPaperShadowRect =
        Rect.fromLTRB(foldX - paperShadowWidth, 0, foldX, 0);

    Paint foldedPaperShadowPaint = Paint()
      ..shader = foldGradient.createShader(foldedPaperShadowRect);

    Paint foldedPaperPaint = new Paint()
      ..color = Color.fromRGBO(0, 0, 0, 0.06)
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Path foldedPaperPath = Path();
    foldedPaperPath.moveTo(foldX, 0);
    foldedPaperPath.lineTo(foldX, canvasSize.height);
    foldedPaperPath.quadraticBezierTo(
        foldX,
        canvasSize.height + (verticalPerspectiveDent * 2),
        foldX - foldWidth,
        canvasSize.height + verticalPerspectiveDent);
    foldedPaperPath.lineTo(foldX - foldWidth, -verticalPerspectiveDent);
    foldedPaperPath.quadraticBezierTo(
        foldX, -verticalPerspectiveDent * 2, foldX, 0);

    canvas.drawPath(foldedPaperPath, foldedPaperPaint);
    canvas.drawPath(foldedPaperPath, foldedPaperShadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
