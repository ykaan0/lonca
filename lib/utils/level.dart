import 'dart:math' as math;

/// Seviye hesabı: seviye L'ye ulaşmak için gereken süre = faktör * (L-1)^2 saat.
/// Böylece ilk seviyeler hızlı, sonrakiler giderek daha emek ister.
class LevelInfo {
  final int level;
  final double progress; // bir sonraki seviyeye ilerleme (0..1)
  final int secondsToNext;

  const LevelInfo(this.level, this.progress, this.secondsToNext);

  static const double userFactorHours = 2; // Lv2: 2 sa, Lv3: 8 sa, Lv5: 32 sa
  static const double groupFactorHours = 5; // Lv2: 5 sa, Lv3: 20 sa, Lv5: 80 sa

  factory LevelInfo.user(int seconds) => LevelInfo._calc(seconds, userFactorHours);
  factory LevelInfo.group(int seconds) => LevelInfo._calc(seconds, groupFactorHours);

  factory LevelInfo._calc(int seconds, double factorHours) {
    final unit = factorHours * 3600; // saniye
    final s = math.max(0, seconds);
    final level = math.sqrt(s / unit).floor() + 1;
    final start = unit * (level - 1) * (level - 1);
    final next = unit * level * level;
    final progress = ((s - start) / (next - start)).clamp(0.0, 1.0);
    return LevelInfo(level, progress, (next - s).ceil());
  }
}

