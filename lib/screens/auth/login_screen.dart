import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await guard(context, () => AuthService.signIn(_email.text, _pass.text));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -120, right: -140, child: OrbitDecor(size: 380)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOŞ GELDİN', style: AppTheme.label(color: AppColors.gold)),
                      const SizedBox(height: 10),
                      Text('Lonca',
                          style: AppTheme.serif(size: 60, weight: FontWeight.w300, height: 1, letterSpacing: -1.5)),
                      const SizedBox(height: 12),
                      Text('Birlikte çalış, birlikte yüksel.',
                          style: AppTheme.serif(
                              size: 18, color: AppColors.textDim, style: FontStyle.italic, weight: FontWeight.w300)),
                      const SizedBox(height: 44),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
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
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                      ),
                      const SizedBox(height: 28),
                      GoldButton(label: 'Giriş yap', loading: _busy, onPressed: _submit),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text.rich(TextSpan(
                            style: AppTheme.sans(color: AppColors.textDim),
                            children: [
                              const TextSpan(text: 'Hesabın yok mu?  '),
                              TextSpan(
                                text: 'Kayıt ol',
                                style: AppTheme.sans(color: AppColors.gold, weight: FontWeight.w800),
                              ),
                            ],
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

