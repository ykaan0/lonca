import 'package:firebase_auth/firebase_auth.dart';

/// Kullanıcıya doğrudan gösterilebilecek uygulama hatası.
class AppError implements Exception {
  final String message;
  const AppError(this.message);
  @override
  String toString() => message;
}

String friendlyError(Object e) {
  if (e is AppError) return e.message;
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-posta adresi geçersiz.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta ya da şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta ile zaten bir hesap var.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı, biraz bekle.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok.';
    }
    return e.message ?? 'Giriş sırasında bir hata oluştu.';
  }
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkin yok.';
      case 'unavailable':
        return 'Sunucuya ulaşılamıyor, bağlantını kontrol et.';
      case 'not-found':
        return 'Kayıt bulunamadı.';
    }
    return e.message ?? 'Bir hata oluştu.';
  }
  return 'Bir şeyler ters gitti.';
}

