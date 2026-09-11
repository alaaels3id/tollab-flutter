import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Converts integer cents/piastres to EGP
  static double centsToEgp(int cents) {
    return cents / 100.0;
  }

  /// Converts EGP to integer cents/piastres safely
  static int egpToCents(num egp) {
    return (egp * 100).round();
  }

  /// Format cents into Arabic Egyptian Pound string, e.g. "300 ج.م"
  static String formatEgp(int cents, {bool withSymbol = true}) {
    final egp = centsToEgp(cents);
    final formatter = NumberFormat('#,##0.##', 'ar_EG');
    final formatted = formatter.format(egp);
    return withSymbol ? '$formatted ج.م' : formatted;
  }

  /// Format EGP double into Arabic string
  static String formatDouble(double egp, {bool withSymbol = true}) {
    final formatter = NumberFormat('#,##0.##', 'ar_EG');
    final formatted = formatter.format(egp);
    return withSymbol ? '$formatted ج.م' : formatted;
  }

  /// Format into English string for search / debug, e.g. "300 EGP"
  static String formatEgpEn(int cents) {
    final egp = centsToEgp(cents);
    final formatter = NumberFormat('#,##0.##', 'en_US');
    return '${formatter.format(egp)} EGP';
  }
}
