import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/payment_status.dart';
import '../data/payment_repository.dart';
import '../models/monthly_payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

class PaymentsState {
  final int month;
  final int year;
  final int? groupId;
  final String? status;
  final String query;
  final AsyncValue<List<MonthlyPaymentModel>> payments;

  PaymentsState({
    required this.month,
    required this.year,
    this.groupId,
    this.status,
    this.query = '',
    required this.payments,
  });

  PaymentsState copyWith({
    int? month,
    int? year,
    int? groupId,
    bool clearGroup = false,
    String? status,
    bool clearStatus = false,
    String? query,
    AsyncValue<List<MonthlyPaymentModel>>? payments,
  }) {
    return PaymentsState(
      month: month ?? this.month,
      year: year ?? this.year,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      status: clearStatus ? null : (status ?? this.status),
      query: query ?? this.query,
      payments: payments ?? this.payments,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final PaymentRepository _repository;

  PaymentsNotifier(this._repository)
      : super(PaymentsState(
          month: DateTime.now().month,
          year: DateTime.now().year,
          payments: const AsyncValue.loading(),
        )) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = state.copyWith(payments: const AsyncValue.loading());
    try {
      final list = await _repository.getMonthlyPayments(
        state.month,
        state.year,
        groupId: state.groupId,
        status: state.status,
        query: state.query,
      );
      state = state.copyWith(payments: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(payments: AsyncValue.error(e, st));
    }
  }

  void setPeriod(int month, int year) {
    state = state.copyWith(month: month, year: year);
    loadPayments();
  }

  void setGroup(int? groupId) {
    state = state.copyWith(groupId: groupId, clearGroup: groupId == null);
    loadPayments();
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
    loadPayments();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    loadPayments();
  }

  Future<void> recordPayment({
    required int paymentId,
    required int amountPaidCents,
    PaymentStatus? customStatus,
    String? notes,
  }) async {
    await _repository.recordPayment(
      paymentId: paymentId,
      amountPaidCents: amountPaidCents,
      customStatus: customStatus,
      notes: notes,
    );
    await loadPayments();
  }
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return PaymentsNotifier(repo);
});
