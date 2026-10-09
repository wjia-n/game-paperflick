import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/paperflick_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/classroom_themes.dart';

/// Paper Flick play screen: engine-driven court, gesture aiming,
/// HUD, pause, game-over with stats/share/review.
class GameScreen extends StatefulWidget {
  final FlickAudio audio;
  final FlickSettings settings;
  final FlickMode mode;
  final FlickDifficulty difficulty;
  final StoreService store;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.mode,
    required this.difficulty,
    required this.store,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PaperFlickEngine _engine;
  bool _overDialogShown = false;
  bool _wasPausedBeforeHide = false;

  DeskThemeDef get _t =>
      DeskThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = PaperFlickEngine(
      mode: widget.mode,
      difficulty: widget.difficulty,
      callbacks: FlickCallbacks(
        onFlick: () => widget.audio.flick(),
        onSwish: () => widget.audio.swish(),
        onRim: () => widget.audio.rimClank(),
        onBounce: () => widget.audio.bounce(),
        onInvalid: () => widget.audio.invalid(),
        onLevelUp: () => widget.audio.levelUp(),
        onWin: () {},
        onLose: () {},
      ),
    );
    _engine.addListener(_onEngine);
    _engine.attachTicker(this);
    _engine.startNew();
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.removeListener(_onEngine);
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine while hidden; watchdog skips paused phases.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasPausedBeforeHide = _engine.isPaused;
      _engine.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_wasPausedBeforeHide && !_engine.isOver) _engine.resume();
    }
  }

  void _onEngine() {
    if (!mounted) return;
    if (_engine.isOver && !_overDialogShown) {
      _overDialogShown = true;
      _onGameOver();
    }
    setState(() {});
  }

  Future<void> _onGameOver() async {
    final e = _engine;
    final win = e.makes > 0;
    if (win) {
      widget.audio.win();
    } else {
      widget.audio.lose();
    }
    await widget.settings.recordGame(
        score: e.score, makes: e.makes, level: e.level);
    await widget.settings.recordStreak(e.bestStreakRun);
    // Sensible review moment: every 3rd finished game, graceful when
    // the sheet is unavailable (stays silent — no fake UI).
    if (widget.settings.gamesPlayed % 3 == 0) {
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final t = _t;
        return AlertDialog(
          backgroundColor: t.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: t.accent, width: 2)),
          title: Text(
              win ? '🏀 ${e.score} points!' : 'The bin wins…',
              style: Desk.display(24, theme: t)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_headline(e),
                  style: Desk.body(15, theme: t)),
              const SizedBox(height: 10),
              _resultRow(t, 'Baskets', '${e.makes}/${e.attempts}'),
              _resultRow(t, 'Best streak', '${e.bestStreakRun}'),
              _resultRow(t, 'Level reached', '${e.level}'),
              _resultRow(t, 'All-time best', '${widget.settings.bestScore}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await SharePlus.instance.share(
                  ShareParams(
                    text:
                        'I scored ${e.score} points in Paper Flick! Can you beat me? https://play.google.com/store/apps/details?id=com.gameswajiha.paperflick',
                  ),
                );
              },
              child: Text('Share', style: Desk.label(14, theme: t)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text('Menu', style: Desk.body(14, theme: t)),
            ),
            TextButton(
              onPressed: () {
                widget.audio.gameStart();
                Navigator.of(ctx).pop();
                setState(() {
                  _overDialogShown = false;
                  _engine.restart();
                });
              },
              child: Text('Rematch', style: Desk.label(15, theme: t)),
            ),
          ],
        );
      },
    );
  }

  String _headline(PaperFlickEngine e) {
    if (e.mode == FlickMode.scoreAttack) {
      return e.makes >= 12
          ? 'Lightning arm! The classroom applauds.'
          : e.makes >= 6
              ? 'Solid flicking under pressure!'
              : 'The clock is cruel. One more run?';
    }
    return e.makes >= 40
        ? 'Sharpshooter! The office bows to you.'
        : e.makes >= 20
            ? 'Solid arm! A few more practice flicks…'
            : 'The bin remains undefeated… this time. Rematch?';
  }

  Widget _resultRow(DeskThemeDef t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Desk.body(14, theme: t, color: t.muted)),
          Text(value,
              style: Desk.body(14, theme: t)
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _showPause() {
    _engine.pause();
    final t = _t;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: t.accent, width: 2)),
        title: Text('Paused', style: Desk.display(24, theme: t)),
        content: Text('The paper ball waits patiently.',
            style: Desk.body(15, theme: t)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // quit to menu
            },
            child: Text('Quit', style: Desk.body(14, theme: t)),
          ),
          TextButton(
            onPressed: () {
              widget.audio.gameStart();
              Navigator.of(ctx).pop();
              _engine.restart();
            },
            child: Text('Restart', style: Desk.label(14, theme: t)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _engine.resume();
            },
            child: Text('Resume', style: Desk.label(15, theme: t)),
          ),
        ],
      ),
    ).then((_) {
      // Dialog dismissed any other way: make sure we are unpaused.
      if (mounted && _engine.isPaused && !_engine.isOver) _engine.resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = _engine;
    return Scaffold(
      backgroundColor: t.wallBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t.text),
          onPressed: () {
            widget.audio.click();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
            e.mode == FlickMode.scoreAttack
                ? '⏱️ ${_fmtTime(e.timeLeft)}'
                : '📄 Level ${e.level}',
            style: Desk.display(18, theme: t)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.accent, width: 1.5),
            ),
            child: Text('⭐ ${e.score}',
                style: Desk.display(16, theme: t)),
          ),
          IconButton(
            icon: Icon(Icons.pause, color: t.text),
            onPressed: () {
              widget.audio.click();
              _showPause();
            },
          ),
        ],
      ),
      body: Desk.backdrop(
        t,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (e.mode != FlickMode.scoreAttack)
                    _chip(t, '🏀 Balls',
                        '●' * e.ballsLeft + '○' * (3 - e.ballsLeft)),
                  if (e.streak >= 2) ...[
                    const SizedBox(width: 8),
                    _chip(t, '🔥 Streak', '${e.streak}'),
                  ],
                  const SizedBox(width: 8),
                  _chip(t, '🎯 Makes', '${e.makes}'),
                ],
              ),
            ),
            if (e.spec.wind.abs() > 1 && !e.isOver)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                    '💨 wind ${e.spec.wind > 0 ? '→' : '←'} ${(e.spec.wind.abs() / 40).round()}/5',
                    style: Desk.label(14, theme: t)),
              ),
            Expanded(
              child: GestureDetector(
                onPanStart: (d) {
                  if (e.isOver) return;
                  e.beginAim();
                },
                onPanUpdate: (d) {
                  e.addAim(d.delta);
                },
                onPanEnd: (_) => e.release(),
                onPanCancel: () => e.cancelAim(),
                child: LayoutBuilder(builder: (ctx, box) {
                  final size = box.biggest;
                  return CustomPaint(
                    size: size,
                    painter: _CourtPainter(
                      theme: t,
                      engine: e,
                      paperStyle: widget.settings.paperStyle,
                      binStyle: widget.settings.binStyle,
                      deskStyle: widget.settings.deskStyle,
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  e.isOver
                      ? 'Done!'
                      : e.isPaused
                          ? 'Paused…'
                          : e.announcement,
                  key: ValueKey(e.announcement),
                  textAlign: TextAlign.center,
                  style: Desk.body(15, theme: t)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(double s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).floor().toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Widget _chip(DeskThemeDef t, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: t.chipBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: Desk.body(10, theme: t, color: t.muted)),
          Text(value,
              style: Desk.display(15, theme: t)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// The classroom court: warm wall, wooden desk with grain, physical bin,
/// crumpled paper ball, slingshot band + predicted flight dots, wind streaks,
/// and floating score popups.
class _CourtPainter extends CustomPainter {
  final DeskThemeDef theme;
  final PaperFlickEngine engine;
  final int paperStyle;
  final int binStyle;
  final int deskStyle;

  _CourtPainter({
    required this.theme,
    required this.engine,
    required this.paperStyle,
    required this.binStyle,
    required this.deskStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final desk = _deskColors();
    // Desk surface fills the whole court; wall peeks above the top edge.
    _paintDesk(canvas, size, desk);
    _paintWind(canvas, size);
    _paintBin(canvas, size);
    _paintBall(canvas, size);
    _paintAim(canvas, size);
    _paintPopups(canvas, size);
  }

  (Color, Color) _deskColors() {
    final p = DeskStyles.surfaceTint(deskStyle);
    if (p != null) return p;
    return (theme.deskLight, theme.deskDark);
  }

  void _paintDesk(Canvas canvas, Size size, (Color, Color) desk) {
    // Warm gradient desk surface.
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              desk.$1,
              Color.lerp(desk.$1, desk.$2, 0.55)!,
            ],
          ).createShader(rect));
    if (deskStyle == 5) {
      // Checkered desk: subtle checkerboard.
      const n = 7;
      final cw = size.width / n;
      final ch = size.height / n;
      final p = Paint()..color = Colors.black.withValues(alpha: 0.08);
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if ((i + j) % 2 == 0) {
            canvas.drawRect(Rect.fromLTWH(i * cw, j * ch, cw, ch), p);
          }
        }
      }
    } else {
      // Wood grain: soft horizontal streaks.
      final grain = Paint()
        ..color = desk.$2.withValues(alpha: 0.35)
        ..strokeWidth = 2;
      for (int i = 0; i < 9; i++) {
        final y = size.height * (0.08 + i * 0.11);
        canvas.drawLine(Offset(0, y), Offset(size.width, y + 6), grain);
      }
    }
    // Desk edge shadow at the very bottom.
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 14, size.width, 14),
        Paint()..color = Colors.black.withValues(alpha: 0.18));
  }

  void _paintWind(Canvas canvas, Size size) {
    final w = engine.spec.wind;
    if (w.abs() < 1 || engine.isOver) return;
    final dir = w > 0 ? 1.0 : -1.0;
    final strength = (w.abs() / 200).clamp(0.2, 1.0);
    final paint = Paint()
      ..color = theme.accent.withValues(alpha: 0.28 * strength)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.15 + i * 0.13);
      final speed = 120 + strength * 160;
      var x = ((t * speed + i * 170) % (size.width + 160)) - 80;
      if (dir < 0) x = size.width - x;
      final len = 40 + strength * 50;
      canvas.drawLine(Offset(x, y), Offset(x - dir * len, y), paint);
      // arrowhead
      canvas.drawLine(
          Offset(x, y),
          Offset(x - dir * 10, y - 6),
          paint..strokeWidth = 2.5);
      canvas.drawLine(
          Offset(x, y), Offset(x - dir * 10, y + 6), paint);
    }
  }

  void _paintBin(Canvas canvas, Size size) {
    final bx = engine.binXNow() * size.width;
    final by = engine.spec.binY * size.height;
    final bw = engine.spec.binHalf * 2 * size.width;
    final bh = size.height * 0.10;

    final tint = BinStyles.bodyTint(binStyle);
    final body = tint ?? theme.binColor;
    final dark = tint != null
        ? Color.lerp(tint, Colors.black, 0.3)!
        : theme.binDark;
    final rim = theme.binRim;

    // Back inner shadow (pseudo-3D depth).
    final inner = Path()
      ..moveTo(bx - bw / 2, by)
      ..lineTo(bx + bw / 2, by)
      ..lineTo(bx + bw / 2 - 10, by + 14)
      ..lineTo(bx - bw / 2 + 10, by + 14)
      ..close();
    canvas.drawPath(inner, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Body trapezoid.
    final path = Path()
      ..moveTo(bx - bw / 2, by)
      ..lineTo(bx + bw / 2, by)
      ..lineTo(bx + bw / 2 - 12, by + bh)
      ..lineTo(bx - bw / 2 + 12, by + bh)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [dark, body, dark],
          ).createShader(Rect.fromLTWH(bx - bw / 2, by, bw, bh)));

    if (binStyle == 0 || binStyle == 2) {
      // Wire mesh / metal slats: vertical + horizontal weave lines.
      final mesh = Paint()
        ..color = rim.withValues(alpha: 0.85)
        ..strokeWidth = 1.6;
      for (int i = 1; i < 7; i++) {
        final x = bx - bw / 2 + (bw * i / 7);
        canvas.drawLine(
            Offset(x, by + 4), Offset(x + (i - 3.5) * 3, by + bh - 4), mesh);
      }
      for (int i = 1; i < 4; i++) {
        final y = by + (bh * i / 4);
        canvas.drawLine(Offset(bx - bw / 2 + 6, y),
            Offset(bx + bw / 2 - 6, y), mesh);
      }
    } else {
      // Solid bins: side shading for roundness + a front highlight.
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = dark.withValues(alpha: 0.7));
      canvas.drawLine(
          Offset(bx - bw / 4, by + 8),
          Offset(bx - bw / 4 + 4, by + bh - 10),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
    }

    // Rim: thick rounded lip with highlight (the target reads clearly).
    canvas.drawLine(
        Offset(bx - bw / 2 - 4, by),
        Offset(bx + bw / 2 + 4, by),
        Paint()
          ..color = rim
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(bx - bw / 2 - 4, by - 2),
        Offset(bx + bw / 2 + 4, by - 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    // Bin shadow on the desk.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bx, by + bh + 10),
            width: bw * 1.15,
            height: 14),
        Paint()..color = Colors.black.withValues(alpha: 0.22));

    if (engine.spec.moving && !engine.isOver) {
      final tp = TextPainter(
          text: TextSpan(
              text: 'moving!',
              style: TextStyle(
                  color: theme.text.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(bx - tp.width / 2, by + bh + 18));
    }
  }

  void _paintBall(Canvas canvas, Size size) {
    if (engine.lastWasScore) return; // ball is in the bin
    final bp = Offset(
        engine.pos.dx * size.width, engine.pos.dy * size.height);
    final r = PaperFlickEngine.ballR * size.width + 2;

    // Drop shadow on the desk (scales with height — pseudo-3D).
    final h = (0.97 - engine.pos.dy).clamp(0.0, 1.0);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bp.dx, size.height * 0.97 - 2),
            width: r * 2.2 * (1 - h * 0.4),
            height: 8 * (1 - h * 0.4)),
        Paint()..color = Colors.black.withValues(alpha: 0.20 * (1 - h * 0.5)));

    // Ball body: paper tint with a light-side highlight.
    final base = Color.lerp(
        theme.paperTint, PaperStyles.tint(paperStyle), 0.6)!;
    canvas.drawCircle(bp, r, Paint()..color = base);
    canvas.drawCircle(
        bp + Offset(-r * 0.3, -r * 0.35),
        r * 0.55,
        Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.drawCircle(
        bp,
        r,
        Paint()
          ..color = theme.paperShadow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Paper-style print.
    final print = Paint()
      ..color = theme.muted.withValues(alpha: 0.75)
      ..strokeWidth = 1.4;
    if (paperStyle == 1) {
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(bp + Offset(-r * 0.8, i * r * 0.45),
            bp + Offset(r * 0.8, i * r * 0.45), print);
      }
    } else if (paperStyle == 2) {
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(bp + Offset(-r * 0.8, i * r * 0.45),
            bp + Offset(r * 0.8, i * r * 0.45), print);
        canvas.drawLine(bp + Offset(i * r * 0.45, -r * 0.8),
            bp + Offset(i * r * 0.45, r * 0.8), print);
      }
    } else if (paperStyle == 3) {
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(bp + Offset(-r * 0.8, i * r * 0.45),
            bp + Offset(r * 0.8, i * r * 0.45),
            print..color = const Color(0xFFB0563A).withValues(alpha: 0.6));
      }
    } else if (paperStyle == 7) {
      canvas.drawCircle(bp + Offset(-r * 0.3, -r * 0.2), 2.2, print);
      canvas.drawCircle(bp + Offset(r * 0.35, r * 0.25), 2.2, print);
      canvas.drawCircle(bp + Offset(r * 0.1, -r * 0.45), 1.8, print);
    }
    // Crumple creases.
    final crease = Paint()
      ..color = theme.paperShadow.withValues(alpha: 0.9)
      ..strokeWidth = 1.6;
    canvas.drawLine(bp + Offset(-r * 0.55, -r * 0.1),
        bp + Offset(r * 0.1, r * 0.5), crease);
    canvas.drawLine(bp + Offset(r * 0.2, -r * 0.6),
        bp + Offset(r * 0.55, r * 0.15), crease);
    canvas.drawLine(bp + Offset(-r * 0.15, r * 0.15),
        bp + Offset(r * 0.5, -r * 0.25), crease);
  }

  void _paintAim(Canvas canvas, Size size) {
    if (!engine.aimingNow ||
        engine.phase != FlickPhase.aiming ||
        engine.isOver) {
      return;
    }
    final bp = Offset(
        engine.pos.dx * size.width, engine.pos.dy * size.height);
    final pull = bp + engine.aimVecPx;
    // Slingshot band.
    canvas.drawLine(
        bp,
        pull,
        Paint()
          ..color = theme.accent
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        pull,
        10,
        Paint()
          ..color = theme.accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // Predicted trajectory dots (same math as the engine launch).
    final scale = size.width / PaperFlickEngine.refPx;
    var p = bp;
    var v = Offset(-engine.aimVecPx.dx * scale * 6.0,
        -engine.aimVecPx.dy * scale * 6.0);
    final dot = Paint()..color = theme.accent.withValues(alpha: 0.75);
    const dt = 0.055;
    for (int i = 0; i < 18; i++) {
      v += Offset(engine.spec.wind / PaperFlickEngine.refPx * size.width,
              engine.spec.gravity / PaperFlickEngine.refPx * size.width) *
          dt;
      p += v * dt;
      if (p.dy > size.height * 0.97 || p.dx < 0 || p.dx > size.width) break;
      canvas.drawCircle(p, 3.4 - i * 0.1, dot);
    }
  }

  void _paintPopups(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;
    const life = 1300;
    for (final pop in engine.popups) {
      final age = now - pop.bornAt;
      if (age > life) continue;
      final t = age / life;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final p = Offset(pop.pos.dx * size.width,
          (pop.pos.dy - t * 0.09) * size.height);
      final tp = TextPainter(
          text: TextSpan(
              text: '+${pop.points}',
              style: TextStyle(
                fontSize: 20 + (1 - t) * 6,
                fontWeight: FontWeight.w900,
                color: theme.accent.withValues(alpha: alpha),
                shadows: [
                  Shadow(
                      color: Colors.black.withValues(alpha: 0.4 * alpha),
                      offset: const Offset(0, 2),
                      blurRadius: 4),
                ],
              )),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
    // Prune dead popups (cheap, once in a while).
    if (engine.popups.isNotEmpty &&
        now - engine.popups.first.bornAt > life * 2) {
      engine.popups.removeWhere((p) => now - p.bornAt > life);
    }
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) => true;
}
