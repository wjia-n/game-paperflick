import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/classroom_themes.dart';

/// Persisted settings + stats for Paper Flick. Survives app restarts.
///
/// The player profile name is persisted as ONE JSON string. NEVER use a
/// StringList for it: Android's SharedPreferences stores StringLists as an
/// unordered StringSet, which scrambles order — even for a single-element
/// profile this rule keeps storage uniform and future-proof.
class FlickSettings extends ChangeNotifier {
  static const _kMusic = 'paperflick_music_on';
  static const _kSfx = 'paperflick_sfx_on';
  static const _kVolume = 'paperflick_volume';
  static const _kNamesJson = 'paperflick_player_names_json';
  static const _kNameJsonLegacy =
      'paperflick_player_name_json'; // old singular JSON key
  static const _kNameListLegacy =
      'paperflick_player_name'; // old unordered StringList key
  static const _kNameStrLegacy =
      'paperflick_player_name_str'; // old plain String key
  static const _kTheme = 'paperflick_theme_id';
  static const _kPaper = 'paperflick_paper_style';
  static const _kBin = 'paperflick_bin_style';
  static const _kDesk = 'paperflick_desk_style';
  static const _kDifficulty = 'paperflick_difficulty'; // 0 casual, 1 skilled, 2 trickshot
  static const _kMode = 'paperflick_mode'; // 0 level run, 1 endless, 2 score attack
  static const _kGames = 'paperflick_games_played';
  static const _kMakes = 'paperflick_total_makes';
  static const _kBestScore = 'paperflick_best_score';
  static const _kBestStreak = 'paperflick_best_streak';
  static const _kBestLevel = 'paperflick_best_level';
  static const _kIsPro = 'paperflick_is_pro';
  static const _kCustomPrefix = 'paperflick_custom_';

  static const defaultName = 'Player One';

