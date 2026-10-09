import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/classroom_themes.dart';

/// Rename dialog for the player profile.
///
/// Persistence contract (hard rule):
/// - NEVER SharedPreferences.setStringList for names.
/// - Saves on EVERY keystroke via [FlickSettings.setPlayerNameLive].
/// - Commits on focus loss via [FlickSettings.commitPlayerName].
/// - Cancelling restores the value the dialog opened with.
Future<void> showFlickNameEditor({
  required BuildContext context,
  required FlickAudio audio,
  required FlickSettings settings,
}) async {
  final theme = DeskThemes.byId(settings.themeId, custom: settings.customTheme);
  final original = settings.playerNameRaw;
  final ctrl = TextEditingController(text: original);
  final focus = FocusNode();

  void commit() => settings.commitPlayerName();

  focus.addListener(() {
    if (!focus.hasFocus) commit(); // commit on focus loss
  });

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.accent, width: 2)),
      title: Text('Your name', style: Desk.display(20, theme: theme)),
      content: TextField(
        controller: ctrl,
        focusNode: focus,
        maxLength: 16,
        autofocus: true,
        style: Desk.body(17, theme: theme),
        decoration: InputDecoration(
          hintText: 'e.g. Desk Sharpshooter',
          hintStyle: Desk.body(15, theme: theme, color: theme.muted),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accent, width: 2)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accentDark, width: 2)),
        ),
        onChanged: (v) => settings.setPlayerNameLive(v), // every keystroke
        onSubmitted: (_) => Navigator.of(ctx).pop(true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: Desk.body(15, theme: theme)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Save', style: Desk.label(15, theme: theme)),
        ),
      ],
    ),
  ).then((saved) async {
    focus.dispose();
    ctrl.dispose();
    if (saved == true) {
      audio.click();
      await settings.commitPlayerName();
    } else {
      // Cancelled: put back exactly what was there before.
      await settings.revertPlayerName(original);
    }
  });
}
