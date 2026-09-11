import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import 'archive_controller.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(archiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرشيف الشهري', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Period Selector Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Month Selector
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: state.month,
                    decoration: const InputDecoration(
                      labelText: 'الشهر',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(12, (index) {
                      final m = index + 1;
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(DateFormatter.getArabicMonthName(m)),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(archiveProvider.notifier).loadArchive(val, state.year);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Year Selector
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: state.year,
                    decoration: const InputDecoration(
                      labelText: 'السنة',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(10, (index) {
                      final y = 2024 + index;
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text('$y'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(archiveProvider.notifier).loadArchive(state.month, val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Archive Content
          Expanded(
            child: state.summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ في تحميل الأرشيف: $err')),
              data: (summary) {
                if (summary.totalStudents == 0) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'لا توجد بيانات أرشيف لهذا الشهر',
                    subtitle: 'لم يتم تسجيل أي طلاب أو اشتراكات في ${DateFormatter.formatPeriodLabel(state.month, state.year)}.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(archiveProvider.notifier).loadArchive(state.month, state.year),
                  child: ListView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                    children: [
                      // Monthly Total Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ملخص ${DateFormatter.formatPeriodLabel(summary.month, summary.year)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${summary.totalGroups} مجموعات • ${summary.totalStudents} طالب',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildWhiteStat(label: 'المتوقع', value: CurrencyFormatter.formatEgp(summary.expectedTotalCents)),
                                _buildWhiteStat(label: 'المحصل', value: CurrencyFormatter.formatEgp(summary.collectedTotalCents)),
                                _buildWhiteStat(label: 'المتبقي', value: CurrencyFormatter.formatEgp(summary.outstandingTotalCents)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Breakdown per Group Title
                      const Text(
                        'تفاصيل المجموعات والاشتراكات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      // Group Expansion Cards
                      ...summary.groups.map((group) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              title: Row(
                                children: [
                                  Text(
                                    group.groupName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Text(
                                      '${group.studentCount} طالب',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      'المحصل: ${CurrencyFormatter.formatEgp(group.collectedCents)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.paidPrimary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'المتبقي: ${CurrencyFormatter.formatEgp(group.outstandingCents)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: group.outstandingCents > 0 ? AppColors.overduePrimary : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                const Divider(),
                                ...group.payments.map((p) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.studentNameSnapshot,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                              Text('كود: ${p.studentCode}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(CurrencyFormatter.formatEgp(p.amountPaidCents),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  if (p.remainingCents > 0)
                                                    Text('متبقي ${CurrencyFormatter.formatEgp(p.remainingCents)}',
                                                        style: const TextStyle(fontSize: 10, color: AppColors.overduePrimary)),
                                                ],
                                              ),
                                              const SizedBox(width: 10),
                                              StatusBadge(status: p.status, fontSize: 11),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