  /// Encode the name list as ONE order-preserving JSON string.
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(String s) =>
      s.trim().isEmpty ? defaultName : s.trim();

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return [defaultName];
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        final names = d
            .whereType<String>()
            .map((s) => s.length > 16 ? s.substring(0, 16) : s)
            .toList();
        if (names.isNotEmpty) return names;
      } else if (d is String) {
        // Tolerate the very first schema (a bare JSON string).
        return [_cleanName(d)];
      }
    } catch (_) {}
    return [defaultName];
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  List<String> playerNames = [defaultName];

  /// Display name for the single profile slot (slot 0). Never blank.
  String get playerName {
    if (playerNames.isEmpty) return defaultName;
    final raw = playerNames.first;
    return raw.trim().isEmpty ? defaultName : raw;
  }

  /// Raw persisted value of the slot (may be mid-typing, e.g. empty).
  String get playerNameRaw =>
      playerNames.isEmpty ? defaultName : playerNames.first;
  String themeId = 'classroom';
  int paperStyle = 0;
  int binStyle = 0;
  int deskStyle = 0;
  int difficulty = 0; // casual default
  int mode = 0; // level run default
  int gamesPlayed = 0;
  int totalMakes = 0;
  int bestScore = 0;
  int bestStreak = 0;
  int bestLevel = 0;
  bool isPro = false;

  /// Custom theme color overrides (ARGB ints), applied over Classic Classroom.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'wallTop': 0xFFF6ECD9,
    'wallBottom': 0xFFE9D9BC,
    'deskLight': 0xFFC99A63,
    'deskDark': 0xFF9A6B3C,
    'binColor': 0xFF8A8F96,
    'binDark': 0xFF5F646B,
    'paperTint': 0xFFFDFBF4,
    'accent': 0xFFC0562F,
    'accentDark': 0xFF8F3A1E,
    'text': 0xFF3B2416,
  };

  DeskThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    final base = DeskThemes.all[0]; // Classic Classroom
    return DeskThemeDef(
      id: 'custom',
      name: 'My Creation',
      wallTop: c('wallTop'),
      wallBottom: c('wallBottom'),
      deskLight: c('deskLight'),
      deskDark: c('deskDark'),
      deskLine: Color(0xFF8A5F34),
      binColor: c('binColor'),
      binDark: c('binDark'),
      binRim: c('binDark'),
      paperTint: c('paperTint'),
      paperShadow: c('paperTint'),
      accent: c('accent'),
      accentDark: c('accentDark'),
      text: c('text'),
      muted: base.muted,
      card: base.card,
      chipBg: base.chipBg,
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Profile names: prefer the order-safe JSON key. Migrate legacy keys
    // once, in order: the old singular JSON key, the old unordered
    // StringList key (may already be scrambled), then the old plain
    // String key.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacyJson = p.getString(_kNameJsonLegacy);
      final legacyList = p.getStringList(_kNameListLegacy);
      final legacyStr = p.getString(_kNameStrLegacy);
      if (legacyJson != null) {
        playerNames = decodePlayerNames(legacyJson);
      } else if (legacyList != null && legacyList.isNotEmpty) {
        playerNames = [_cleanName(legacyList.first)];
      } else if (legacyStr != null && legacyStr.trim().isNotEmpty) {
        playerNames = [_cleanName(legacyStr)];
      } else {
        playerNames = [defaultName];
      }
    }
    themeId = p.getString(_kTheme) ?? 'classroom';
    paperStyle = (p.getInt(_kPaper) ?? 0).clamp(0, PaperStyles.names.length - 1);
    binStyle = (p.getInt(_kBin) ?? 0).clamp(0, BinStyles.names.length - 1);
    deskStyle = (p.getInt(_kDesk) ?? 0).clamp(0, DeskStyles.names.length - 1);
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 2);
    gamesPlayed = p.getInt(_kGames) ?? 0;
    totalMakes = p.getInt(_kMakes) ?? 0;
    bestScore = p.getInt(_kBestScore) ?? 0;
    bestStreak = p.getInt(_kBestStreak) ?? 0;
    bestLevel = p.getInt(_kBestLevel) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    // Drop every legacy name key for good.
    await p.remove(_kNameJsonLegacy);
    await p.remove(_kNameListLegacy);
    await p.remove(_kNameStrLegacy);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kPaper, paperStyle);
    await p.setInt(_kBin, binStyle);
    await p.setInt(_kDesk, deskStyle);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, mode);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kMakes, totalMakes);
    await p.setInt(_kBestScore, bestScore);
    await p.setInt(_kBestStreak, bestStreak);
    await p.setInt(_kBestLevel, bestLevel);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp Pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    // 'custom' is the Pro custom-theme creator and is not in the catalog's
    // isProTheme check, so it needs an explicit check.
    if (themeId == 'custom' || DeskThemes.isProTheme(themeId)) {
      themeId = 'classroom';
      changed = true;
    }
    if (PaperStyles.isPro(paperStyle)) {
      paperStyle = 0;
      changed = true;
    }
    if (BinStyles.isPro(binStyle)) {
      binStyle = 0;
      changed = true;
    }
    if (DeskStyles.isPro(deskStyle)) {
      deskStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1; // trickshot is a Pro feature
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Save-on-every-keystroke: called from the name field's onChanged.
  /// Stores the raw in-progress text so nothing is lost if the app dies
  /// mid-typing. Display code falls back to the default while blank.
  Future<void> setPlayerNameLive(String raw) async {
    final v = raw.length > 16 ? raw.substring(0, 16) : raw;
    playerNames = [v];
    notifyListeners();
    await _save();
  }

  /// Commit on focus loss / Save: trim and normalize; an empty field falls
  /// back to the default name.
  Future<void> commitPlayerName() async {
    playerNames = [_cleanName(playerNameRaw)];
    notifyListeners();
    await _save();
  }

  /// Restore a previous value (e.g. the rename dialog was cancelled).
  Future<void> revertPlayerName(String raw) async {
    playerNames = [raw];
    notifyListeners();
    await _save();
  }

  /// Explicit save (kept for callers that already validated).
  Future<void> setPlayerName(String name) async {
    playerNames = [_cleanName(name)];
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || DeskThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPaperStyle(int v) async {
    v = v.clamp(0, PaperStyles.names.length - 1);
    if (!isPro && PaperStyles.isPro(v)) return;
    paperStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBinStyle(int v) async {
    v = v.clamp(0, BinStyles.names.length - 1);
    if (!isPro && BinStyles.isPro(v)) return;
    binStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDeskStyle(int v) async {
    v = v.clamp(0, DeskStyles.names.length - 1);
    if (!isPro && DeskStyles.isPro(v)) return;
    deskStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // trickshot is Pro-only
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  /// Record a finished run.
  Future<void> recordGame(
      {required int score, required int makes, required int level}) async {
    gamesPlayed++;
    totalMakes += makes;
    if (score > bestScore) bestScore = score;
    if (level > bestLevel) bestLevel = level;
    notifyListeners();
    await _save();
  }

  Future<void> recordStreak(int streak) async {
    if (streak > bestStreak) {
      bestStreak = streak;
      notifyListeners();
      await _save();
    }
  }
}
