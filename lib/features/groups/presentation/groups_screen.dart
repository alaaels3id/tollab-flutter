import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../students/presentation/students_controller.dart';
import 'group_form_screen.dart';
import 'groups_controller.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  bool _activeOnly = false;

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المجموعات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          FilterChip(
            label: Text(_activeOnly ? 'النشطة فقط' : 'الكل'),
            selected: _activeOnly,
            onSelected: (val) {
              setState(() => _activeOnly = val);
              ref.read(groupsProvider.notifier).loadGroups(activeOnly: val);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'مجموعة جديدة',
            onPressed: () => GroupFormScreen.navigate(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ: $err')),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: 'لا توجد مجموعات حتى الآن',
              subtitle: 'قم بإنشاء مجموعتك الأولى لتتمكن من إضافة الطلاب وتوليد الاشتراكات الشهرية.',
              actionLabel: 'إنشاء مجموعة جديدة',
              onAction: () => GroupFormScreen.navigate(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(groupsProvider.notifier).loadGroups(activeOnly: _activeOnly),
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: group.isActive
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    child: Icon(
                                      Icons.group,
                                      color: group.isActive ? AppColors.primary : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: group.isActive ? AppColors.textPrimary : AppColors.textMuted,
                                          ),
                                        ),
                                        if (group.description != null && group.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            group.description!,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  GroupFormScreen.navigate(context, groupToEdit: group);
                                } else if (val == 'toggle') {
                                  await ref.read(groupsProvider.notifier).toggleStatus(group.id, !group.isActive);
                                } else if (val == 'delete') {
                                  final confirmed = await ConfirmDialog.show(
                                    context,
                                    title: 'حذف المجموعة',
                                    message: 'هل أنت متأكد من رغبتك في حذف مجموعة "${group.name}"؟',
                                    confirmText: 'حذف',
                                    isDestructive: true,
                                  );
                                  if (confirmed) {
                                    try {
                                      await ref.read(groupsProvider.notifier).deleteGroup(group.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم حذف المجموعة بنجاح'),
                                            backgroundColor: AppColors.paidPrimary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        final forceConfirm = await ConfirmDialog.show(
                                          context,
                                          title: 'حذف إجباري للمجموعة',
                                          message: '${e.toString().replaceAll('Exception: ', '')}\n\nهل ترغب في الحذف الإجباري لمسح المجموعة مع كافة طلابها وسجلات اشتراكاتهم نهائياً؟',
                                          confirmText: 'حذف إجباري نهائي',
                                          isDestructive: true,
                                        );
                                        if (forceConfirm) {
                                          try {
                                            await ref.read(groupsProvider.notifier).deleteGroup(group.id, force: true);
                                            ref.read(studentsProvider.notifier).loadStudents();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('تم الحذف الإجباري للمجموعة وكافة طلابها وسجلاتها بنجاح'),
                                                  backgroundColor: AppColors.paidPrimary,
                                                ),
                                              );
                                            }
                                          } catch (e2) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(e2.toString().replaceAll('Exception: ', '')),
                                                  backgroundColor: AppColors.overduePrimary,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                } else if (val == 'force_delete') {
                                  final confirmed = await ConfirmDialog.show(
                                    context,
                                    title: 'حذف إجباري للمجموعة',
                                    message: 'تحذير شديد: سيتم حذف المجموعة "${group.name}" وجميع الطلاب المنتمين إليها وكافة سجلات الاشتراكات المرتبطة بها نهائياً. هذا الإجراء لا يمكن التراجع عنه.',
                                    confirmText: 'حذف إجباري نهائي',
                                    isDestructive: true,
                                  );
                                  if (confirmed) {
                                    try {
                                      await ref.read(groupsProvider.notifier).deleteGroup(group.id, force: true);
                                      ref.read(studentsProvider.notifier).loadStudents();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم الحذف الإجباري للمجموعة بنجاح'),
                                            backgroundColor: AppColors.paidPrimary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: AppColors.overduePrimary,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('تعديل البيانات'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        group.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(group.isActive ? 'إلغاء التفعيل' : 'تفعيل المجموعة'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: AppColors.overduePrimary),
                                      SizedBox(width: 8),
                                      Text('حذف', style: TextStyle(color: AppColors.overduePrimary)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'force_delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.overduePrimary),
                                      SizedBox(width: 8),
                                      Text('حذف إجباري', style: TextStyle(color: AppColors.overduePrimary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetaBadge(
                              icon: Icons.attach_money_rounded,
                              label: 'الاشتراك',
                              value: CurrencyFormatter.formatEgp(group.monthlyFeeCents),
                              color: AppColors.primary,
                            ),
                            _buildMetaBadge(
                              icon: Icons.calendar_today_rounded,
                              label: 'الاستحقاق',
                              value: 'يوم ${group.dueDay} (${DateFormatter.formatRelativeDueDate(group.dueDay)})',
                              color: AppColors.pendingText,
                            ),
                            _buildMetaBadge(
                              icon: Icons.person_outline_rounded,
                              label: 'الطلاب',
                              value: '${group.studentCount} طالب',
                              color: AppColors.secondary,
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
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
