import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../widgets/group_card.dart';
import '../../widgets/ui.dart';
import '../group/group_screen.dart';
import '../home_shell.dart';
import 'create_group_screen.dart';

/// Grup seçme ekranı — gruplar seviyelerine göre sıralanır.
class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late final Stream<List<Group>> _stream = Db.rankedGroups();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top;

    return StreamBuilder<List<Group>>(
      stream: _stream,
      builder: (context, snap) {
        final all = snap.data ?? const <Group>[];
        final q = _query.trim().toLowerCase();
        final ranked = [for (var i = 0; i < all.length; i++) (i + 1, all[i])]
            .where((e) => q.isEmpty || e.$2.name.toLowerCase().contains(q))
            .toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, top + 24, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LONCA', style: AppTheme.label(color: AppColors.gold)),
                          const SizedBox(height: 6),
                          Text('Keşfet', style: AppTheme.serif(size: 40, weight: FontWeight.w300, height: 1)),
                        ],
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.add_rounded,
                      filled: true,
                      size: 50,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Text(
                  'Loncalar, üyelerinin birlikte çalıştığı her dakikayla yükselir.',
                  style: AppTheme.sans(color: AppColors.textDim, height: 1.5),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Lonca ara',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 1.6)),
                ),
              )
            else if (ranked.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 50, 40, 0),
                  child: Text(
                    q.isEmpty ? 'Henüz hiç lonca yok.\nİlkini sen kur.' : 'Eşleşen lonca bulunamadı.',
                    textAlign: TextAlign.center,
                    style: AppTheme.serif(size: 18, color: AppColors.textDim, style: FontStyle.italic, height: 1.5),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: ranked.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final (rank, g) = ranked[i];
                    return Entrance(
                      key: ValueKey(g.id),
                      index: i,
                      child: GroupCard(
                        group: g,
                        rank: rank,
                        myUid: me.uid,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id))),
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: kShellBottomInset)),
          ],
        );
      },
    );
  }
}

