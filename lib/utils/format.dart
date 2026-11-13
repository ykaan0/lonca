String _two(int n) => n.toString().padLeft(2, '0');

/// 01:23:45
String clock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${_two(s ~/ 3600)}:${_two(s % 3600 ~/ 60)}:${_two(s % 60)}';
}

/// "2 sa 15 dk" / "15 dk" / "40 sn"
String hm(int seconds) {
  if (seconds < 60) return '${seconds < 0 ? 0 : seconds} sn';
  final h = seconds ~/ 3600;
  final m = seconds % 3600 ~/ 60;
  if (h == 0) return '$m dk';
  if (m == 0) return '$h sa';
  return '$h sa $m dk';
}

/// Kısa toplam: "45 dk", "3,5 sa", "128 sa"
String hoursShort(int seconds) {
  if (seconds < 3600) return '${seconds ~/ 60} dk';
  final h = seconds / 3600;
  final txt = h < 10 ? h.toStringAsFixed(1) : h.toStringAsFixed(0);
  return '${txt.replaceAll('.', ',')} sa';
}

String timeOfDay(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'az önce';
  if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
  if (diff.inDays < 1) return '${diff.inHours} sa önce';
  return '${diff.inDays} gün önce';
}

/// Türkçe büyük harf (i → İ, ı → I).
String trUpper(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters1;
  final second = parts.length > 1 ? parts.last.characters1 : '';
  return trUpper(first + second);
}

extension on String {
  String get characters1 => isEmpty ? '' : String.fromCharCode(runes.first);
}

