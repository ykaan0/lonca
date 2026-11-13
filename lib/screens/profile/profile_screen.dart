import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/level.dart';
import '../../widgets/group_card.dart';
import '../../widgets/ui.dart';
import '../group/group_screen.dart';
import '../home_shell.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final bool showBack;

  const ProfileScreen({super.key, required this.uid, this.showBack = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<AppUser?> _user = Db.userStream(widget.uid);
  late final Stream<List<Group>> _groups = Db.groupsOf(widget.uid);

  Future<void> _signOut() async {
    final ok = await confirm(
      context,
      title: 'Çıkış yap',
      message: 'Hesabından çıkış yapmak istediğine emin misin?',
      action: 'Çıkış yap',
      danger: true,
    );
    if (ok && mounted) {
      await guard(context, AuthService.signOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();
    final isMe = widget.uid == me.uid;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = widget.showBack ? 32 + MediaQuery.paddingOf(context).bottom : kShellBottomInset;

    return Scaffold(
      body: StreamBuilder<AppUser?>(
        stream: _user,
        builder: (context, us) {
          if (!us.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 1.6));
          }
          final u = us.data!;
          final showGroups = isMe || !u.hideGroups;

          return ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, bottom),
            children: [
              Row(
                children: [
                  if (widget.showBack)
                    CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context))
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('PROFİL', style: AppTheme.label(color: AppColors.gold)),
                    ),
                  const Spacer(),
                  if (isMe) CircleIconButton(icon: Icons.logout_rounded, onTap: _signOut),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileHero(user: u, isMe: isMe),
              if (isMe) ...[
                const SizedBox(height: 18),
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_off_outlined, size: 20, color: AppColors.gold),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Loncaları gizle', style: AppTheme.sans(size: 14.5, weight: FontWeight.w700)),
                            Text(
                              'Diğer kullanıcılar üye olduğun loncaları görmez.',
                              style: AppTheme.sans(size: 12, color: AppColors.textDim),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: u.hideGroups,
                        onChanged: (v) => guard(context, () => Db.setHideGroups(u.uid, v)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const SectionLabel('Üye olduğu loncalar'),
              const SizedBox(height: 14),
              if (!showGroups)
                SoftCard(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: AppColors.textDim),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Bu kullanıcı üye olduğu loncaları gizli tutuyor.',
                          style: AppTheme.sans(color: AppColors.textDim),
                        ),
                      ),
                    ],
                  ),
                )
              else
                StreamBuilder<List<Group>>(
                  stream: _groups,
                  builder: (context, gs) {
                    final groups = gs.data ?? const <Group>[];
                    if (gs.connectionState == ConnectionState.waiting && !gs.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 1.6)),
                      );
                    }
                    if (groups.isEmpty) {
                      return SoftCard(
                        padding: const EdgeInsets.all(22),
                        child: Text(
                          'Henüz bir loncaya üye değil.',
                          textAlign: TextAlign.center,
                          style: AppTheme.sans(color: AppColors.textDim),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < groups.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Entrance(
                              key: ValueKey(groups[i].id),
                              index: i,
                              child: GroupCard(
                                group: groups[i],
                                myUid: u.uid,
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => GroupScreen(groupId: groups[i].id))),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AppUser user;
  final bool isMe;
  const _ProfileHero({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return LiveTick(builder: (context) {
      final live = user.activeSession == null
          ? 0
          : math.min(math.max(0, user.activeSession!.elapsed), Db.maxSessionSeconds);
      final total = user.totalSeconds + live;
      final lvl = LevelInfo.user(total);

      return Column(
        children: [
          LevelRing(
            progress: lvl.progress,
            size: 122,
            child: Monogram(name: user.name, size: 92, active: user.activeSession != null),
          ),
          const SizedBox(height: 16),
          Text(user.name,
              textAlign: TextAlign.center,
              style: AppTheme.serif(size: 32, weight: FontWeight.w400, height: 1.1)),
          const SizedBox(height: 4),
          Text('@${user.handle}', style: AppTheme.sans(color: AppColors.gold, weight: FontWeight.w600)),
          if (isMe && user.email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(user.email, style: AppTheme.sans(size: 12.5, color: AppColors.textDim)),
          ],
          const SizedBox(height: 20),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('LV ${lvl.level}', style: AppTheme.serif(size: 22, color: AppColors.gold)),
                        const SizedBox(height: 4),
                        Text('SEVİYE', style: AppTheme.label(size: 9)),
                      ],
                    ),
                  ),
                  Container(width: 1, color: AppColors.line),
                  Expanded(
                    child: Column(
                      children: [
                        Text(hoursShort(total), style: AppTheme.serif(size: 22)),
                        const SizedBox(height: 4),
                        Text('TOPLAM ÇALIŞMA', style: AppTheme.label(size: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Sonraki seviyeye ${hm(lvl.secondsToNext)}',
              style: AppTheme.sans(size: 12, color: AppColors.textFaint)),
        ],
      );
    });
  }
}

