import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/errors.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _fs = FirebaseFirestore.instance;
  static final handlePattern = RegExp(r'^[a-z0-9_.]{3,20}$');

  static String normalizeHandle(String raw) => raw.trim().toLowerCase().replaceAll('@', '');

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  /// Hesap oluşturur ve benzersiz kullanıcı ID'sini (handle) ayırır.
  static Future<void> register({
    required String name,
    required String handle,
    required String email,
    required String password,
  }) async {
    final h = normalizeHandle(handle);
    if (!handlePattern.hasMatch(h)) {
      throw const AppError('ID 3-20 karakter olmalı: harf, rakam, _ ve . kullanılabilir.');
    }
    final pre = await _fs.collection('handles').doc(h).get();
    if (pre.exists) throw const AppError('Bu ID zaten alınmış.');

    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    try {
      await _fs.runTransaction((tx) async {
        final hRef = _fs.collection('handles').doc(h);
        final snap = await tx.get(hRef);
        if (snap.exists) throw const AppError('Bu ID zaten alınmış.');
        tx.set(hRef, {'uid': user.uid});
        tx.set(_fs.collection('users').doc(user.uid), {
          'name': name.trim(),
          'email': email.trim(),
          'handle': h,
          'totalSeconds': 0,
          'hideGroups': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      await user.updateDisplayName(name.trim());
    } catch (_) {
      await user.delete(); // yarım kalan hesabı geri al
      rethrow;
    }
  }

  static Future<void> signOut() => _auth.signOut();
}

