import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/classroom_themes.dart';

/// Custom theme creator (PRO): pick the classroom colors, live preview.
class CustomThemeScreen extends StatefulWidget {
  final FlickAudio audio;
  final FlickSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  DeskThemeDef get _t => widget.settings.customTheme;

  static const _fields = [
    ('wallTop', 'Wall (top)'),
    ('wallBottom', 'Wall (bottom)'),
    ('deskLight', 'Desk (light)'),
    ('deskDark', 'Desk (dark)'),
    ('binColor', 'Bin (body)'),
    ('binDark', 'Bin (shade)'),
    ('paperTint', 'Paper'),
    ('accent', 'Accent'),
    ('accentDark', 'Accent (dark)'),
    ('text', 'Text'),
  ];

  // Warm, classroom-safe palette swatches.
  static const _palette = [
    0xFFF6ECD9, 0xFFE9D9BC, 0xFFC99A63, 0xFF9A6B3C, 0xFF3B2416,
    0xFFC0562F, 0xFF8F3A1E, 0xFFFDFBF4, 0xFF2E4038, 0xFF1E2C26,
    0xFF3F7FB5, 0xFF2A5A82, 0xFF2E8B66, 0xFF1C5E45, 0xFFD9A441,
    0xFFB5432A, 0xFF5E7E96, 0xFF3F6B5A, 0xFFF1E6C8, 0xFF1A1712,
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return Desk.backdrop(
      t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
          title: Text('My Creation', style: Desk.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                widget.audio.click();
                s.resetCustomColors();
                setState(() {});
              },
              child: Text('Reset', style: Desk.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Live preview strip.
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.wallTop, t.wallBottom, t.deskLight],
                      stops: const [0.0, 0.45, 0.46],
                    ),
                    border: Border.all(color: t.accent, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 40,
                        top: 62,
                        child: _miniBin(t),
                      ),
                      Positioned(
                        right: 40,
                        bottom: 18,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: t.paperTint,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: t.accent.withValues(alpha: 0.6),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: Center(
                          child: Text('Preview',
                              style: Desk.label(12, theme: t)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final f in _fields)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: Desk.cardDeco(t, radius: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color:
                                    Color(s.customColors[f.$1] ?? 0xFF000000),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        t.muted.withValues(alpha: 0.6)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(f.$2, style: Desk.body(15, theme: t)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in _palette)
                              GestureDetector(
                                onTap: () {
                                  widget.audio.click();
                                  s.setCustomColor(f.$1, c);
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(c),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: s.customColors[f.$1] == c
                                          ? t.accent
                                          : t.muted.withValues(alpha: 0.4),
                                      width: s.customColors[f.$1] == c
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    s.setTheme('custom');
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    decoration: Desk.buttonDeco(t),
                    child: Text('Use My Creation',
                        style: Desk.display(17, theme: t)
                            .copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBin(DeskThemeDef t) {
    return CustomPaint(
      size: const Size(64, 60),
      painter: _MiniBinPainter(theme: t),
    );
  }
}

class _MiniBinPainter extends CustomPainter {
  final DeskThemeDef theme;
  _MiniBinPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(6, 6)
      ..lineTo(size.width - 6, 6)
      ..lineTo(size.width - 12, size.height)
      ..lineTo(12, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = theme.binColor);
    canvas.drawLine(
        Offset(2, 6),
        Offset(size.width - 2, 6),
        Paint()
          ..color = theme.binDark
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
