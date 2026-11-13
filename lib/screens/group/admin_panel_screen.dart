import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui.dart';

/// Lider ve yardımcıların erişebildiği yönetim paneli.
///
/// Lider & Yardımcı: katılma isteklerini onaylama/reddetme, susturma, çıkarma.
/// Sadece Lider: yardımcı atama/alma, liderliği devretme.
class AdminPanelScreen extends StatefulWidget {
  final String groupId;
  const AdminPanelScreen({super.key, required this.groupId});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final Stream<Group?> _group = Db.groupStream(widget.groupId);
  late final Stream<List<JoinRequest>> _requests = Db.requestsStream(widget.groupId);
  late final Stream<List<Member>> _members = Db.membersStream(widget.groupId);

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();

    return StreamBuilder<Group?>(
      stream: _group,
      builder: (context, gs) {
        if (!gs.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 1.6)));
        }
        final g = gs.data!;
        if (!g.isStaff(me.uid)) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 36),
                    const SizedBox(height: 16),
                    Text('Yönetim yetkin yok.', style: AppTheme.serif(size: 22)),
                    const SizedBox(height: 20),
                    GhostButton(label: 'Geri dön', onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
          );
        }

        final isLeader = g.isLeader(me.uid);

        return Scaffold(
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Row(
                  children: [
                    CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YÖNETİM PANELİ', style: AppTheme.label(color: AppColors.gold)),
                          Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.serif(size: 24, weight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    RoleTag(isLeader ? 'Lider' : 'Yardımcı', strong: isLeader),
                  ],
                ),
                const SizedBox(height: 28),
                const SectionLabel('Katılma istekleri'),
                const SizedBox(height: 14),
                StreamBuilder<List<JoinRequest>>(
                  stream: _requests,
                  builder: (context, rs) {
                    final list = rs.data ?? const <JoinRequest>[];
                    if (list.isEmpty) {
                      return SoftCard(
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                        child: Text(
                          'Bekleyen katılma isteği yok.',
                          textAlign: TextAlign.center,
                          style: AppTheme.sans(color: AppColors.textDim),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final r in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RequestCard(group: g, req: r, me: me),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const SectionLabel('Üye yönetimi'),
                const SizedBox(height: 14),
                StreamBuilder<List<Member>>(
                  stream: _members,
                  builder: (context, ms) {
                    final members = [...(ms.data ?? const <Member>[]).where((m) => g.isMember(m.uid))]
                      ..sort((a, b) {
                        final r = g.rankOf(a.uid).compareTo(g.rankOf(b.uid));
                        return r != 0 ? r : a.name.compareTo(b.name);
                      });
                    return Column(
                      children: [
                        for (final m in members)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MemberAdminCard(group: g, member: m, me: me),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final Group group;
  final JoinRequest req;
  final AppUser me;
  const _RequestCard({required this.group, required this.req, required this.me});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    await guard(context, fn);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.req;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Monogram(name: r.name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: AppTheme.sans(size: 15, weight: FontWeight.w700)),
                Text('@${r.handle} · ${ago(r.createdAt)}',
                    style: AppTheme.sans(size: 12, color: AppColors.textDim)),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 1.8))
          else ...[
            CircleIconButton(
              icon: Icons.close_rounded,
              size: 38,
              onTap: () => _run(() => Db.rejectRequest(widget.group.id, r.uid)),
            ),
            const SizedBox(width: 8),
            CircleIconButton(
              icon: Icons.check_rounded,
              size: 38,
              filled: true,
              onTap: () => _run(() => Db.acceptRequest(widget.group, r, widget.me)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAdminCard extends StatelessWidget {
  final Group group;
  final Member member;
  final AppUser me;
  const _MemberAdminCard({required this.group, required this.member, required this.me});

  @override
  Widget build(BuildContext context) {
    final isSelf = member.uid == me.uid;
    final iAmLeader = group.isLeader(me.uid);
    final targetLeader = group.isLeader(member.uid);
    final targetHelper = group.isHelper(member.uid);
    final muted = group.isMuted(member.uid);

    // Lider kendisi hariç herkesi yönetebilir.
    // Yardımcı yalnızca normal üyeleri susturup çıkarabilir.
    final canMuteOrKick = !isSelf && (iAmLeader || (!targetLeader && !targetHelper));

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Monogram(name: member.name, size: 40, active: targetLeader),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.sans(size: 15, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoleTag(group.roleOf(member.uid), strong: !group.isMember(member.uid) ? false : group.isStaff(member.uid)),
                        if (muted) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.volume_off_rounded, size: 15, color: AppColors.danger),
                        ],
                      ],
                    ),
                    Text(
                      '@${member.handle} · ${hoursShort(member.seconds)}',
                      style: AppTheme.sans(size: 12, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canMuteOrKick || (iAmLeader && !isSelf)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canMuteOrKick)
                  _ActionChip(
                    icon: muted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    label: muted ? 'Sesi aç' : 'Sustur',
                    onTap: () => guard(context, () => Db.setMuted(group.id, member.uid, !muted)),
                  ),
                if (iAmLeader && !isSelf)
                  _ActionChip(
                    icon: targetHelper ? Icons.star_border_rounded : Icons.star_rounded,
                    label: targetHelper ? 'Yardımcılığı al' : 'Yardımcı yap',
                    gold: !targetHelper,
                    onTap: () => guard(context, () => Db.setHelper(group.id, member.uid, !targetHelper)),
                  ),
                if (iAmLeader && !isSelf)
                  _ActionChip(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Liderliği devret',
                    gold: true,
                    onTap: () async {
                      final ok = await confirm(
                        context,
                        title: 'Liderliği devret',
                        message:
                            '${member.name} loncanın yeni lideri olacak, sen ise yardımcı olarak kalacaksın. Emin misin?',
                        action: 'Devret',
                      );
                      if (ok && context.mounted) {
                        final done = await guard(context, () => Db.transferLeadership(group, member, me));
                        if (done && context.mounted) toast(context, 'Liderlik devredildi.');
                      }
                    },
                  ),
                if (canMuteOrKick)
                  _ActionChip(
                    icon: Icons.person_remove_outlined,
                    label: 'Çıkar',
                    danger: true,
                    onTap: () async {
                      final ok = await confirm(
                        context,
                        title: 'Üyeyi çıkar',
                        message: '${member.name} loncadan çıkarılacak.',
                        action: 'Çıkar',
                        danger: true,
                      );
                      if (ok && context.mounted) {
                        await guard(context, () => Db.kick(group, member, me));
                      }
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gold;
  final bool danger;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gold = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.danger : (gold ? AppColors.gold : AppColors.textDim);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: c.withValues(alpha: .08),
          border: Border.all(color: c.withValues(alpha: .28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.sans(size: 12, weight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }
}

