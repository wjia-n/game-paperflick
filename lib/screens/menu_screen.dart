import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/paperflick_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/classroom_themes.dart';
import '../widgets/name_editor.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Paper Flick main menu: mode + difficulty, player name, theme/paper/bin/
/// desk pickers, Pro, share/rate/settings, stats, how-to.
class MenuScreen extends StatefulWidget {
  final FlickAudio audio;
  final FlickSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final StoreService _store;

  FlickAudio get _a => widget.audio;
  FlickSettings get _s => widget.settings;

  DeskThemeDef get _t =>
      DeskThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    _store = StoreService();
    _store.init();
    _store.proPurchased.addListener(_onPro);
    _store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      _s.setPro(true);
      _store.proPurchased.value = false;
      _a.win();
      setState(() {});
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    _a.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Desk.body(15, theme: _t)),
        backgroundColor: _t.accentDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    _a.gameStart();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        audio: _a,
        settings: _s,
        mode: FlickMode.values[_s.mode],
        difficulty: FlickDifficulty.values[_s.difficulty],
        store: _store,
      ),
    ))
        .then((_) {
      if (mounted) _a.startMenuMusic();
    });
  }

  Future<void> _editName() => showFlickNameEditor(
        context: context, audio: _a, settings: _s);

  void _showHowTo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _t.accent, width: 2)),
        title: Text('How to Play', style: Desk.display(20, theme: _t)),
        content: SingleChildScrollView(
          child: Text(
            '• Press and DRAG BACK from anywhere to pull the paper ball.\n'
            '• Release to FLICK it toward the bin!\n'
            '• The dotted line shows your flight path — watch the WIND 💨.\n'
            '• Land it in the bin to score. 3 balls per level.\n'
            '• Streaks build bonus points. First-try makes earn +25.\n'
            '• Later levels: stronger wind and a MOVING bin!\n\n'
            'Modes:\n'
            '• Level Run — 20 levels, beat them all.\n'
            '• Endless — how far can your arm take you?\n'
            '• Score Attack — 60 seconds, unlimited balls!',
            style: Desk.body(15, theme: _t),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _a.click();
              Navigator.of(ctx).pop();
            },
            child: Text('Got it!', style: Desk.label(15, theme: _t)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = _s;
    return Desk.backdrop(
      t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: logo + name + PRO badge.
                  Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: t.accent, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              offset: const Offset(0, 5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/paperflick_logo.png',
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paper Flick',
                                style: Desk.display(30, theme: t)),
                            Text('CRUMPLE · AIM · SWISH',
                                style: Desk.label(11, theme: t)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _editName,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(s.playerName,
                                        style: Desk.body(15,
                                            theme: t, color: t.muted),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit,
                                      size: 14, color: t.accent),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (s.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: t.accent.withValues(alpha: 0.25),
                            border: Border.all(color: t.accent),
                          ),
                          child: Text('✦ PRO',
                              style: Desk.label(12, theme: t)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Big play button.
                  _WoodButton(
                    theme: t,
                    label: '▶  FLICK NOW',
                    onTap: _play,
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    theme: t,
                    title: 'Mode',
                    child: Row(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Expanded(
                            child: _PickChip(
                              theme: t,
                              label: const ['🏁 Levels', '♾️ Endless', '⏱️ Attack'][i],
                              selected: s.mode == i,
                              onTap: () {
                                _a.click();
                                s.setMode(i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    theme: t,
                    title: 'Difficulty',
                    child: Row(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Expanded(
                            child: _PickChip(
                              theme: t,
                              label: const ['😌 Casual', '💪 Skilled', '🤯 Trickshot'][i],
                              locked: i == 2 && !s.isPro,
                              selected: s.difficulty == i,
                              onTap: () {
                                _a.click();
                                if (i == 2 && !s.isPro) {
                                  _openPro();
                                } else {
                                  s.setDifficulty(i);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    theme: t,
                    title: 'Desk Theme',
                    child: _StyleGrid(
                      theme: t,
                      count: DeskThemes.all.length + 1,
                      selected: s.themeId == 'custom'
                          ? DeskThemes.all.length
                          : DeskThemes.all
                              .indexWhere((e) => e.id == s.themeId),
                      emojiFor: (i) => i < DeskThemes.all.length
                          ? _themeEmoji(i)
                          : '🎨',
                      labelFor: (i) => i < DeskThemes.all.length
                          ? DeskThemes.all[i].name
                          : 'My Creation',
                      lockedFor: (i) => i < DeskThemes.all.length
                          ? DeskThemes.all[i].pro
                          : true,
                      onTap: (i) {
                        _a.click();
                        if (i < DeskThemes.all.length) {
                          final id = DeskThemes.all[i].id;
                          if (DeskThemes.isProTheme(id) && !s.isPro) {
                            _openPro();
                          } else {
                            s.setTheme(id);
                          }
                        } else if (s.isPro) {
                          s.setTheme('custom');
                        } else {
                          _openPro();
                        }
                      },
                      onEdit: (i) {
                        if (i == DeskThemes.all.length && s.isPro) {
                          _openCustomTheme();
                        }
                      },
                      swatchFor: (i) => i < DeskThemes.all.length
                          ? DeskThemes.all[i].accent
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    theme: t,
                    title: 'Paper Ball',
                    child: _StyleGrid(
                      theme: t,
                      count: PaperStyles.names.length,
                      selected: s.paperStyle,
                      emojiFor: (i) => PaperStyles.emojis[i],
                      labelFor: (i) => PaperStyles.names[i],
                      lockedFor: (i) => PaperStyles.isPro(i),
                      onTap: (i) {
                        _a.click();
                        if (PaperStyles.isPro(i) && !s.isPro) {
                          _openPro();
                        } else {
                          s.setPaperStyle(i);
                        }
                      },
                      swatchFor: (i) => PaperStyles.tint(i),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    theme: t,
                    title: 'Bin',
                    child: _StyleGrid(
                      theme: t,
                      count: BinStyles.names.length,
                      selected: s.binStyle,
                      emojiFor: (i) => BinStyles.emojis[i],
                      labelFor: (i) => BinStyles.names[i],
                      lockedFor: (i) => BinStyles.isPro(i),
                      onTap: (i) {
                        _a.click();
                        if (BinStyles.isPro(i) && !s.isPro) {
                          _openPro();
                        } else {
                          s.setBinStyle(i);
                        }
                      },
                      swatchFor: (i) => BinStyles.bodyTint(i),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    theme: t,
                    title: 'Desk Surface',
                    child: _StyleGrid(
                      theme: t,
                      count: DeskStyles.names.length,
                      selected: s.deskStyle,
                      emojiFor: (i) => DeskStyles.emojis[i],
                      labelFor: (i) => DeskStyles.names[i],
                      lockedFor: (i) => DeskStyles.isPro(i),
                      onTap: (i) {
                        _a.click();
                        if (DeskStyles.isPro(i) && !s.isPro) {
                          _openPro();
                        } else {
                          s.setDeskStyle(i);
                        }
                      },
                      swatchFor: (i) {
                        final p = DeskStyles.surfaceTint(i);
                        return p?.$1;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats strip.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: Desk.cardDeco(t, radius: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(theme: t, label: 'Best score', value: '${s.bestScore}'),
                        _Stat(theme: t, label: 'Makes', value: '${s.totalMakes}'),
                        _Stat(theme: t, label: 'Best streak', value: '${s.bestStreak}'),
                        _Stat(theme: t, label: 'Best level', value: '${s.bestLevel}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pro banner.
                  if (!s.isPro)
                    GestureDetector(
                      onTap: _openPro,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              t.accent,
                              t.accentDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('✦', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Go PRO: all themes, Trickshot mode, custom creator',
                                style: Desk.body(14,
                                    theme: t,
                                    color: Colors.white)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  // Icon row: share / rate / settings / how-to.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          _a.click();
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Flick paper balls into the bin with me! https://play.google.com/store/apps/details?id=com.gameswajiha.paperflick',
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          _a.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          _a.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: _a,
                              settings: s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to',
                        onTap: () {
                          _a.click();
                          _showHowTo();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPro() {
    _a.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => ProScreen(audio: _a, settings: _s, store: _store),
    ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openCustomTheme() {
    _a.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => CustomThemeScreen(audio: _a, settings: _s),
    ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  static String _themeEmoji(int i) => const [
        '🏫', '🌙', '☀️', '🕯️', '🏭', '🌧️', '🍂', '🌿', '🕰️', '🌅', '🧱', '🌲', '🌹',
        '🌌'
      ][i.clamp(0, 13)];
}

class _WoodButton extends StatelessWidget {
  final DeskThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _WoodButton(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: Desk.buttonDeco(theme),
        child: Text(label,
            style: Desk.display(20, theme: theme)
                .copyWith(color: Colors.white, letterSpacing: 1.5)),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final DeskThemeDef theme;
  final String title;
  final Widget child;
  const _Section(
      {required this.theme, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: Desk.cardDeco(theme, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Desk.label(13, theme: theme)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  final DeskThemeDef theme;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _PickChip({
    required this.theme,
    required this.label,
    required this.selected,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.accent
              : theme.chipBg.withValues(alpha: locked ? 0.6 : 1.0),
          border: Border.all(
              color: selected ? theme.accentDark : theme.muted, width: 2),
        ),
        child: Text(
          locked ? '🔒 ${label.split(' ').last}' : label,
          textAlign: TextAlign.center,
          style: Desk.body(13, theme: theme, color: selected ? Colors.white : theme.text)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StyleGrid extends StatelessWidget {
  final DeskThemeDef theme;
  final int count;
  final int selected;
  final String Function(int) emojiFor;
  final String Function(int) labelFor;
  final bool Function(int) lockedFor;
  final void Function(int) onTap;
  final void Function(int)? onEdit;
  final Color? Function(int) swatchFor;

  const _StyleGrid({
    required this.theme,
    required this.count,
    required this.selected,
    required this.emojiFor,
    required this.labelFor,
    required this.lockedFor,
    required this.onTap,
    this.onEdit,
    required this.swatchFor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: count,
      itemBuilder: (_, i) {
        final sel = i == selected;
        final locked = lockedFor(i);
        final swatch = swatchFor(i);
        return GestureDetector(
          onTap: () => onTap(i),
          onLongPress:
              onEdit != null && sel ? () => onEdit!(i) : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: sel
                  ? theme.accent.withValues(alpha: 0.35)
                  : theme.chipBg.withValues(alpha: locked ? 0.55 : 1.0),
              border: Border.all(
                  color: sel ? theme.accent : theme.muted.withValues(alpha: 0.6),
                  width: sel ? 2.5 : 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (swatch != null)
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.muted.withValues(alpha: 0.7)),
                        ),
                      )
                    else
                      Text(emojiFor(i),
                          style: const TextStyle(fontSize: 26)),
                    if (locked)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Text('🔒',
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    labelFor(i),
                    style: Desk.body(9, theme: theme)
                        .copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final DeskThemeDef theme;
  final String label;
  final String value;
  const _Stat({required this.theme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Desk.display(18, theme: theme)),
        Text(label,
            style: Desk.body(10, theme: theme, color: theme.muted)),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final DeskThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.chipBg,
              border: Border.all(color: theme.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, color: theme.accent, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: Desk.body(11, theme: theme, color: theme.muted)),
        ],
      ),
    );
  }
}
