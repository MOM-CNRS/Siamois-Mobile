import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'siamois_colors.dart';

abstract final class SiamoisTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: SiamoisColors.primary,
      onPrimary: Colors.white,
      primaryContainer: SiamoisColors.primaryContainer,
      onPrimaryContainer: SiamoisColors.primaryDark,
      secondary: const Color(0xFF4A6274),
      onSecondary: Colors.white,
      secondaryContainer: SiamoisColors.surfaceMuted,
      onSecondaryContainer: SiamoisColors.textPrimary,
      tertiary: SiamoisColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: SiamoisColors.accentMuted,
      onTertiaryContainer: const Color(0xFF5C3A14),
      surface: SiamoisColors.surface,
      onSurface: SiamoisColors.textPrimary,
      onSurfaceVariant: SiamoisColors.textSecondary,
      outline: SiamoisColors.border,
      outlineVariant: SiamoisColors.borderSubtle,
      error: SiamoisColors.error,
      onError: Colors.white,
      surfaceContainerLowest: SiamoisColors.surfaceCard,
      surfaceContainerLow: SiamoisColors.surfaceMuted,
      surfaceContainer: const Color(0xFFE6E0D8),
      surfaceContainerHigh: const Color(0xFFDAD4CC),
      surfaceContainerHighest: const Color(0xFFCEC8C0),
    );

    // Corps + labels : Inter
    final interBase = GoogleFonts.interTextTheme();
    // Titres display : Lora (serif académique)
    final loraDisplay = GoogleFonts.loraTextTheme();

    final textTheme = interBase.copyWith(
      // Titres display en Lora
      displayLarge: loraDisplay.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: SiamoisColors.textPrimary,
      ),
      displayMedium: loraDisplay.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: SiamoisColors.textPrimary,
      ),
      displaySmall: loraDisplay.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: SiamoisColors.textPrimary,
      ),
      headlineLarge: loraDisplay.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: SiamoisColors.textPrimary,
      ),
      headlineMedium: loraDisplay.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: SiamoisColors.textPrimary,
      ),
      headlineSmall: loraDisplay.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: SiamoisColors.textPrimary,
      ),
      // Titres UI : Inter
      titleLarge: interBase.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: SiamoisColors.textPrimary,
        height: 1.25,
      ),
      titleMedium: interBase.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: SiamoisColors.textPrimary,
        height: 1.3,
      ),
      titleSmall: interBase.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: SiamoisColors.textPrimary,
      ),
      bodyLarge: interBase.bodyLarge?.copyWith(
        color: SiamoisColors.textPrimary,
        height: 1.45,
      ),
      bodyMedium: interBase.bodyMedium?.copyWith(
        color: SiamoisColors.textPrimary,
        height: 1.45,
      ),
      bodySmall: interBase.bodySmall?.copyWith(
        color: SiamoisColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: interBase.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: interBase.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: SiamoisColors.textSecondary,
      ),
      labelSmall: interBase.labelSmall?.copyWith(
        letterSpacing: 0.2,
        color: SiamoisColors.textTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SiamoisColors.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: SiamoisColors.surfaceCard,
        foregroundColor: SiamoisColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SiamoisColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SiamoisColors.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: SiamoisColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SiamoisColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiamoisColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiamoisColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiamoisColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiamoisColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiamoisColors.error, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: SiamoisColors.textSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: SiamoisColors.textTertiary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: SiamoisColors.border),
          foregroundColor: SiamoisColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SiamoisColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      // FAB en terre cuite pour un contraste visuel fort
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: SiamoisColors.accent,
        foregroundColor: Colors.white,
        extendedSizeConstraints: const BoxConstraints(minHeight: 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: SiamoisColors.primary, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
        labelColor: SiamoisColors.primary,
        unselectedLabelColor: SiamoisColors.textTertiary,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SiamoisColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: SiamoisColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SiamoisColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SiamoisColors.primary,
        linearTrackColor: SiamoisColors.surfaceMuted,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: SiamoisColors.textSecondary,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(
            SiamoisColors.surfaceCard,
          ),
          elevation: const WidgetStatePropertyAll(8),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              side: const BorderSide(color: SiamoisColors.borderSubtle),
            ),
          ),
        ),
        textStyle: textTheme.bodyLarge?.copyWith(
          color: SiamoisColors.textPrimary,
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(SiamoisColors.surfaceCard),
        side: const WidgetStatePropertyAll(
          BorderSide(color: SiamoisColors.border),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: SiamoisColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
