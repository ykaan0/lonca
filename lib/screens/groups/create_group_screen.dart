import 'package:flutter/material.dart';

import '../../app.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../widgets/sigil.dart';
import '../../widgets/ui.dart';
import '../group/group_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  int _sigil = 0;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    final me = UserScope.me(context);
    setState(() => _busy = true);
    String? id;
    await guard(context, () async {
      id = await Db.createGroup(me: me, name: _name.text, description: _desc.text, sigil: _sigil);
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GroupScreen(groupId: id!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 26),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                  child: SigilBadge(key: ValueKey(_sigil), sigil: _sigil, size: 96, glow: true),
                ),
              ),
              const SizedBox(height: 22),
              Center(child: Text('Yeni lonca', style: AppTheme.serif(size: 34, weight: FontWeight.w300))),
              const SizedBox(height: 6),
              Center(
                child: Text('Liderliği sende olacak.',
                    style: AppTheme.sans(color: AppColors.textDim)),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _name,
                maxLength: 32,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Lonca adı', counterText: ''),
                validator: (v) => (v == null || v.trim().length < 3) ? 'En az 3 karakter' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _desc,
                maxLength: 140,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (isteğe bağlı)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Sembol'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < sigils.length; i++)
                    Pressable(
                      scale: .88,
                      onTap: () => setState(() => _sigil = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: i == _sigil ? AppColors.goldGradient : null,
                          color: i == _sigil ? null : AppColors.surface,
                          border: Border.all(color: i == _sigil ? Colors.transparent : AppColors.line),
                        ),
                        child: Icon(sigils[i], size: 22, color: i == _sigil ? AppColors.ink : AppColors.textDim),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 34),
              GoldButton(label: 'Loncayı kur', icon: Icons.flag_outlined, loading: _busy, onPressed: _create),
            ],
          ),
        ),
      ),
    );
  }
}

