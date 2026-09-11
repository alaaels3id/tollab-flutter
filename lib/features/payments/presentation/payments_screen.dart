import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/payment_status.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../groups/presentation/groups_controller.dart';
import 'payments_controller.dart';
import 'record_payment_dialog.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _nextMonth() {
    final cur = ref.read(paymentsProvider);
    if (cur.month == 12) {
      ref.read(paymentsProvider.notifier).setPeriod(1, cur.year + 1);
    } else {
      ref.read(paymentsProvider.notifier).setPeriod(cur.month + 1, cur.year);
    }
  }

  void _prevMonth() {
    final cur = ref.read(paymentsProvider);
    if (cur.month == 1) {
      ref.read(paymentsProvider.notifier).setPeriod(12, cur.year - 1);
    } else {
      ref.read(paymentsProvider.notifier).setPeriod(cur.month - 1, cur.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);
    final groupsState = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراكات الشهرية', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Period Selector Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  tooltip: 'الشهر السابق',
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormatter.formatPeriodLabel(state.month, state.year),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  tooltip: 'الشهر القادم',
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filters & Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الطالب أو الكود...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(paymentsProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    ref.read(paymentsProvider.notifier).setQuery(val);
                  },
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(label: 'الكل', value: null, selected: state.status == null),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'متأخر ⚠',
                        value: 'overdue',
                        selected: state.status == 'overdue',
                        activeColor: AppColors.overduePrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'قيد الانتظار ⏳',
                        value: 'pending',
                        selected: state.status == 'pending',
                        activeColor: AppColors.pendingPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'سداد جزئي ◐',
                        value: 'partial',
                        selected: state.status == 'partial',
                        activeColor: AppColors.partialPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'تم السداد ✓',
                        value: 'paid',
                        selected: state.status == 'paid',
                        activeColor: AppColors.paidPrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Group Filter Dropdown
                groupsState.maybeWhen(
                  data: (groups) {
                    final active = groups.where((g) => g.isActive).toList();
                    return DropdownButtonFormField<int?>(
                      key: ValueKey(state.groupId),
                      initialValue: state.groupId,
                      decoration: const InputDecoration(
                        labelText: 'تصفية حسب المجموعة',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('جميع المجموعات')),
                        ...active.map((g) => DropdownMenuItem<int?>(
                              value: g.id,
                              child: Text(g.name),
                            )),
                      ],
                      onChanged: (val) => ref.read(paymentsProvider.notifier).setGroup(val),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: state.payments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
              data: (payments) {
                if (payments.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا توجد سجلات اشتراكات مطابقة',
                    subtitle: 'تأكد من وجود طلاب ومجموعات نشطة أو جرّب إزالة الفلاتر.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(paymentsProvider.notifier).loadPayments(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
                    itemCount: payments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          p.studentNameSnapshot,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${p.studentCode})',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: p.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'المجموعة: ${p.groupNameSnapshot}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تاريخ الاستحقاق: ${DateFormatter.formatFullArabicDate(p.dueDate)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المطلوب: ${CurrencyFormatter.formatEgp(p.amountDueCents)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'المدفوع: ${CurrencyFormatter.formatEgp(p.amountPaidCents)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.amountPaidCents > 0 ? AppColors.paidPrimary : AppColors.textMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (p.remainingCents > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'المتبقي: ${CurrencyFormatter.formatEgp(p.remainingCents)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.overduePrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => RecordPaymentDialog.show(context, payment: p),
                                    icon: const Icon(Icons.payment, size: 16),
                                    label: Text(p.status == PaymentStatus.paid ? 'تعديل السداد' : 'تسجيل سداد'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: p.status == PaymentStatus.paid ? AppColors.primary : AppColors.secondary,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required String? value,
    required bool selected,
    Color? activeColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: (activeColor ?? AppColors.primary).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? (activeColor ?? AppColors.primary) : AppColors.textSecondary,
      ),
      onSelected: (_) {
        ref.read(paymentsProvider.notifier).setStatus(value);
      },
    );
  }
}
