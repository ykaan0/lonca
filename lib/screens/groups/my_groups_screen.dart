import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../widgets/group_card.dart';
import '../../widgets/ui.dart';
import '../group/group_screen.dart';
import '../home_shell.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  Stream<List<Group>>? _stream;
  String? _uid;

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();
    if (_uid != me.uid) {
      _uid = me.uid;
      _stream = Db.groupsOf(me.uid);
    }
    final top = MediaQuery.paddingOf(context).top;

    return StreamBuilder<List<Group>>(
      stream: _stream,
      builder: (context, snap) {
        final groups = snap.data ?? const <Group>[];
        return ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(20, top + 24, 20, kShellBottomInset),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ÜYELİKLER', style: AppTheme.label(color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Text('Loncalarım', style: AppTheme.serif(size: 40, weight: FontWeight.w300, height: 1)),
                  const SizedBox(height: 26),
                ],
              ),
            ),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(strokeWidth: 1.6)),
              )
            else if (groups.isEmpty)
              SoftCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.hive_outlined, color: AppColors.gold, size: 34),
                    const SizedBox(height: 14),
                    Text('Henüz bir loncan yok', style: AppTheme.serif(size: 20)),
                    const SizedBox(height: 8),
                    Text(
                      'Keşfet sekmesinden bir loncaya katılma isteği gönder ya da kendi loncanı kur.',
                      textAlign: TextAlign.center,
                      style: AppTheme.sans(color: AppColors.textDim, height: 1.5),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < groups.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Entrance(
                    key: ValueKey(groups[i].id),
                    index: i,
                    child: GroupCard(
                      group: groups[i],
                      myUid: me.uid,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => GroupScreen(groupId: groups[i].id))),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

