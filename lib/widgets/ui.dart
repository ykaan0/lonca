import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/errors.dart';
import '../utils/format.dart';

/// Basınca hafifçe içe çöken, yumuşak dokunuş.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = .97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.gradient,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.line),
      ),
      child: child,
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GoldButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Pressable(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onPressed == null ? .45 : 1,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: .16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? const SizedBox(
                    key: ValueKey('l'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                  )
                : Row(
                    key: const ValueKey('t'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19, color: AppColors.ink),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: AppTheme.sans(size: 15, weight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool loading;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.gold,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .4)),
          color: color.withValues(alpha: .04),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTheme.sans(size: 14.5, weight: FontWeight.w700, color: color)),
                ],
              ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final bool filled;
  final double size;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = 0,
    this.filled = false,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .9,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: filled ? AppColors.goldGradient : null,
                color: filled ? null : AppColors.surface,
                border: filled ? null : Border.all(color: AppColors.line),
              ),
              child: Icon(icon, size: size * .44, color: filled ? AppColors.ink : AppColors.text),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: Text('$badge',
                      textAlign: TextAlign.center,
                      style: AppTheme.sans(size: 10.5, weight: FontWeight.w800, color: AppColors.ink)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// İsim baş harflerinden oluşan avatar.
class Monogram extends StatelessWidget {
  final String name;
  final double size;
  final bool active;
  final bool dim;

  const Monogram({super.key, required this.name, this.size = 44, this.active = false, this.dim = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppColors.goldGradient : null,
        color: active ? null : AppColors.surfaceHi,
        border: active ? null : Border.all(color: AppColors.line),
      ),
      child: Text(
        initials(name),
        style: AppTheme.serif(
          size: size * .36,
          weight: FontWeight.w600,
          letterSpacing: 0,
          color: active ? AppColors.ink : (dim ? AppColors.textFaint : AppColors.gold),
        ),
      ),
    );
  }
}

class LevelBadge extends StatelessWidget {
  final int level;
  const LevelBadge(this.level, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: AppColors.gold.withValues(alpha: .08),
        border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 6, height: 6, color: AppColors.gold),
          ),
          const SizedBox(width: 7),
          Text('LV $level', style: AppTheme.label(color: AppColors.gold, size: 10.5)),
        ],
      ),
    );
  }
}

class RoleTag extends StatelessWidget {
  final String text;
  final bool strong;
  const RoleTag(this.text, {super.key, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: strong ? AppColors.gold.withValues(alpha: .14) : AppColors.surfaceHi,
      ),
      child: Text(trUpper(text),
          style: AppTheme.label(color: strong ? AppColors.gold : AppColors.textDim, size: 9)),
    );
  }
}

class GoldProgress extends StatelessWidget {
  final double value;
  final double height;
  const GoldProgress({super.key, required this.value, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(height),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(trUpper(text), style: AppTheme.label()),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppColors.line)),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Her saniye yeniden çizilen alan (canlı sayaçlar için).
class LiveTick extends StatefulWidget {
  final WidgetBuilder builder;
  const LiveTick({super.key, required this.builder});

  @override
  State<LiveTick> createState() => _LiveTickState();
}

class _LiveTickState extends State<LiveTick> {
  late final Timer _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Nefes alan canlılık noktası.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, this.color = AppColors.live, this.size = 8});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: .45 * (1 - t) + .1),
                blurRadius: 4 + 8 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Liste öğeleri için sıralı, yumuşak giriş animasyonu.
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;
  const Entrance({super.key, required this.child, this.index = 0});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 45 * math.min(widget.index, 10)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .08), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}

/// Seviye ilerlemesini gösteren altın halka.
class LevelRing extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Widget child;

  const LevelRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 110,
    this.stroke = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => CustomPaint(painter: _RingPainter(v, stroke), child: c),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final double stroke;
  _RingPainter(this.v, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.line,
    );
    if (v <= 0) return;
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * v,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.goldDeep, AppColors.gold, AppColors.goldSoft],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}

/// Arka planda duran ince yörünge çizgileri (dekor).
class OrbitDecor extends StatelessWidget {
  final double size;
  const OrbitDecor({super.key, this.size = 360});

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(size: Size.square(size), painter: _OrbitPainter()));
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 4; i++) {
      final radius = size.width * (.2 + i * .1);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.gold.withValues(alpha: .10 - i * .02),
      );
    }
    final dots = [(.3, .7), (.4, 2.4), (.5, 4.2)];
    for (final (f, a) in dots) {
      final radius = size.width * f;
      canvas.drawCircle(
        c + Offset(math.cos(a) * radius, math.sin(a) * radius),
        2.5,
        Paint()..color = AppColors.gold.withValues(alpha: .5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────── Yardımcı fonksiyonlar ─────────────

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Async işlemi çalıştırır, hata olursa kullanıcıya Türkçe mesaj gösterir.
Future<bool> guard(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) toast(context, friendlyError(e));
    return false;
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .65),
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: AppColors.line),
      ),
      title: Text(title, style: AppTheme.serif(size: 22)),
      content: Text(message, style: AppTheme.sans(color: AppColors.textDim, height: 1.5)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Vazgeç', style: AppTheme.sans(color: AppColors.textDim, weight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action,
              style: AppTheme.sans(
                  color: danger ? AppColors.danger : AppColors.gold, weight: FontWeight.w800)),
        ),
      ],
    ),
  );
  return result ?? false;
}
