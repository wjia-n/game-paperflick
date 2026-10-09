import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Paper Flick engine: owns ALL game state, phases, timers and physics.
///
/// Phases: [FlickPhase.aiming] -> [flying] -> [celebrating] -> [aiming] ...
/// with [levelBreak] between levels and [gameOver] at the end. Every transient
/// phase (flying, celebrating, levelBreak) is entered with an explicit
/// deadline owned by the engine. A watchdog timer fires every 500ms and
/// force-advances any phase found past its deadline without a live timer —
/// stuck states are impossible by construction. The UI only renders and
/// forwards input; it never owns game flow.
enum FlickPhase { aiming, flying, celebrating, levelBreak, gameOver }

/// 0 = level run (20 levels), 1 = endless, 2 = score attack (60s).
enum FlickMode { levelRun, endless, scoreAttack }

/// 0 = casual, 1 = skilled, 2 = trickshot (Pro).
enum FlickDifficulty { casual, skilled, trickshot }

/// Per-level challenge spec. Deterministic from (level, difficulty, mode).
class LevelSpec {
  final double binX; // 0..1
  final double binY; // 0..1 from top
  final double wind; // px/s^2 at the 800px reference scale
  final bool moving;
  final double moveAmp; // fraction of width
  final double moveSpeed;
  final double binHalf; // bin mouth half-width, fraction of width
  final double gravity; // px/s^2 at the 800px reference scale

  const LevelSpec({
    required this.binX,
    required this.binY,
    required this.wind,
    required this.moving,
    required this.moveAmp,
    required this.moveSpeed,
    required this.binHalf,
    required this.gravity,
  });
}

/// Sound/event hooks the engine fires; the screen wires them to audio.
class FlickCallbacks {
  final VoidCallback onFlick;
  final VoidCallback onSwish;
  final VoidCallback onRim;
  final VoidCallback onBounce;
  final VoidCallback onInvalid;
  final VoidCallback onLevelUp;
  final VoidCallback onWin;
  final VoidCallback onLose;

  const FlickCallbacks({
    required this.onFlick,
    required this.onSwish,
    required this.onRim,
    required this.onBounce,
    required this.onInvalid,
    required this.onLevelUp,
    required this.onWin,
    required this.onLose,
  });
}

/// Score popup the UI animates over the bin.
class ScorePopup {
  final int id;
  final int points;
  final Offset pos; // fraction coords
  final int bornAt; // ms epoch
  ScorePopup(
      {required this.id, required this.points, required this.pos, required this.bornAt});
}

class PaperFlickEngine extends ChangeNotifier {
  PaperFlickEngine({
    required this.mode,
    required this.difficulty,
    required this.callbacks,
  });

  final FlickMode mode;
  final FlickDifficulty difficulty;
  final FlickCallbacks callbacks;

  static const double ballsPerLevel = 3;
  static const double startX = 0.5;
  static const double startY = 0.85;
  static const double maxDragPx = 220;
  static const double refPx = 800; // reference scale for physics
  static const double ballR = 0.016; // fraction of width

  // ------------------------------------------------------------- state
  FlickPhase phase = FlickPhase.aiming;
  int level = 1; // 1-based
  int ballsLeft = ballsPerLevel.toInt();
  int score = 0;
  int makes = 0;
  int attempts = 0;
  int streak = 0;
  int bestStreakRun = 0;
  bool lastWasScore = false;

  Offset pos = const Offset(startX, startY);
  Offset vel = Offset.zero;
  bool aimingNow = false;
  Offset aimVecPx = Offset.zero; // accumulated drag in px

  double timeLeft = 60; // score attack only
  String announcement = 'Drag back, release to flick!';

  List<ScorePopup> popups = [];
  int _popupId = 0;

  late LevelSpec spec;

