import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lonca renk paleti — sıcak siyahlar ve yumuşak altın tonları.
class AppColors {
  static const ink = Color(0xFF0A0907); // ana arka plan
  static const coal = Color(0xFF110F0C); // paneller
  static const surface = Color(0xFF191612); // kartlar
  static const surfaceHi = Color(0xFF221E18); // yükseltilmiş kartlar
  static const line = Color(0xFF2C2720); // ince çizgiler

  static const gold = Color(0xFFD6B06C);
  static const goldSoft = Color(0xFFEDD6A6);
  static const goldDeep = Color(0xFF94713A);

  static const text = Color(0xFFF3ECDE);
  static const textDim = Color(0xFF9B937F);
  static const textFaint = Color(0xFF5F584B);

  static const live = Color(0xFFA9CFA2); // aktiflik için yumuşak adaçayı yeşili
  static const danger = Color(0xFFDB8E7B);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldSoft, gold, goldDeep],
    stops: [0, .55, 1],
  );
}

class AppTheme {
  static TextStyle serif({
    double size = 24,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
    double? height,
    double letterSpacing = -0.4,
    FontStyle? style,
    List<FontFeature>? features,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: style,
        fontFeatures: features,
      );

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
    double? height,
    double letterSpacing = 0,
    FontStyle? style,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: style,
      );

  /// Küçük, aralıklı, büyük harfli etiket stili.
  static TextStyle label({Color color = AppColors.textDim, double size = 10.5}) =>
      sans(size: size, weight: FontWeight.w800, color: color, letterSpacing: 2);

  /// Sabit genişlikli rakamlar (sayaçlar titremesin diye).
  static TextStyle clock({double size = 32, Color color = AppColors.gold}) => serif(
        size: size,
        color: color,
        weight: FontWeight.w400,
        letterSpacing: 0.5,
        features: const [FontFeature.tabularFigures()],
      );

  static ThemeData build() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final text = GoogleFonts.manropeTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      canvasColor: AppColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.ink,
        secondary: AppColors.goldSoft,
        onSecondary: AppColors.ink,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
        onError: AppColors.ink,
        outline: AppColors.line,
        outlineVariant: AppColors.line,
      ),
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: AppColors.gold.withValues(alpha: 0.06),
      dividerColor: AppColors.line,
      iconTheme: const IconThemeData(color: AppColors.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: AppColors.gold.withValues(alpha: .3),
        selectionHandleColor: AppColors.gold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: sans(color: AppColors.textFaint),
        labelStyle: sans(color: AppColors.textDim),
        floatingLabelStyle: sans(color: AppColors.gold),
        prefixIconColor: AppColors.textDim,
        suffixIconColor: AppColors.textDim,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.gold.withValues(alpha: .8), 1.2),
        errorBorder: border(AppColors.danger.withValues(alpha: .7)),
        focusedErrorBorder: border(AppColors.danger, 1.2),
        errorStyle: sans(size: 12, color: AppColors.danger),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHi,
        contentTextStyle: sans(color: AppColors.text),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.coal,
        modalBackgroundColor: AppColors.coal,
        showDragHandle: true,
        dragHandleColor: AppColors.line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ink : AppColors.textDim),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold : AppColors.surfaceHi),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: SoftPageTransitions(),
        TargetPlatform.iOS: SoftPageTransitions(),
      }),
    );
  }
}

/// Sayfalar arası yumuşak geçiş: hafif yukarı kayma + solma.
class SoftPageTransitions extends PageTransitionsBuilder {
  const SoftPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final behind = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: .35).animate(behind),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

