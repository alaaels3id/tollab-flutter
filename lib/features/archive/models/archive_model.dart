import '../../payments/models/monthly_payment_model.dart';

class GroupMonthlyArchiveSummary {
  final int groupId;
  final String groupName;
  final int studentCount;
  final int feeCents;
  final int expectedCents;
  final int collectedCents;
  final int outstandingCents;
  final int paidCount;
  final int partialCount;
  final int pendingCount;
  final int overdueCount;
  final List<MonthlyPaymentModel> payments;

  GroupMonthlyArchiveSummary({
    required this.groupId,
    required this.groupName,
    required this.studentCount,
    required this.feeCents,
    required this.expectedCents,
    required this.collectedCents,
    required this.outstandingCents,
    required this.paidCount,
    required this.partialCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.payments,
  });

  double get feeEgp => feeCents / 100.0;
  double get expectedEgp => expectedCents / 100.0;
  double get collectedEgp => collectedCents / 100.0;
  double get outstandingEgp => outstandingCents / 100.0;
}

class MonthArchiveSummary {
  final int month;
  final int year;
  final int totalGroups;
  final int totalStudents;
  final int expectedTotalCents;
  final int collectedTotalCents;
  final int outstandingTotalCents;
  final int paidCount;
  final int partialCount;
  final int pendingCount;
  final int overdueCount;
  final List<GroupMonthlyArchiveSummary> groups;

  MonthArchiveSummary({
    required this.month,
    required this.year,
    required this.totalGroups,
    required this.totalStudents,
    required this.expectedTotalCents,
    required this.collectedTotalCents,
    required this.outstandingTotalCents,
    required this.paidCount,
    required this.partialCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.groups,
  });

  double get expectedTotalEgp => expectedTotalCents / 100.0;
  double get collectedTotalEgp => collectedTotalCents / 100.0;
  double get outstandingTotalEgp => outstandingTotalCents / 100.0;
  double get collectionPercentage =>
      expectedTotalCents > 0 ? ((collectedTotalCents / expectedTotalCents) * 100).clamp(0.0, 100.0) : 0.0;
}