  // ---------------------------------------------------------- timers/ticker
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _simTime = 0; // seconds, for moving bin
  DateTime? _lastStepWall; // last physics step (watchdog input)
  DateTime? _phaseDeadline; // engine-owned deadline for transient phases
  Timer? _watchdog;
  Timer? _phaseTimer; // engine-owned transition timer
  Timer? _attackTimer; // score-attack countdown
  bool _paused = false;
  DateTime? _pausedAt;
  Duration _pauseAccum = Duration.zero; // pause time within current phase
  bool _disposed = false;

  bool get isPaused => _paused;
  bool get isOver => phase == FlickPhase.gameOver;

  // ------------------------------------------------------- level generation
  /// Deterministic challenge spec. Same (level, difficulty, mode) always
  /// yields the same bin placement, wind and movement.
  static LevelSpec specFor(int level, FlickDifficulty diff, FlickMode m) {
    final rand = Random(level * 7919 + diff.index * 131 + m.index * 17 + 5);
    final tier = diff.index;
    // Base gravity scales gently with difficulty.
    final gravity = 1400.0 + tier * 100;

    // Bin placement: fair spread, never overlapping the spawn zone.
    final binX = 0.18 + rand.nextDouble() * 0.64;
    final binY = 0.14 + rand.nextDouble() * 0.20;

    // Wind: grows with level and difficulty.
    final windCap = [90.0, 150.0, 200.0][tier];
    final windStartLevel = [6, 2, 1][tier];
    double wind = 0;
    if (level >= windStartLevel) {
      final scale = ((level - windStartLevel + 3) / 10).clamp(0.3, 1.0);
      wind = (rand.nextDouble() * 2 - 1) * windCap * scale;
    }

    // Moving bin: later tiers start earlier, faster amplitude.
    final moveStartLevel = [12, 6, 3][tier];
    final moving = level >= moveStartLevel;
    final moveAmp = moving ? 0.14 + tier * 0.04 : 0.0;
    final moveSpeed = moving ? 1.2 + tier * 0.35 + level * 0.02 : 0.0;

    // Bin mouth shrinks at high levels / tiers.
    final shrink = (level > 12 ? (level - 12) * 0.0012 : 0) + tier * 0.004;
    final binHalf = (0.062 - shrink).clamp(0.038, 0.062);

    if (m == FlickMode.scoreAttack) {
      // Score attack: every make re-rolls a fresh mid-tier challenge.
      return LevelSpec(
        binX: binX,
        binY: binY,
        wind: (rand.nextDouble() * 2 - 1) * windCap * 0.7,
        moving: tier >= 1 && rand.nextDouble() < 0.5 + tier * 0.2,
        moveAmp: 0.14 + tier * 0.04,
        moveSpeed: 1.4 + tier * 0.4,
        binHalf: binHalf,
        gravity: gravity,
      );
    }

    return LevelSpec(
      binX: binX,
      binY: binY,
      wind: wind,
      moving: moving,
      moveAmp: moveAmp,
      moveSpeed: moveSpeed,
      binHalf: binHalf,
      gravity: gravity,
    );
  }

  // --------------------------------------------------------------- lifecycle
  /// The engine owns its own ticker; the screen hands over a TickerProvider.
  void attachTicker(TickerProvider vsync) {
    if (_ticker != null) return;
    _ticker = vsync.createTicker(_onTick)..start();
    _watchdog =
        Timer.periodic(const Duration(milliseconds: 500), (_) => _watchdogCheck());
  }

  void startNew() {
    level = 1;
    score = 0;
    makes = 0;
    attempts = 0;
    streak = 0;
    bestStreakRun = 0;
    ballsLeft = ballsPerLevel.toInt();
    timeLeft = 60;
    _pauseAccum = Duration.zero;
    _paused = false;
    spec = specFor(level, difficulty, mode);
    _enterAim('Level 1 — drag back, release to flick!');
    if (mode == FlickMode.scoreAttack) {
      _armAttackTimer();
    }
  }

