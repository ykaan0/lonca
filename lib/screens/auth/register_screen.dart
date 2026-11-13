import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _handle, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => AuthService.register(
        name: _name.text,
        handle: _handle.text,
        email: _email.text,
        password: _pass.text,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                const SizedBox(height: 28),
                Text('YENİ HESAP', style: AppTheme.label(color: AppColors.gold)),
                const SizedBox(height: 10),
                Text('Loncaya\nadım at.', style: AppTheme.serif(size: 42, weight: FontWeight.w300, height: 1.05)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'İsmini gir' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _handle,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı ID',
                    hintText: 'ornek_kullanici',
                    prefixIcon: Icon(Icons.tag_rounded, size: 20),
                    helperText: 'Benzersiz olmalı · harf, rakam, _ ve .',
                  ),
                  validator: (v) => AuthService.handlePattern.hasMatch(AuthService.normalizeHandle(v ?? ''))
                      ? null
                      : '3-20 karakter: a-z, 0-9, _ ve .',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta gir' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass2,
                  obscureText: true,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Şifre (tekrar)',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (v) => v != _pass.text ? 'Şifreler eşleşmiyor' : null,
                ),
                const SizedBox(height: 30),
                GoldButton(label: 'Hesabı oluştur', loading: _busy, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

