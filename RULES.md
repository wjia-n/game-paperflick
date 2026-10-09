# Paper Flick — Rules

## 1. Objective
Flick a crumpled paper ball into the waste bin. Score points for every basket.
Modes: Level Run (beat 20 levels), Endless (survive as long as you can),
Score Attack (60 seconds, unlimited balls, maximize points).

## 2. Setup
- Player drags back anywhere on the court and releases to flick.
- The paper ball always starts at the bottom-center of the desk.
- Each level places the bin at a deterministic position with a wind value,
  and (at higher levels) the bin moves side to side.
- Level Run / Endless: 3 balls per level (Endless grants +1 ball every 3rd level).
- Score Attack: 60 seconds, unlimited balls.

## 3. Turn order
Single-player skill game — no turns. Each flick is one attempt.

## 4. Legal moves
- Press and drag back anywhere (up to 220px) to aim, then release to flick.
- The dotted line previews the flight path including wind and gravity.
- A pull shorter than 22px is rejected with feedback (no ball consumed).

## 5. Illegal moves
- Flicking while the ball is flying, while celebrating a basket, during a
  level break, while paused, or after game over — all ignored.
- A sub-22px pull is an invalid move: it stays in the aim phase, plays the
  invalid sound, and shows a hint. It never consumes a ball or advances state.

## 6. Captures
Not applicable (no opponents).

## 7. Special rules
- Wind pushes the ball sideways every frame; strength is shown (1–5) and as
  moving streaks on the court.
- A moving bin oscillates sinusoidally; its current position is what counts.
- Hitting the bin rim (not the mouth) plays a clank and deflects the ball.
- Streaks: consecutive baskets add +10 per streak level, capped at +100.
- First-try basket of a level: +25 bonus (Level Run / Endless).
- Score Attack: +5 extra per streak level; each basket re-rolls a fresh challenge.

## 8. Scoring
- Base: 100 points per basket.
- Streak bonus: (streak − 1) × 10, capped at +100.
- First-try bonus: +25 (Level Run / Endless only).
- Score Attack adds: streak × 5.
- A missed ball resets the streak to 0.

## 9. Winning conditions
- Level Run: complete all 20 levels. Any basket counts as a personal win;
  final score is the headline.
- Endless / Score Attack: there is no final win — the goal is the best score.

## 10. Draw conditions
Not applicable.

## 11. AI strategy
Not applicable (pure skill game, no opponents).

## 12. Edge cases
- Ball leaves the court (flicked wildly): counts as a miss, never a score.
- Ball comes to rest on the floor: counts as a miss after it settles.
- Physics stall (no step for 1.5s): the watchdog ends the ball as a miss.
- Phase timers are engine-owned; if any phase exceeds its deadline, the
  watchdog force-advances it (flying → miss, celebrating → next ball,
  level break → next level). No stuck states.
- Pause freezes physics, timers and countdown; resume shifts deadlines.
- Score Attack timer reaching 0 ends the run immediately, even mid-flight.

## 13. Test cases
- Determinism: `LevelSpec` for the same (level, difficulty, mode) is identical
  across calls (covered by unit test).
- Weak pull (< 22px): no ball consumed, still in aim phase.
- Falling into the bin mouth (vel.dy > 0, |dx| < half mouth): scores once.
- Clipping the rim: no score, clank, ball deflects.
- Ball resting on floor: miss, streak reset, ball consumed.
- Last ball of level 20 (Level Run): game over, not level break.
- Level break advances level and resets balls.
- Watchdog: a phase past its deadline force-advances.
