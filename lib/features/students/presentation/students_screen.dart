import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../groups/presentation/groups_controller.dart';
import 'move_student_dialog.dart';
import 'student_form_screen.dart';
import 'students_controller.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsProvider);
    final groupsState = ref.watch(groupsProvider);
    final filter = ref.read(studentsProvider.notifier).filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلاب', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'طالب جديد',
            onPressed: () => StudentFormScreen.navigate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Group Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، الكود، أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(studentsProvider.notifier).setFilter(filter.copyWith(query: ''));
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    ref.read(studentsProvider.notifier).setFilter(filter.copyWith(query: val));
                  },
                ),
                const SizedBox(height: 10),

                // Group Filter Chips
                groupsState.maybeWhen(
                  data: (groups) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('جميع المجموعات'),
                            selected: filter.groupId == null,
                            onSelected: (_) {
                              ref.read(studentsProvider.notifier).setFilter(filter.copyWith(clearGroup: true));
                            },
                          ),
                          const SizedBox(width: 8),
                          ...groups.where((g) => g.isActive).map((g) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(g.name),
                                  selected: filter.groupId == g.id,
                                  onSelected: (selected) {
                                    ref.read(studentsProvider.notifier).setFilter(
                                          filter.copyWith(groupId: selected ? g.id : null, clearGroup: !selected),
                                        );
                                  },
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: studentsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
              data: (students) {
                if (students.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'لا يوجد طلاب مطابقين للبحث',
                    subtitle: filter.query.isNotEmpty || filter.groupId != null
                        ? 'جرّب تعديل خيارات البحث أو الفلتر أعلاه.'
                        : 'أضف أول طالب في مجموعاتك التعليمية لبدء المتابعة.',
                    actionLabel: (filter.query.isEmpty && filter.groupId == null) ? 'إضافة طالب جديد' : null,
                    onAction: () => StudentFormScreen.navigate(context),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(studentsProvider.notifier).loadStudents(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
                    itemCount: students.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: student.isActive
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.person,
                              color: student.isActive ? AppColors.primary : Colors.grey,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                student.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: student.isActive ? AppColors.textPrimary : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  student.studentCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    student.groupName ?? 'بدون مجموعة',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  if (student.phone != null && student.phone!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      student.phone!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                              if (student.notes != null && student.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  student.notes!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'edit') {
                                StudentFormScreen.navigate(context, studentToEdit: student);
                              } else if (val == 'move') {
                                MoveStudentDialog.show(context, student: student);
                              } else if (val == 'toggle') {
                                await ref.read(studentsProvider.notifier).toggleStatus(student.id, !student.isActive);
                              } else if (val == 'delete') {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'حذف الطالب',
                                  message: 'هل أنت متأكد من حذف الطالب "${student.name}"؟',
                                  confirmText: 'حذف',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  try {
                                    await ref.read(studentsProvider.notifier).deleteStudent(student.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم حذف الطالب بنجاح'),
                                          backgroundColor: AppColors.paidPrimary,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      final forceConfirm = await ConfirmDialog.show(
                                        context,
                                        title: 'حذف إجباري للطالب',
                                        message: '${e.toString().replaceAll('Exception: ', '')}\n\nهل ترغب في الحذف الإجباري لمسح الطالب وكافة سجلاته نهائياً؟',
                                        confirmText: 'حذف إجباري نهائي',
                                        isDestructive: true,
                                      );
                                      if (forceConfirm) {
                                        try {
                                          await ref.read(studentsProvider.notifier).deleteStudent(student.id, force: true);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('تم الحذف الإجباري للطالب بنجاح'),
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
                                  title: 'حذف إجباري للطالب',
                                  message: 'تحذير: سيتم حذف الطالب "${student.name}" نهائياً وجميع سجلات الاشتراكات والدفع المرتبطة به. لا يمكن التراجع عن هذا الإجراء.',
                                  confirmText: 'حذف إجباري نهائي',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  try {
                                    await ref.read(studentsProvider.notifier).deleteStudent(student.id, force: true);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم الحذف الإجباري للطالب بنجاح'),
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
                              const PopupMenuItem(
                                value: 'move',
                                child: Row(
                                  children: [
                                    Icon(Icons.drive_file_move_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('نقل إلى مجموعة أخرى'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      student.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(student.isActive ? 'إلغاء التفعيل' : 'تفعيل الطالب'),
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
}
