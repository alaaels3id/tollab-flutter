import '../../payments/models/monthly_payment_model.dart';

class UpcomingDueGroup {
  final int groupId;
  final String groupName;
  final int dueDay;
  final int studentCount;
  final int feeCents;

  UpcomingDueGroup({
    required this.groupId,
    required this.groupName,
    required this.dueDay,
    required this.studentCount,
    required this.feeCents,
  });

  double get feeEgp => feeCents / 100.0;
}

class DashboardStatsModel {
  final int month;
  final int year;
  final int activeStudents;
  final int activeGroups;
  final int expectedRevenueCents;
  final int collectedRevenueCents;
  final int outstandingRevenueCents;
  final int paidCount;
  final int pendingCount;
  final int partialCount;
  final int overdueCount;
  final List<UpcomingDueGroup> upcomingDueGroups;
  final List<MonthlyPaymentModel> overduePayments;
  final List<MonthlyPaymentModel> recentPayments;

  DashboardStatsModel({
    required this.month,
    required this.year,
    required this.activeStudents,
    required this.activeGroups,
    required this.expectedRevenueCents,
    required this.collectedRevenueCents,
    required this.outstandingRevenueCents,
    required this.paidCount,
    required this.pendingCount,
    required this.partialCount,
    required this.overdueCount,
    required this.upcomingDueGroups,
    required this.overduePayments,
    required this.recentPayments,
  });

  double get expectedRevenueEgp => expectedRevenueCents / 100.0;
  double get collectedRevenueEgp => collectedRevenueCents / 100.0;
  double get outstandingRevenueEgp => outstandingRevenueCents / 100.0;
  double get collectionPercentage =>
      expectedRevenueCents > 0 ? ((collectedRevenueCents / expectedRevenueCents) * 100).clamp(0.0, 100.0) : 0.0;
}
