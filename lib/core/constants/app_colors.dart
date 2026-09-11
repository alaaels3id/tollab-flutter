import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color secondary = Color(0xFF0F766E); // Deep Teal
  static const Color accent = Color(0xFF6366F1);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Status colors matching PRD & Electron
  // Paid (تم السداد) - Emerald
  static const Color paidText = Color(0xFF047857);
  static const Color paidBg = Color(0xFFECFDF5);
  static const Color paidBorder = Color(0xFFA7F3D0);
  static const Color paidPrimary = Color(0xFF10B981);

  // Partial (سداد جزئي) - Blue
  static const Color partialText = Color(0xFF1D4ED8);
  static const Color partialBg = Color(0xFFEFF6FF);
  static const Color partialBorder = Color(0xFFBFDBFE);
  static const Color partialPrimary = Color(0xFF3B82F6);

  // Pending (قيد الانتظار) - Amber
  static const Color pendingText = Color(0xFFB45309);
  static const Color pendingBg = Color(0xFFFFFBEB);
  static const Color pendingBorder = Color(0xFFFDE68A);
  static const Color pendingPrimary = Color(0xFFF59E0B);

  // Overdue (متأخر) - Rose/Red
  static const Color overdueText = Color(0xFFBE123C);
  static const Color overdueBg = Color(0xFFFFF1F2);
  static const Color overdueBorder = Color(0xFFFECDD3);
  static const Color overduePrimary = Color(0xFFF43F5E);

  // Inactive / Muted
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}
