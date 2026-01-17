import 'package:flutter/material.dart';

/// Lumina App Theme - Professional & Sober Design System
class AppColors {
  // Primary palette
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMedium = Color(0xFF16213E);
  static const Color accent = Color(0xFF4A5568);

  // Surface colors
  static const Color surface = Color(0xFFFAFAFA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);

  // Text colors
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textMuted = Color(0xFFA0AEC0);

  // Status colors
  static const Color success = Color(0xFF38A169);
  static const Color successLight = Color(0xFFC6F6D5);
  static const Color error = Color(0xFFE53E3E);
  static const Color errorLight = Color(0xFFFED7D7);
  static const Color warning = Color(0xFFDD6B20);
  static const Color warningLight = Color(0xFFFEEBC8);
  static const Color info = Color(0xFF3182CE);
  static const Color infoLight = Color(0xFFBEE3F8);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

class AppShadows {
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppDecorations {
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      );

  static BoxDecoration get cardHovered => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: AppShadows.md,
      );

  static BoxDecoration get surface => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      );

  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.accent, size: 20)
          : null,
      suffix: suffix,
      filled: true,
      fillColor: AppColors.card,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

/// Common AppBar for all pages
PreferredSizeWidget buildAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  bool showBackButton = true,
  VoidCallback? onBack,
}) {
  return AppBar(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: showBackButton
        ? Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accent),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            ),
          )
        : null,
    title: Text(
      title,
      style: AppTextStyles.h3.copyWith(fontSize: 18),
    ),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        color: AppColors.border,
        height: 1,
      ),
    ),
  );
}

/// Primary button style
ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

/// Secondary button style
ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

/// Status badge widget
Widget buildStatusBadge(String status) {
  Color bgColor;
  Color textColor;

  switch (status.toLowerCase()) {
    case 'active':
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      break;
    case 'completed':
      bgColor = AppColors.infoLight;
      textColor = AppColors.info;
      break;
    case 'draft':
      bgColor = const Color(0xFFEDF2F7);
      textColor = AppColors.textSecondary;
      break;
    default:
      bgColor = const Color(0xFFEDF2F7);
      textColor = AppColors.textSecondary;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Message/Alert container
Widget buildAlertContainer({
  required String message,
  required bool isError,
  IconData? icon,
}) {
  final bgColor = isError ? AppColors.errorLight : AppColors.successLight;
  final borderColor = isError ? AppColors.error : AppColors.success;
  final textColor = isError ? AppColors.error : AppColors.success;
  final defaultIcon = isError ? Icons.error_outline_rounded : Icons.check_circle_rounded;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: borderColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(icon ?? defaultIcon, color: textColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

/// Info tip container
Widget buildInfoTip({required String message, IconData? icon}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.infoLight,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon ?? Icons.lightbulb_outline_rounded, color: AppColors.info, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.info, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    ),
  );
}
