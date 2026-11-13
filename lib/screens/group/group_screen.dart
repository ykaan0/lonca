import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/level.dart';
import '../../widgets/sigil.dart';
import '../../widgets/ui.dart';
import '../profile/profile_screen.dart';
import 'admin_panel_screen.dart';
import 'chat_panel.dart';
import 'member_tile.dart';
import 'start_session_sheet.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  const GroupScreen({super.key, required this.groupId});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  late final Stream<Group?> _group = Db.groupStream(widget.groupId);
  late final Stream<List<Member>> _members = Db.membersStream(widget.groupId);
  late final Stream<List<LiveSession>> _sessions = Db.sessionsStream(widget.groupId);
  Stream<bool>? _pending;
  Stream<List<JoinRequest>>? _requests;

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();
    _pending ??= Db.hasPendingRequest(widget.groupId, me.uid);

    return StreamBuilder<Group?>(
      stream: _group,
      builder: (context, gs) {
        if (!gs.hasData) {
          return Scaffold(
            body: Center(
              child: gs.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator(strokeWidth: 1.6)
                  : _Missing(onBack: () => Navigator.pop(context)),
            ),
          );
        }
        final g = gs.data!;
        final member = g.isMember(me.uid);
        if (g.isStaff(me.uid)) _requests ??= Db.requestsStream(g.id);

        return Scaffold(
          key: _scaffold,
          endDrawer: member ? ChatPanel(group: g) : null,
          drawerEdgeDragWidth: 56,
          drawerScrimColor: Colors.black.withValues(alpha: .6),
          body: StreamBuilder<List<Member>>(
            stream: _members,
            builder: (context, ms) => StreamBuilder<List<LiveSession>>(
              stream: _sessions,
              builder: (context, ss) => _body(
                context,
                me,
                g,
                ms.data ?? const [],
                ss.data ?? const [],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, AppUser me, Group g, List<Member> members, List<LiveSession> sessions) {
    final member = g.isMember(me.uid);
    final byUid = {for (final s in sessions) s.uid: s};
    final sorted = [...members.where((m) => g.isMember(m.uid))]
      ..sort((a, b) {
        final sa = byUid[a.uid], sb = byUid[b.uid];
        if ((sa == null) != (sb == null)) return sa != null ? -1 : 1;
        if (sa != null && sb != null) return sa.startedAt.compareTo(sb.startedAt);
        final r = g.rankOf(a.uid).compareTo(g.rankOf(b.uid));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
    final activeCount = sorted.where((m) => byUid.containsKey(m.uid)).length;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _topBar(context, me, g)),
          SliverToBoxAdapter(child: _Hero(group: g, sessions: sessions, activeCount: activeCount)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: member
                  ? _SessionPanel(group: g, me: me, onOpenChat: () => _scaffold.currentState?.openEndDrawer())
                  : _JoinPanel(group: g, me: me, pending: _pending!),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 16),
              child: SectionLabel(
                'Üyeler',
                trailing: Text('$activeCount aktif · ${sorted.length}',
                    style: AppTheme.sans(size: 12, color: AppColors.textDim)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .9,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: sorted.length,
                (context, i) {
                  final m = sorted[i];
                  return Entrance(
                    key: ValueKey(m.uid),
                    index: i,
                    child: MemberTile(
                      member: m,
                      session: byUid[m.uid],
                      role: g.rankOf(m.uid),
                      muted: g.isMuted(m.uid),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => ProfileScreen(uid: m.uid, showBack: true))),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom)),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, AppUser me, Group g) {
    final member = g.isMember(me.uid);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const Spacer(),
          if (g.isStaff(me.uid) && _requests != null) ...[
            StreamBuilder<List<JoinRequest>>(
              stream: _requests,
              builder: (context, rs) => CircleIconButton(
                icon: Icons.tune_rounded,
                badge: rs.data?.length ?? 0,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => AdminPanelScreen(groupId: g.id))),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (member) ...[
            CircleIconButton(
              icon: Icons.forum_outlined,
              onTap: () => _scaffold.currentState?.openEndDrawer(),
            ),
            if (!g.isLeader(me.uid)) ...[
              const SizedBox(width: 10),
              CircleIconButton(icon: Icons.logout_rounded, onTap: () => _leave(g, me)),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _leave(Group g, AppUser me) async {
    final ok = await confirm(
      context,
      title: 'Loncadan ayrıl',
      message: '"${g.name}" loncasından ayrılmak istediğine emin misin? Tekrar girmek için onay gerekir.',
      action: 'Ayrıl',
      danger: true,
    );
    if (!ok || !mounted) return;
    final done = await guard(context, () => Db.leave(g, me));
    if (done && mounted) toast(context, 'Loncadan ayrıldın.');
  }
}

class _Hero extends StatelessWidget {
  final Group group;
  final List<LiveSession> sessions;
  final int activeCount;

  const _Hero({required this.group, required this.sessions, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: LiveTick(builder: (context) {
        // Açık oturumlar canlı olarak grubun süresine eklenir.
        final live = sessions.fold<int>(
            0, (sum, s) => sum + s.elapsed.clamp(0, Db.maxSessionSeconds));
        final total = group.totalSeconds + live;
        final lvl = LevelInfo.group(total);
        return Column(
          children: [
            LevelRing(
              progress: lvl.progress,
              size: 128,
              child: SigilBadge(sigil: group.sigil, size: 96, glow: activeCount > 0),
            ),
            const SizedBox(height: 18),
            Text(group.name,
                textAlign: TextAlign.center,
                style: AppTheme.serif(size: 32, weight: FontWeight.w400, height: 1.1)),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(group.description,
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(color: AppColors.textDim, height: 1.5)),
            ],
            const SizedBox(height: 22),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _Stat(label: 'Seviye', value: '${lvl.level}', gold: true),
                    const _Divider(),
                    _Stat(label: 'Üye', value: '${group.memberCount}'),
                    const _Divider(),
                    _Stat(label: 'Toplam', value: hoursShort(total)),
                    const _Divider(),
                    _Stat(label: 'Aktif', value: '$activeCount'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Sonraki seviyeye ${hm(lvl.secondsToNext)}',
                style: AppTheme.sans(size: 12, color: AppColors.textFaint)),
          ],
        );
      }),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;
  const _Stat({required this.label, required this.value, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              style: AppTheme.serif(size: 20, color: gold ? AppColors.gold : AppColors.text)),
          const SizedBox(height: 4),
          Text(trUpper(label), style: AppTheme.label(size: 9)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, color: AppColors.line);
}

class _SessionPanel extends StatefulWidget {
  final Group group;
  final AppUser me;
  final VoidCallback onOpenChat;
  const _SessionPanel({required this.group, required this.me, required this.onOpenChat});

  @override
  State<_SessionPanel> createState() => _SessionPanelState();
}

class _SessionPanelState extends State<_SessionPanel> {
  bool _busy = false;

  Future<void> _end() async {
    final ok = await confirm(
      context,
      title: 'Oturumu bitir',
      message: 'Çalışma süren profiline ve loncaya eklenecek.',
      action: 'Bitir',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    var added = 0;
    await guard(context, () async => added = await Db.endSession(widget.me));
    if (!mounted) return;
    setState(() => _busy = false);
    if (added > 0) toast(context, 'Tebrikler! +${hm(added)} çalışma eklendi.');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.me.activeSession;
    final here = s != null && s.groupId == widget.group.id;

    Widget content;
    if (here) {
      content = SoftCard(
        key: const ValueKey('here'),
        padding: const EdgeInsets.all(22),
        borderColor: AppColors.gold.withValues(alpha: .35),
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.4,
          colors: [AppColors.gold.withValues(alpha: .12), AppColors.surface],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const PulseDot(),
              const SizedBox(width: 10),
              Text('OTURUM AÇIK', style: AppTheme.label(color: AppColors.live)),
            ]),
            const SizedBox(height: 14),
            Text(s.task, style: AppTheme.serif(size: 22, height: 1.2)),
            const SizedBox(height: 6),
            LiveTick(builder: (_) => Text(clock(s.elapsed), style: AppTheme.clock(size: 44))),
            const SizedBox(height: 16),
            GhostButton(label: 'Oturumu bitir', icon: Icons.stop_rounded, loading: _busy, onPressed: _end),
          ],
        ),
      );
    } else if (s != null) {
      content = SoftCard(
        key: const ValueKey('elsewhere'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Başka bir loncada oturumun açık', style: AppTheme.sans(weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('"${s.groupName}" · ${s.task}', style: AppTheme.sans(color: AppColors.textDim)),
            const SizedBox(height: 14),
            GhostButton(label: 'O oturumu bitir', loading: _busy, onPressed: _end),
          ],
        ),
      );
    } else {
      content = GoldButton(
        key: const ValueKey('start'),
        label: 'Çalışma oturumu başlat',
        icon: Icons.play_arrow_rounded,
        onPressed: () => showStartSessionSheet(context, widget.group, widget.me),
      );
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          child: content,
        ),
        const SizedBox(height: 14),
        Pressable(
          onTap: widget.onOpenChat,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sohbet için sağdan kaydır',
                    style: AppTheme.sans(size: 12.5, color: AppColors.textDim)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinPanel extends StatefulWidget {
  final Group group;
  final AppUser me;
  final Stream<bool> pending;
  const _JoinPanel({required this.group, required this.me, required this.pending});

  @override
  State<_JoinPanel> createState() => _JoinPanelState();
}

class _JoinPanelState extends State<_JoinPanel> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    await guard(context, fn);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.pending,
      builder: (context, snap) {
        final pending = snap.data ?? false;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: pending
              ? SoftCard(
                  key: const ValueKey('pending'),
                  child: Column(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: AppColors.gold),
                      const SizedBox(height: 10),
                      Text('İsteğin iletildi', style: AppTheme.serif(size: 20)),
                      const SizedBox(height: 6),
                      Text('Lider ya da yardımcılar onayladığında içeri girebileceksin.',
                          textAlign: TextAlign.center,
                          style: AppTheme.sans(color: AppColors.textDim, height: 1.5)),
                      const SizedBox(height: 16),
                      GhostButton(
                        label: 'İsteği geri çek',
                        color: AppColors.textDim,
                        loading: _busy,
                        onPressed: () => _run(() => Db.cancelRequest(widget.group.id, widget.me.uid)),
                      ),
                    ],
                  ),
                )
              : GoldButton(
                  key: const ValueKey('join'),
                  label: 'Katılma isteği gönder',
                  icon: Icons.login_rounded,
                  loading: _busy,
                  onPressed: () => _run(() => Db.sendRequest(widget.group.id, widget.me)),
                ),
        );
      },
    );
  }
}

class _Missing extends StatelessWidget {
  final VoidCallback onBack;
  const _Missing({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Bu lonca artık yok.', style: AppTheme.serif(size: 22)),
          const SizedBox(height: 20),
          GhostButton(label: 'Geri dön', onPressed: onBack),
        ],
      ),
    );
  }
}

