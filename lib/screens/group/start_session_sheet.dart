import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

const _suggestions = [
  'Flutter öğrenme',
  'Algoritma pratiği',
  'Okuma & not alma',
  'Proje geliştirme',
  'Tasarım çalışması',
];

Future<void> showStartSessionSheet(BuildContext context, Group group, AppUser me) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _StartSessionSheet(group: group, me: me),
  );
}

class _StartSessionSheet extends StatefulWidget {
  final Group group;
  final AppUser me;
  const _StartSessionSheet({required this.group, required this.me});

  @override
  State<_StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<_StartSessionSheet> {
  final _form = GlobalKey<FormState>();
  final _task = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _task.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final ok = await guard(context, () => Db.startSession(widget.group, widget.me, _task.text));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 6, 24, 24 + inset + bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ÇALIŞMA OTURUMU', style: AppTheme.label(color: AppColors.gold)),
            const SizedBox(height: 8),
            Text('Şu an ne üzerinde çalışacaksın?', style: AppTheme.serif(size: 26, weight: FontWeight.w400)),
            const SizedBox(height: 6),
            Text(
              'Oturumun açık kaldığı süre hem senin hem de "${widget.group.name}" loncasının seviyesini artırır.',
              style: AppTheme.sans(size: 13, color: AppColors.textDim, height: 1.45),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _task,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              onFieldSubmitted: (_) => _start(),
              decoration: const InputDecoration(
                labelText: 'Ne yapıyorsun?',
                hintText: 'Örn: Flutter öğrenme',
                counterText: '',
              ),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Kısa bir açıklama yaz' : null,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _suggestions)
                  Pressable(
                    onTap: () => _task.text = s,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(s, style: AppTheme.sans(size: 12, color: AppColors.textDim)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            GoldButton(
              label: 'Oturumu başlat',
              icon: Icons.play_arrow_rounded,
              loading: _busy,
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }
}

