import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ─────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF6366F1);        // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary palette
  static const Color secondary = Color(0xFF10B981);      // Emerald
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color info = Color(0xFF3B82F6);

  // Light mode
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightOutline = Color(0xFFE5E7EB);
  static const Color lightOutlineVariant = Color(0xFF9CA3AF);
  static const Color lightOnSurface = Color(0xFF1F2937);
  static const Color lightOnSurfaceVariant = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOutline = Color(0xFF475569);
  static const Color darkOutlineVariant = Color(0xFF64748B);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, primary],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // Message bubbles
  static const Color myMessageBubble = primary;
  static const Color partnerMessageBubble = Color(0xFFE5E7EB);
  static const Color partnerMessageBubbleDark = Color(0xFF334155);
}

// ─── Theme ──────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.lightOutline,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme, AppColors.lightOnSurface),
      appBarTheme: _buildAppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        shadowColor: AppColors.lightOutline,
      ),
      cardTheme: _buildCardTheme(AppColors.lightSurface),
      inputDecorationTheme: _buildInputTheme(
        fillColor: AppColors.lightSurfaceVariant,
        borderColor: AppColors.lightOutline,
        focusedBorderColor: AppColors.primary,
        labelColor: AppColors.lightOnSurfaceVariant,
        hintColor: AppColors.lightOutlineVariant,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(AppColors.primary),
      textButtonTheme: _buildTextButtonTheme(AppColors.primary),
      bottomNavigationBarTheme: _buildBottomNavTheme(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.lightOutlineVariant,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
      ),
      chipTheme: _buildChipTheme(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.primary,
        labelColor: AppColors.lightOnSurface,
      ),
      switchTheme: _buildSwitchTheme(AppColors.primary),
      checkboxTheme: _buildCheckboxTheme(AppColors.primary),
      dialogTheme: _buildDialogTheme(AppColors.lightSurface),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkOutline,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme, AppColors.darkOnSurface),
      appBarTheme: _buildAppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        shadowColor: AppColors.darkOutline,
      ),
      cardTheme: _buildCardTheme(AppColors.darkSurface),
      inputDecorationTheme: _buildInputTheme(
        fillColor: AppColors.darkSurfaceVariant,
        borderColor: AppColors.darkOutline,
        focusedBorderColor: AppColors.primary,
        labelColor: AppColors.darkOnSurfaceVariant,
        hintColor: AppColors.darkOutlineVariant,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(AppColors.primaryLight),
      textButtonTheme: _buildTextButtonTheme(AppColors.primaryLight),
      bottomNavigationBarTheme: _buildBottomNavTheme(
        backgroundColor: AppColors.darkSurface,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.darkOutlineVariant,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
      ),
      chipTheme: _buildChipTheme(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary,
        labelColor: AppColors.darkOnSurface,
      ),
      switchTheme: _buildSwitchTheme(AppColors.primary),
      checkboxTheme: _buildCheckboxTheme(AppColors.primary),
      dialogTheme: _buildDialogTheme(AppColors.darkSurface),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  // ─── Private builders ─────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    final poppins = GoogleFonts.poppinsTextTheme(base);
    return poppins.copyWith(
      displayLarge:  poppins.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: poppins.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      displaySmall:  poppins.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      headlineLarge:  poppins.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      headlineMedium: poppins.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall:  poppins.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleLarge:  poppins.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: poppins.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      titleSmall:  poppins.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge:  poppins.bodyLarge?.copyWith(color: textColor),
      bodyMedium: poppins.bodyMedium?.copyWith(color: textColor),
      bodySmall:  poppins.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.7)),
      labelLarge:  poppins.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      labelMedium: poppins.labelMedium?.copyWith(color: textColor),
      labelSmall:  poppins.labelSmall?.copyWith(color: textColor.withValues(alpha: 0.7)),
    );
  }

  static AppBarTheme _buildAppBarTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color shadowColor,
  }) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: shadowColor,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: foregroundColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: foregroundColor),
    );
  }

  static CardThemeData _buildCardTheme(Color color) {
    return CardThemeData(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static InputDecorationTheme _buildInputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusedBorderColor,
    required Color labelColor,
    required Color hintColor,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: focusedBorderColor, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      labelStyle: GoogleFonts.poppins(color: labelColor, fontSize: 14),
      hintStyle: GoogleFonts.poppins(color: hintColor, fontSize: 14),
      errorStyle: GoogleFonts.poppins(color: AppColors.error, fontSize: 12),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return focusedBorderColor;
        return labelColor;
      }),
      suffixIconColor: labelColor,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color color) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Color color) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme({
    required Color backgroundColor,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    return BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
    );
  }

  static ChipThemeData _buildChipTheme({
    required Color backgroundColor,
    required Color selectedColor,
    required Color labelColor,
  }) {
    return ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: selectedColor.withValues(alpha: 0.15),
      checkmarkColor: selectedColor,
      labelStyle: GoogleFonts.poppins(color: labelColor, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: backgroundColor),
    );
  }

  static SwitchThemeData _buildSwitchTheme(Color color) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color;
        return AppColors.lightOutline;
      }),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(Color color) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  static DialogThemeData _buildDialogTheme(Color backgroundColor) {
    return DialogThemeData(
      backgroundColor: backgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.poppins(fontSize: 14),
    );
  }
}
