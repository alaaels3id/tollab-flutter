import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/payment_status.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../payments/presentation/record_payment_dialog.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الرئيسية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: () => ref.read(dashboardProvider.notifier).loadStats(),
          ),
        ],
      ),
      body: statsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'حدث خطأ أثناء تحميل البيانات: $err',
                style: const TextStyle(color: AppColors.overduePrimary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(dashboardProvider.notifier).loadStats(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (stats) {
          final monthName = DateFormatter.getArabicMonthName(stats.month);

          return RefreshIndicator(
            onRefresh: () => ref.read(dashboardProvider.notifier).loadStats(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              children: [
                // Current Period Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نظرة عامة على اشتراكات الشهر',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$monthName ${stats.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${stats.collectionPercentage.toStringAsFixed(1)}% تم تحصيله',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Overview Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    StatCard(
                      title: 'إجمالي المتوقع',
                      value: CurrencyFormatter.formatEgp(
                        stats.expectedRevenueCents,
                      ),
                      subtitle: '${stats.activeStudents} طالب نشط',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.primary,
                    ),
                    StatCard(
                      title: 'المحصّل الفعلي',
                      value: CurrencyFormatter.formatEgp(
                        stats.collectedRevenueCents,
                      ),
                      subtitle:
                          'نسبة التحصيل: ${stats.collectionPercentage.toStringAsFixed(0)}%',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.paidPrimary,
                    ),
                    StatCard(
                      title: 'المتبقي للتحصيل',
                      value: CurrencyFormatter.formatEgp(
                        stats.outstandingRevenueCents,
                      ),
                      subtitle: '${stats.overdueCount} اشتراك متأخر',
                      icon: Icons.pending_actions_rounded,
                      iconColor: stats.outstandingRevenueCents > 0
                          ? AppColors.overduePrimary
                          : AppColors.textSecondary,
                    ),
                    StatCard(
                      title: 'المجموعات والطلاب',
                      value: '${stats.activeGroups} مجموعة',
                      subtitle: '${stats.activeStudents} طالب مسجل',
                      icon: Icons.group_rounded,
                      iconColor: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status Counts
                const Text(
                  'حالة الاشتراكات لهذا الشهر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatusCard(
                        status: PaymentStatus.paid,
                        count: stats.paidCount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatusCard(
                        status: PaymentStatus.partial,
                        count: stats.partialCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatusCard(
                        status: PaymentStatus.pending,
                        count: stats.pendingCount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatusCard(
                        status: PaymentStatus.overdue,
                        count: stats.overdueCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Upcoming Due Groups
                if (stats.upcomingDueGroups.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مواعيد السداد القادمة (خلال 7 أيام)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...stats.upcomingDueGroups.map(
                    (grp) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            '${grp.dueDay}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          grp.groupName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${grp.studentCount} طالب • الاشتراك: ${CurrencyFormatter.formatEgp(grp.feeCents)}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pendingBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.pendingBorder),
                          ),
                          child: Text(
                            DateFormatter.formatRelativeDueDate(grp.dueDay),
                            style: const TextStyle(
                              color: AppColors.pendingText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Overdue Payments Alert Section
                if (stats.overduePayments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اشتراكات متأخرة تحتاج متابعة (${stats.overduePayments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.overdueText,
                        ),
                      ),
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.overduePrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...stats.overduePayments.map(
                    (p) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.overdueBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        title: Row(
                          children: [
                            Text(
                              p.studentNameSnapshot,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${p.studentCode})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${p.groupNameSnapshot} • المتبقي: ${CurrencyFormatter.formatEgp(p.remainingCents)}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final updated = await RecordPaymentDialog.show(
                              context,
                              payment: p,
                            );
                            if (updated) {
                              ref.read(dashboardProvider.notifier).loadStats();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.overduePrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('سداد'),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStatusCard({
    required PaymentStatus status,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.borderColor),
      ),
      child: Column(
        children: [
          Text(
            status.iconSymbol,
            style: TextStyle(
              color: status.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              color: status.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status.labelArabic,
            style: TextStyle(
              color: status.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
