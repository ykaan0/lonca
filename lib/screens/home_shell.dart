import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'group/group_screen.dart';
import 'groups/group_list_screen.dart';
import 'groups/my_groups_screen.dart';
import 'profile/profile_screen.dart';

/// Ekranların alt kısmında, gezinme çubuğu için bırakılan boşluk.
const double kShellBottomInset = 180;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();
    final session = me.activeSession;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              const GroupListScreen(),
              const MyGroupsScreen(),
              ProfileScreen(uid: me.uid),
            ],
          ),
          // alt kenarda içeriği yumuşakça karartan geçiş
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140 + bottom,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.ink.withValues(alpha: 0), AppColors.ink],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (c, a) => SizeTransition(
                    sizeFactor: a,
                    alignment: Alignment.bottomCenter,
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: session == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(session.groupId),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LivePill(session: session),
                        ),
                ),
                _NavBar(index: _index, onChanged: (i) => setState(() => _index = i)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final ActiveSession session;
  const _LivePill({required this.session});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: session.groupId))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            const PulseDot(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.task,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(weight: FontWeight.w700)),
                  Text(session.groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(size: 12, color: AppColors.textDim)),
                ],
              ),
            ),
            LiveTick(builder: (_) => Text(clock(session.elapsed), style: AppTheme.clock(size: 20))),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _NavBar({required this.index, required this.onChanged});

  static const _items = [
    (Icons.explore_outlined, 'Keşfet'),
    (Icons.hive_outlined, 'Loncalarım'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.coal.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              flex: i == index ? 5 : 3,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.gold.withValues(alpha: .1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[i].$1, size: 22, color: i == index ? AppColors.gold : AppColors.textDim),
                      if (i == index) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _items[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: AppTheme.sans(size: 13, weight: FontWeight.w800, color: AppColors.gold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

