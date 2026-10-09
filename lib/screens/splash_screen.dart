import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/classroom_themes.dart';
import 'menu_screen.dart';

/// Launch splash in two beats (one screen, no separate route):
/// 1. Company moment — the official WAJIHA logo (copied unchanged).
/// 2. Game splash — logo + name + animated loading line + "Credits: WAJIHA".
class SplashScreen extends StatefulWidget {
  final FlickAudio audio;
  final FlickSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _showGameSplash = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Beat 1: company moment — pre-warm audio while the logo shows.
    widget.audio.prewarm();
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    // Beat 2: game splash — start menu music under the loading line.
    setState(() => _showGameSplash = true);
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = DeskThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: _showGameSplash
          ? _GameSplash(theme: theme, loader: _loader)
          : _CompanySplash(theme: theme),
    );
  }
}

/// Company moment: the official WAJIHA winged-W logo, shown unchanged.
class _CompanySplash extends StatelessWidget {
  final DeskThemeDef theme;
  const _CompanySplash({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'WAJIHA',
              style: Desk.display(30, theme: theme)
                  .copyWith(color: Colors.white, letterSpacing: 8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final DeskThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Desk.backdrop(
      theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/paperflick_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Paper Flick', style: Desk.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'CRUMPLE · AIM · SWISH',
              style: Desk.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.25),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: theme.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Crumpling paper…' : 'Ready!',
                      style: Desk.body(13,
                          theme: theme,
                          color: theme.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Desk.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
