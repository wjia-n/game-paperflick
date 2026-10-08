import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const PaperFlickApp());

class PaperFlickApp extends StatelessWidget {
  const PaperFlickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Paper Flick',
      tagline: 'One crumpled ball, one distant bin. Office legend status awaits!',
      emoji: '🗑️',
      slug: 'paperflick',
      howToPlay:
          '• Drag BACK from the paper ball to aim, release to flick! 📄\n• Land it in the bin to score. 3 balls per level.\n• Later levels bring WIND 💨 and a MOVING bin. Stay frosty!\n• 20 levels. Every basket counts — make them all!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => PaperFlickScreen(players: players, callbacks: cb),
    );
  }
}
