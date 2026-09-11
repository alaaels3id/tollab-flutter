import '../../../core/constants/payment_status.dart';

class MonthlyPaymentModel {
  final int id;
  final int monthlyPeriodId;
  final int studentId;
  final String studentCode;
  final int groupId;
  final String studentNameSnapshot;
  final String groupNameSnapshot;
  final int amountDueCents;
  final int amountPaidCents;
  final String dueDate; // YYYY-MM-DD
  final PaymentStatus status;
  final String? paidAt;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  MonthlyPaymentModel({
    required this.id,
    required this.monthlyPeriodId,
    required this.studentId,
    required this.studentCode,
    required this.groupId,
    required this.studentNameSnapshot,
    required this.groupNameSnapshot,
    required this.amountDueCents,
    required this.amountPaidCents,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get amountDueEgp => amountDueCents / 100.0;
  double get amountPaidEgp => amountPaidCents / 100.0;
  int get remainingCents => (amountDueCents - amountPaidCents) > 0 ? (amountDueCents - amountPaidCents) : 0;
  double get remainingEgp => remainingCents / 100.0;

  factory MonthlyPaymentModel.fromMap(Map<String, dynamic> map) {
    return MonthlyPaymentModel(
      id: map['id'] as int,
      monthlyPeriodId: map['monthly_period_id'] as int,
      studentId: map['student_id'] as int,
      studentCode: (map['student_code'] as String?) ?? '',
      groupId: map['group_id'] as int,
      studentNameSnapshot: map['student_name_snapshot'] as String,
      groupNameSnapshot: map['group_name_snapshot'] as String,
      amountDueCents: map['amount_due_cents'] as int,
      amountPaidCents: map['amount_paid_cents'] as int,
      dueDate: map['due_date'] as String,
      status: PaymentStatus.fromString(map['status'] as String? ?? 'pending'),
      paidAt: map['paid_at'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'monthly_period_id': monthlyPeriodId,
      'student_id': studentId,
      'group_id': groupId,
      'student_name_snapshot': studentNameSnapshot,
      'group_name_snapshot': groupNameSnapshot,
      'amount_due_cents': amountDueCents,
      'amount_paid_cents': amountPaidCents,
      'due_date': dueDate,
      'status': status.dbValue,
      'paid_at': paidAt,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