  void _armAttackTimer() {
    _attackTimer?.cancel();
    _attackTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_paused || _disposed || phase == FlickPhase.gameOver) return;
      timeLeft -= 0.25;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _enterGameOver(win: makes > 0);
      }
      notifyListeners();
    });
  }

  // ------------------------------------------------------------- phase entry
  void _setPhase(FlickPhase p, {Duration? timeout}) {
    _phaseTimer?.cancel();
    phase = p;
    _pauseAccum = Duration.zero;
    _phaseDeadline =
        timeout == null ? null : DateTime.now().add(timeout);
  }

  void _enterAim(String msg) {
    pos = const Offset(startX, startY);
    vel = Offset.zero;
    aimingNow = false;
    aimVecPx = Offset.zero;
    lastWasScore = false;
    announcement = msg;
    _setPhase(FlickPhase.aiming); // aiming has NO timeout — player decides
    notifyListeners();
  }

  void _enterFlying() {
    attempts++;
    _setPhase(FlickPhase.flying, timeout: const Duration(seconds: 9));
    notifyListeners();
  }

  void _enterCelebrating({required bool scored}) {
    lastWasScore = scored;
    if (scored) {
      _setPhase(FlickPhase.celebrating,
          timeout: const Duration(milliseconds: 1400));
      _phaseTimer = Timer(const Duration(milliseconds: 950), () {
        if (_disposed || _paused) return;
        _afterBall(scored: true);
      });
    } else {
      _setPhase(FlickPhase.celebrating,
          timeout: const Duration(milliseconds: 1200));
      _phaseTimer = Timer(const Duration(milliseconds: 700), () {
        if (_disposed || _paused) return;
        _afterBall(scored: false);
      });
    }
    notifyListeners();
  }

  void _enterLevelBreak() {
    announcement = level >= _maxLevel
        ? 'Run complete!'
        : 'Level $level cleared — level ${level + 1} incoming!';
    _setPhase(FlickPhase.levelBreak, timeout: const Duration(seconds: 4));
    _phaseTimer = Timer(const Duration(milliseconds: 1400), () {
      if (_disposed || _paused) return;
      level++;
      ballsLeft = ballsPerLevel.toInt() +
          (mode == FlickMode.endless && level % 3 == 0 ? 1 : 0);
      spec = specFor(level, difficulty, mode);
      callbacks.onLevelUp();
      _enterAim(
          'Level $level — ${spec.moving ? 'the bin is MOVING! ' : ''}${spec.wind.abs() > 1 ? 'mind the wind!' : 'steady arm!'}');
    });
    notifyListeners();
  }

  void _enterGameOver({required bool win}) {
    _setPhase(FlickPhase.gameOver); // terminal — no timeout needed
    _attackTimer?.cancel();
    if (win) {
      callbacks.onWin();
      announcement = 'What a run! $score points!';
    } else {
      callbacks.onLose();
      announcement = 'The bin wins this one. Rematch?';
    }
    notifyListeners();
  }

  int get _maxLevel => mode == FlickMode.levelRun ? 20 : 1 << 30;

  /// Force-advance any transient phase found past its deadline. This is the
  /// backstop: even if a phase timer was lost (app jank, timer bug), the
  /// game can never sit frozen in flying/celebrating/levelBreak.
  void _watchdogCheck() {
    if (_disposed || _paused) return;
    if (_lastStepWall != null &&
        phase == FlickPhase.flying &&
        DateTime.now().difference(_lastStepWall!) >
            const Duration(milliseconds: 1500)) {
      // Physics stalled mid-flight: settle the ball safely.
      _forceEndBall(scored: false);
      return;
    }
    final dl = _phaseDeadline;
    if (dl != null && DateTime.now().isAfter(dl)) {
      switch (phase) {
        case FlickPhase.flying:
          _forceEndBall(scored: false);
          break;
        case FlickPhase.celebrating:
          _afterBall(scored: lastWasScore);
          break;
        case FlickPhase.levelBreak:
          _phaseTimer?.cancel();
          level++;
          ballsLeft = ballsPerLevel.toInt() +
              (mode == FlickMode.endless && level % 3 == 0 ? 1 : 0);
          spec = specFor(level, difficulty, mode);
          _enterAim('Level $level');
          break;
        case FlickPhase.aiming:
        case FlickPhase.gameOver:
          break;
      }
    }
  }

  void _forceEndBall({required bool scored}) {
    // Same path as a natural settle — never invents a score.
    _enterCelebrating(scored: scored);
  }

  // --------------------------------------------------------------- input
  void beginAim() {
    if (phase != FlickPhase.aiming || _paused) return;
    aimingNow = true;
    aimVecPx = Offset.zero;
    notifyListeners();
  }

  void addAim(Offset deltaPx) {
    if (!aimingNow || phase != FlickPhase.aiming) return;
    aimVecPx += deltaPx;
    final m = aimVecPx.distance;
    if (m > maxDragPx) aimVecPx = aimVecPx / m * maxDragPx;
    notifyListeners();
  }

  void cancelAim() {
    aimingNow = false;
    aimVecPx = Offset.zero;
    notifyListeners();
  }

  /// Release the drag: launch opposite to the pull. Too weak a pull is an
  /// invalid move — it stays in aim, never consumes a ball.
  void release() {
    if (phase != FlickPhase.aiming || !aimingNow || _paused) return;
    aimingNow = false;
    if (aimVecPx.distance < 22) {
      aimVecPx = Offset.zero;
      callbacks.onInvalid();
      announcement = 'Pull back further for a real flick!';
      notifyListeners();
      return;
    }
    vel = Offset(
      -aimVecPx.dx / refPx * 6.0,
      -aimVecPx.dy / refPx * 6.0,
    );
    aimVecPx = Offset.zero;
    callbacks.onFlick();
    _enterFlying();
  }

  // --------------------------------------------------------------- physics
  void _onTick(Duration now) {
    if (_disposed || _paused) {
      _lastTick = now;
      return;
    }
    final dt = min(0.05, (now - _lastTick).inMicroseconds / 1e6);
    _lastTick = now;
    _lastStepWall = DateTime.now();
    _simTime += dt;
    if (phase == FlickPhase.flying) {
      _step(dt);
    } else if (phase == FlickPhase.celebrating && !lastWasScore) {
      // Let a missed ball keep rolling to rest while we celebrate.
      _step(dt, settleOnly: true);
    }
    // Moving bin animates in every phase — the world stays alive.
    notifyListeners();
  }

  double binXNow() {
    if (!spec.moving) return spec.binX;
    return (spec.binX + spec.moveAmp * sin(_simTime * spec.moveSpeed))
        .clamp(0.12, 0.88);
  }

  void _step(double dt, {bool settleOnly = false}) {
    vel += Offset(spec.wind / refPx, spec.gravity / refPx) * dt;
    pos += vel * dt;
    final bx = binXNow();

    // Walls.
    if (pos.dx < 0.03) {
      pos = Offset(0.03, pos.dy);
      vel = Offset(-vel.dx * 0.4, vel.dy);
      callbacks.onBounce();
    }
    if (pos.dx > 0.97) {
      pos = Offset(0.97, pos.dy);
      vel = Offset(-vel.dx * 0.4, vel.dy);
      callbacks.onBounce();
    }
    if (pos.dy < 0.02) {
      pos = Offset(pos.dx, 0.02);
      vel = Offset(vel.dx, -vel.dy * 0.4);
      callbacks.onBounce();
    }

    if (!settleOnly) {
      // Bin mouth: falling into the mouth scores; clipping the rim clanks.
      final dx = (pos.dx - bx).abs();
      final dy = (pos.dy - spec.binY).abs();
      if (!lastWasScore &&
          vel.dy > 0 &&
          dy < 0.028 &&
          dx < spec.binHalf + ballR) {
        if (dx < spec.binHalf - 0.004) {
          _onScore(bx);
          return;
        } else {
          // Rim hit: metallic clank, deflect outward.
          callbacks.onRim();
          final side = pos.dx < bx ? -1.0 : 1.0;
          vel = Offset(side * vel.dx.abs() * 0.8 + side * 0.12, -vel.dy * 0.45);
          pos = Offset(bx + side * (spec.binHalf + ballR + 0.004), pos.dy);
        }
      }
    }

    // Floor.
    if (pos.dy > 0.97) {
      if (vel.dy.abs() < 0.28) {
        if (!settleOnly) _onMiss();
        return;
      }
      pos = Offset(pos.dx, 0.97);
      vel = Offset(vel.dx * 0.6, -vel.dy * 0.45);
      callbacks.onBounce();
    }
    // Out-of-bounds safety net.
    if (pos.dy > 1.25 || pos.dx < -0.2 || pos.dx > 1.2) {
      if (!settleOnly) _onMiss();
    }
  }

  void _onScore(double bx) {
    lastWasScore = true;
    makes++;
    streak++;
    if (streak > bestStreakRun) bestStreakRun = streak;
    final firstTry = ballsLeft == ballsPerLevel.toInt() &&
        mode != FlickMode.scoreAttack;
    final streakBonus = ((streak - 1) * 10).clamp(0, 100);
    final gained = 100 +
        streakBonus +
        (firstTry ? 25 : 0) +
        (mode == FlickMode.scoreAttack ? streak * 5 : 0);
    score += gained;
    popups.add(ScorePopup(
      id: ++_popupId,
      points: gained,
      pos: Offset(bx, spec.binY - 0.06),
      bornAt: DateTime.now().millisecondsSinceEpoch,
    ));
    announcement = streak >= 3 ? 'SWISH! $streak in a row!' : 'SWISH! +$gained';
    callbacks.onSwish();
    if (mode == FlickMode.scoreAttack) {
      // Fresh challenge after every make; ball respawns quickly.
      spec = specFor(level + makes, difficulty, mode);
      _setPhase(FlickPhase.celebrating,
          timeout: const Duration(milliseconds: 1200));
      _phaseTimer = Timer(const Duration(milliseconds: 550), () {
        if (_disposed || _paused) return;
        _enterAim(streak >= 2 ? 'On fire! $streak streak!' : 'Nice! Keep going!');
      });
      notifyListeners();
      return;
    }
    _enterCelebrating(scored: true);
  }

  void _onMiss() {
    streak = 0;
    announcement = 'Missed! ${ballsLeft - 1 > 0 ? 'Shake it off.' : 'Last ball gone.'}';
    _enterCelebrating(scored: false);
  }

  void _afterBall({required bool scored}) {
    if (_disposed || phase == FlickPhase.gameOver) return;
    if (mode == FlickMode.scoreAttack) {
      _enterAim('Keep flicking!');
      return;
    }
    ballsLeft--;
    if (ballsLeft <= 0) {
      if (level >= _maxLevel) {
        _enterGameOver(win: makes > 0);
      } else {
        _enterLevelBreak();
      }
    } else {
      _enterAim(scored
          ? (streak >= 2 ? '$streak in a row — stay hot!' : 'Nice shot!')
          : (ballsLeft == 1 ? 'Last ball — make it count!' : 'Shake it off, flick again.'));
    }
  }

  // ---------------------------------------------------------------- pause
  void pause() {
    if (_paused || _disposed) return;
    _paused = true;
    _pausedAt = DateTime.now();
    _ticker?.stop();
    notifyListeners();
  }

  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    if (_pausedAt != null) {
      final delta = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      // Push the deadline out by the paused duration.
      if (_phaseDeadline != null) {
        _phaseDeadline = _phaseDeadline!.add(delta);
      }
    }
    _ticker?.start();
    notifyListeners();
  }

  void restart() {
    _phaseTimer?.cancel();
    startNew();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.dispose();
    _watchdog?.cancel();
    _phaseTimer?.cancel();
    _attackTimer?.cancel();
    super.dispose();
  }
}
