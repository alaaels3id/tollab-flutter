import 'package:flutter/material.dart';
import 'app_colors.dart';

enum PaymentStatus {
  paid,
  pending,
  partial,
  overdue;

  static PaymentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partial':
        return PaymentStatus.partial;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  String get dbValue => name;

  String get labelArabic {
    switch (this) {
      case PaymentStatus.paid:
        return 'تم السداد';
      case PaymentStatus.partial:
        return 'سداد جزئي';
      case PaymentStatus.pending:
        return 'قيد الانتظار';
      case PaymentStatus.overdue:
        return 'متأخر';
    }
  }

  String get iconSymbol {
    switch (this) {
      case PaymentStatus.paid:
        return '✓';
      case PaymentStatus.partial:
        return '◐';
      case PaymentStatus.pending:
        return '⏳';
      case PaymentStatus.overdue:
        return '⚠';
    }
  }

  IconData get iconData {
    switch (this) {
      case PaymentStatus.paid:
        return Icons.check_circle_rounded;
      case PaymentStatus.partial:
        return Icons.pie_chart_rounded;
      case PaymentStatus.pending:
        return Icons.hourglass_top_rounded;
      case PaymentStatus.overdue:
        return Icons.warning_rounded;
    }
  }

  Color get textColor {
    switch (this) {
      case PaymentStatus.paid:
        return AppColors.paidText;
      case PaymentStatus.partial:
        return AppColors.partialText;
      case PaymentStatus.pending:
        return AppColors.pendingText;
      case PaymentStatus.overdue:
        return AppColors.overdueText;
    }
  }

  Color get bgColor {
    switch (this) {
      case PaymentStatus.paid:
        return AppColors.paidBg;
      case PaymentStatus.partial:
        return AppColors.partialBg;
      case PaymentStatus.pending:
        return AppColors.pendingBg;
      case PaymentStatus.overdue:
        return AppColors.overdueBg;
    }
  }

  Color get borderColor {
    switch (this) {
      case PaymentStatus.paid:
        return AppColors.paidBorder;
      case PaymentStatus.partial:
        return AppColors.partialBorder;
      case PaymentStatus.pending:
        return AppColors.pendingBorder;
      case PaymentStatus.overdue:
        return AppColors.overdueBorder;
    }
  }

  Color get primaryColor {
    switch (this) {
      case PaymentStatus.paid:
        return AppColors.paidPrimary;
      case PaymentStatus.partial:
        return AppColors.partialPrimary;
      case PaymentStatus.pending:
        return AppColors.pendingPrimary;
      case PaymentStatus.overdue:
        return AppColors.overduePrimary;
    }
  }
}
