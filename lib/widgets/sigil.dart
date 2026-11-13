import 'package:flutter/material.dart';

import '../theme.dart';

/// Gruplar için seçilebilir semboller.
const sigils = <IconData>[
  Icons.auto_awesome,
  Icons.local_fire_department_outlined,
  Icons.bolt_outlined,
  Icons.spa_outlined,
  Icons.terrain_outlined,
  Icons.nightlight_outlined,
  Icons.diamond_outlined,
  Icons.menu_book_outlined,
  Icons.code_rounded,
  Icons.music_note_outlined,
  Icons.fitness_center_outlined,
  Icons.palette_outlined,
];

IconData sigilIcon(int i) => sigils[i.clamp(0, sigils.length - 1)];

class SigilBadge extends StatelessWidget {
  final int sigil;
  final double size;
  final bool glow;

  const SigilBadge({super.key, required this.sigil, this.size = 48, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.gold.withValues(alpha: .22), AppColors.surfaceHi],
          radius: .9,
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: .3)),
        boxShadow: glow
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: .15), blurRadius: 30, spreadRadius: 2)]
            : null,
      ),
      child: Icon(sigilIcon(sigil), color: AppColors.gold, size: size * .46),
    );
  }
}

