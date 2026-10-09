import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/classroom_themes.dart';
import '../widgets/name_editor.dart';

/// Paper Flick settings: audio toggles + volume, player name, stats.
class SettingsScreen extends StatefulWidget {
  final FlickAudio audio;
  final FlickSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DeskThemeDef get _t =>
      DeskThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  void _editName() => showFlickNameEditor(
        context: context,
        audio: widget.audio,
        settings: widget.settings,
      );

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final a = widget.audio;
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
              a.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Desk.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _row(t, 'Your name', s.playerName, Icons.edit, _editName),
                _toggle(t, 'Music', s.musicOn, (v) {
                  a.click();
                  s.setMusic(v);
                  a.configure(musicOn: v, sfxOn: s.sfxOn, volume: s.volume);
                  if (v) {
                    a.startMenuMusic();
                  } else {
                    a.stopMusic();
                  }
                }),
                _toggle(t, 'Sound effects', s.sfxOn, (v) {
                  s.setSfx(v);
                  a.configure(musicOn: s.musicOn, sfxOn: v, volume: s.volume);
                  if (v) a.click();
                }),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: Desk.cardDeco(t, radius: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Volume', style: Desk.body(16, theme: t)),
                      Slider(
                        value: s.volume,
                        activeColor: t.accent,
                        inactiveColor: t.chipBg,
                        onChanged: (v) {
                          s.setVolume(v);
                          a.configure(
                              musicOn: s.musicOn,
                              sfxOn: s.sfxOn,
                              volume: v);
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: Desk.cardDeco(t, radius: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Career stats', style: Desk.label(13, theme: t)),
                      const SizedBox(height: 8),
                      _stat(t, 'Games played', '${s.gamesPlayed}'),
                      _stat(t, 'Total baskets', '${s.totalMakes}'),
                      _stat(t, 'Best score', '${s.bestScore}'),
                      _stat(t, 'Best streak', '${s.bestStreak}'),
                      _stat(t, 'Best level', '${s.bestLevel}'),
                    ],
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

  Widget _row(DeskThemeDef t, String label, String value, IconData icon,
      VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: Desk.cardDeco(t, radius: 14),
      child: ListTile(
        title: Text(label, style: Desk.body(16, theme: t)),
        subtitle: Text(value, style: Desk.body(13, theme: t, color: t.muted)),
        trailing: Icon(icon, color: t.accent),
        onTap: onTap,
      ),
    );
  }

  Widget _toggle(
      DeskThemeDef t, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: Desk.cardDeco(t, radius: 14),
      child: SwitchListTile(
        title: Text(label, style: Desk.body(16, theme: t)),
        value: value,
        activeThumbColor: t.accent,
        onChanged: onChanged,
      ),
    );
  }

  Widget _stat(DeskThemeDef t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Desk.body(14, theme: t, color: t.muted)),
          Text(value,
              style:
                  Desk.body(14, theme: t).copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
