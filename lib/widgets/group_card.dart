import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/level.dart';
import 'sigil.dart';
import 'ui.dart';

/// Grup listesi kartı. [rank] verilirse soldaki büyük sıra numarası gösterilir.
class GroupCard extends StatelessWidget {
  final Group group;
  final int? rank;
  final String? myUid;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap, this.rank, this.myUid});

  @override
  Widget build(BuildContext context) {
    final lvl = LevelInfo.group(group.totalSeconds);
    final top = rank != null && rank! <= 3;
    final member = myUid != null && group.isMember(myUid!);

    return Pressable(
      onTap: onTap,
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        borderColor: top ? AppColors.gold.withValues(alpha: .22) : null,
        gradient: top
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gold.withValues(alpha: .07), AppColors.surface],
              )
            : null,
        child: Row(
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 44,
                child: top
                    ? ShaderMask(
                        shaderCallback: (r) => AppColors.goldGradient.createShader(r),
                        child: Text(rank!.toString().padLeft(2, '0'),
                            style: AppTheme.serif(size: 30, weight: FontWeight.w300, color: Colors.white)),
                      )
                    : Text(rank!.toString().padLeft(2, '0'),
                        style: AppTheme.serif(size: 30, weight: FontWeight.w300, color: AppColors.textFaint)),
              ),
              const SizedBox(width: 6),
            ],
            SigilBadge(sigil: group.sigil, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.sans(size: 16, weight: FontWeight.w700)),
                      ),
                      if (member) ...[
                        const SizedBox(width: 8),
                        RoleTag(group.roleOf(myUid!), strong: group.isStaff(myUid!)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.memberCount} üye  ·  ${hoursShort(group.totalSeconds)}',
                    style: AppTheme.sans(size: 12.5, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 10),
                  GoldProgress(value: lvl.progress, height: 3),
                ],
              ),
            ),
            const SizedBox(width: 14),
            LevelBadge(lvl.level),
          ],
        ),
      ),
    );
  }
}

