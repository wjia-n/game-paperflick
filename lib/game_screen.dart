import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Paper Flick — slingshot a paper ball into the bin. 20 levels.
class PaperFlickScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const PaperFlickScreen({super.key, required this.players, required this.callbacks});

  @override
  State<PaperFlickScreen> createState() => _PaperFlickScreenState();
}

class _Level {
  final double binX; // 0..1
  final double binY; // 0..1 (from top)
  final double wind; // px/s^2, can be negative
  final bool moving;
  const _Level(this.binX, this.binY, this.wind, this.moving);
}

class _PaperFlickScreenState extends State<PaperFlickScreen>
    with SingleTickerProviderStateMixin {
  static const totalLevels = 20;
  static const ballsPerLevel = 3;

  int level = 1;
  int ballsLeft = ballsPerLevel;
  int makes = 0;
  bool over = false;

  // ball physics (in fraction-of-size coords, scaled at paint time)
  Offset pos = const Offset(0.5, 0.85);
  Offset vel = Offset.zero;
  bool flying = false;
  bool scored = false;
  bool aiming = false;
  Offset aimVec = Offset.zero; // drag vector in px

  late Ticker _ticker;
  Duration _last = Duration.zero;
  double _moveT = 0; // for moving bin

  static const _levels = [
    _Level(0.5, 0.25, 0, false),
    _Level(0.3, 0.30, 0, false),
    _Level(0.7, 0.30, 0, false),
    _Level(0.5, 0.18, 0, false),
    _Level(0.2, 0.25, 0, false),
    _Level(0.8, 0.25, 60, false),
    _Level(0.5, 0.22, -70, false),
    _Level(0.3, 0.32, 90, false),
    _Level(0.7, 0.20, -90, false),
    _Level(0.5, 0.28, 110, false),
    _Level(0.25, 0.18, 0, false),
    _Level(0.75, 0.18, 60, true),
    _Level(0.5, 0.15, -110, true),
    _Level(0.3, 0.26, 130, true),
    _Level(0.7, 0.26, -130, true),
    _Level(0.5, 0.20, 150, true),
    _Level(0.2, 0.22, -150, true),
    _Level(0.8, 0.22, 170, true),
    _Level(0.5, 0.14, 190, true),
    _Level(0.5, 0.16, -200, true),
  ];

  _Level get _lv => _levels[level - 1];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    if (!flying || over) {
      _last = now;
      return;
    }
    final dt = min(0.05, (now - _last).inMicroseconds / 1e6);
    _last = now;
    _moveT += dt;
    setState(() {
      // gravity + wind (in fraction units; assume ~800px tall play area)
      vel += Offset(_lv.wind / 800, 1400 / 800) * dt;
      pos += vel * dt;
      // walls
      if (pos.dx < 0.03) {
        pos = Offset(0.03, pos.dy);
        vel = Offset(-vel.dx * 0.4, vel.dy);
      }
      if (pos.dx > 0.97) {
        pos = Offset(0.97, pos.dy);
        vel = Offset(-vel.dx * 0.4, vel.dy);
      }
      if (pos.dy < 0.02) {
        pos = Offset(pos.dx, 0.02);
        vel = Offset(vel.dx, -vel.dy * 0.4);
      }
      // bin mouth check
      final bx = _binX();
      if (!scored &&
          vel.dy > 0 &&
          (pos.dx - bx).abs() < 0.055 &&
          (pos.dy - _lv.binY).abs() < 0.03) {
        scored = true;
        _onScore();
        return;
      }
      // floor
      if (pos.dy > 0.97) {
        if (vel.dy.abs() < 0.25) {
          _endBall();
        } else {
          pos = Offset(pos.dx, 0.97);
          vel = Offset(vel.dx * 0.6, -vel.dy * 0.45);
        }
      }
      // out of bounds safety
      if (pos.dy > 1.2) _endBall();
    });
  }

  double _binX() {
    if (!_lv.moving) return _lv.binX;
    return (_lv.binX + 0.22 * sin(_moveT * 1.6)).clamp(0.15, 0.85);
  }

  void _onScore() {
    makes++;
    final gained = 100 + (ballsLeft - 1) * 25;
    widget.players[0].score += gained;
    widget.callbacks.refreshHud();
    Sfx.win();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || over) return;
      _endBall();
    });
  }

  void _endBall() {
    setState(() {
      flying = false;
      scored = false;
      ballsLeft--;
      pos = const Offset(0.5, 0.85);
      vel = Offset.zero;
    });
    if (ballsLeft <= 0) {
      if (level >= totalLevels) {
        _endGame();
      } else {
        setState(() {
          level++;
          ballsLeft = ballsPerLevel;
        });
        Sfx.click();
      }
    }
  }

  void _endGame() {
    setState(() => over = true);
    final s = widget.players[0].score;
    widget.callbacks.finish(
        headline: '$s points! 📄🏀',
        subline: makes >= 40
            ? 'Sharpshooter! The office bows to you.'
            : makes >= 20
                ? 'Solid arm! A few more practice flicks…'
                : 'The bin remains undefeated… this time. Rematch?');
  }

  void _launch() {
    if (over || flying || !aiming) return;
    setState(() {
      aiming = false;
      flying = true;
      _last = Duration.zero;
      // slingshot: velocity opposite to drag, scaled
      vel = Offset(-aimVec.dx / 800 * 6.0, -aimVec.dy / 800 * 6.0);
    });
    Sfx.move();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(t, '📄 Level', '$level/$totalLevels'),
              const SizedBox(width: 10),
              _chip(t, '🏀 Balls', '●' * ballsLeft + '○' * (ballsPerLevel - ballsLeft)),
              const SizedBox(width: 10),
              _chip(t, '⭐ Score', '${widget.players[0].score}'),
            ],
          ),
          if (_lv.wind != 0 && !over)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  '💨 wind ${_lv.wind > 0 ? '→' : '←'} ${(_lv.wind.abs() / 40).round()}/5',
                  style: TextStyle(
                      color: t.accent, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: GestureDetector(
              onPanStart: (d) {
                if (over || flying) return;
                setState(() {
                  aiming = true;
                  aimVec = Offset.zero;
                });
              },
              onPanUpdate: (d) {
                if (!aiming) return;
                setState(() {
                  final v = d.delta;
                  aimVec += v;
                  final m = aimVec.distance;
                  if (m > 220) aimVec = aimVec / m * 220;
                });
              },
              onPanEnd: (_) => _launch(),
              onPanCancel: () => setState(() => aiming = false),
              child: LayoutBuilder(builder: (ctx, box) {
                final size = box.biggest;
                return CustomPaint(
                  size: size,
                  painter: _CourtPainter(
                    theme: t,
                    binX: _binX(),
                    binY: _lv.binY,
                    ball: pos,
                    flying: flying,
                    scored: scored,
                    aiming: aiming,
                    aimVec: aimVec,
                    wind: _lv.wind,
                    moving: _lv.moving,
                  ),
                );
              }),
            ),
          ),
          Text(
              over
                  ? 'Done!'
                  : flying
                      ? (scored ? 'SWISH! 🏀' : '…')
                      : 'Drag back from anywhere, release to flick!',
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _chip(GameTheme t, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration:
          BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: t.muted, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  final GameTheme theme;
  final double binX, binY;
  final Offset ball;
  final bool flying, scored, aiming, moving;
  final Offset aimVec;
  final double wind;

  _CourtPainter({
    required this.theme,
    required this.binX,
    required this.binY,
    required this.ball,
    required this.flying,
    required this.scored,
    required this.aiming,
    required this.aimVec,
    required this.wind,
    required this.moving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // floor line
    canvas.drawLine(
        Offset(0, size.height * 0.97),
        Offset(size.width, size.height * 0.97),
        Paint()
          ..color = theme.muted
          ..strokeWidth = 3);

    // bin (trapezoid, opening at top)
    final bx = binX * size.width;
    final by = binY * size.height;
    final bw = size.width * 0.11;
    final bh = size.height * 0.09;
    final binPaint = Paint()..color = theme.secondary;
    final path = Path()
      ..moveTo(bx - bw / 2, by)
      ..lineTo(bx + bw / 2, by)
      ..lineTo(bx + bw / 2 - 8, by + bh)
      ..lineTo(bx - bw / 2 + 8, by + bh)
      ..close();
    canvas.drawPath(path, binPaint);
    // rim highlight
    canvas.drawLine(Offset(bx - bw / 2, by), Offset(bx + bw / 2, by),
        Paint()..color = theme.accent..strokeWidth = 5..strokeCap = StrokeCap.round);
    if (moving) {
      final tp = TextPainter(
          text: TextSpan(
              text: 'moving!',
              style: TextStyle(color: theme.muted, fontSize: 11)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(bx - tp.width / 2, by + bh + 4));
    }

    // paper ball
    if (!scored) {
      final bp = Offset(ball.dx * size.width, ball.dy * size.height);
      final r = 13.0;
      canvas.drawCircle(bp, r, Paint()..color = const Color(0xFFF5F5F5));
      canvas.drawCircle(
          bp, r, Paint()..color = theme.muted..style = PaintingStyle.stroke..strokeWidth = 2);
      // crumple lines
      canvas.drawLine(bp + const Offset(-6, -2), bp + const Offset(2, 5),
          Paint()..color = theme.muted..strokeWidth = 1.5);
      canvas.drawLine(bp + const Offset(3, -6), bp + const Offset(7, 2),
          Paint()..color = theme.muted..strokeWidth = 1.5);
    } else {
      // ball dropping into bin
      final bp = Offset(bx, by + bh * 0.4);
      canvas.drawCircle(bp, 10, Paint()..color = const Color(0xFFF5F5F5));
    }

    // aim guide: slingshot band + predicted dots
    if (aiming && !flying) {
      final bp = Offset(ball.dx * size.width, ball.dy * size.height);
      final pull = bp + aimVec;
      canvas.drawLine(bp, pull,
          Paint()..color = theme.accent..strokeWidth = 3);
      // predicted trajectory
      var p = bp;
      var v = Offset(-aimVec.dx / 800 * 6.0 * size.width,
          -aimVec.dy / 800 * 6.0 * size.width);
      final dot = Paint()..color = theme.accent.withValues(alpha: 0.6);
      for (int i = 0; i < 16; i++) {
        const dt = 0.06;
        v += Offset(wind / 800 * size.width, 1400 / 800 * size.width) * dt;
        p += v * dt;
        if (p.dy > size.height * 0.97 || p.dx < 0 || p.dx > size.width) break;
        canvas.drawCircle(p, 3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) => true;
}
