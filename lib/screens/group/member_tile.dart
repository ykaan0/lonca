import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui.dart';

/// Grup ekranındaki kare üye kartı: isim, aktiflik, yapılan iş ve çalışma süresi.
class MemberTile extends StatelessWidget {
  final Member member;
  final LiveSession? session;
  final int role; // 0 = lider, 1 = yardımcı, 2 = üye
  final bool muted;
  final VoidCallback onTap;

  const MemberTile({
    super.key,
    required this.member,
    required this.session,
    required this.role,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = session != null;

    return Pressable(
      onTap: onTap,
      child: SoftCard(
        padding: const EdgeInsets.all(15),
        radius: 22,
        borderColor: active ? AppColors.gold.withValues(alpha: .35) : AppColors.line,
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gold.withValues(alpha: .10), AppColors.surface],
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Monogram(name: member.name, size: 38, active: active, dim: !active),
                const Spacer(),
                if (muted)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.volume_off_rounded, size: 15, color: AppColors.danger),
                  ),
                if (active)
                  const PulseDot(size: 8)
                else
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textFaint),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sans(
                size: 15,
                weight: FontWeight.w700,
                color: active ? AppColors.text : AppColors.textDim,
              ),
            ),
            const SizedBox(height: 4),
            if (role < 2)
              RoleTag(role == 0 ? 'Lider' : 'Yardımcı', strong: role == 0)
            else
              Text(
                '@${member.handle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(size: 11.5, color: AppColors.textFaint),
              ),
            const Spacer(),
            if (active) ...[
              Text(
                session!.task,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(size: 12.5, color: AppColors.goldSoft, height: 1.3),
              ),
              const SizedBox(height: 6),
              LiveTick(
                builder: (_) => Text(
                  clock(session!.elapsed),
                  style: AppTheme.clock(size: 18, color: AppColors.gold),
                ),
              ),
            ] else ...[
              Text(
                'Çevrimdışı',
                style: AppTheme.sans(size: 12, color: AppColors.textFaint),
              ),
              const SizedBox(height: 4),
              Text(
                'Toplam ${hoursShort(member.seconds)}',
                style: AppTheme.sans(size: 12.5, weight: FontWeight.w600, color: AppColors.textDim),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
