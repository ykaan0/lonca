import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'services/db.dart';
import 'theme.dart';
import 'widgets/ui.dart';

/// Oturum durumunu ve giriş yapan kullanıcının profilini tüm ağaca dağıtır.
class UserScope extends InheritedWidget {
  final bool authReady;
  final User? authUser;
  final AppUser? user;

  const UserScope({
    super.key,
    required this.authReady,
    required this.authUser,
    required this.user,
    required super.child,
  });

  static UserScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserScope>()!;

  /// Giriş yapılmış ekranlarda mevcut kullanıcı.
  static AppUser me(BuildContext context) => of(context).user!;
  static AppUser? maybeMe(BuildContext context) => of(context).user;

  @override
  bool updateShouldNotify(UserScope old) => true;
}

class LoncaApp extends StatefulWidget {
  const LoncaApp({super.key});

  @override
  State<LoncaApp> createState() => _LoncaAppState();
}

class _LoncaAppState extends State<LoncaApp> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;
  bool _ready = false;
  User? _authUser;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _userSub?.cancel();
      setState(() {
        _ready = true;
        _authUser = u;
        _user = null;
      });
      if (u != null) {
        _userSub = Db.userStream(u.uid).listen(
          (au) => setState(() => _user = au),
          onError: (_) {},
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserScope(
      authReady: _ready,
      authUser: _authUser,
      user: _user,
      child: MaterialApp(
        title: 'Lonca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final scope = UserScope.of(context);
    final Widget page;
    if (!scope.authReady || (scope.authUser != null && scope.user == null)) {
      page = const _Splash(key: ValueKey('splash'));
    } else if (scope.authUser == null) {
      page = const LoginScreen(key: ValueKey('login'));
    } else {
      page = const HomeShell(key: ValueKey('home'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: page,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          const OrbitDecor(size: 320),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lonca', style: AppTheme.serif(size: 44, color: AppColors.gold, weight: FontWeight.w400)),
              const SizedBox(height: 18),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

