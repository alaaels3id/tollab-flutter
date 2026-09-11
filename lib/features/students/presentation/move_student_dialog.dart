import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../groups/presentation/groups_controller.dart';
import '../models/student_model.dart';
import 'students_controller.dart';

class MoveStudentDialog extends ConsumerStatefulWidget {
  final StudentModel student;

  const MoveStudentDialog({super.key, required this.student});

  static Future<bool> show(BuildContext context, {required StudentModel student}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => MoveStudentDialog(student: student),
    );
    return result ?? false;
  }

  @override
  ConsumerState<MoveStudentDialog> createState() => _MoveStudentDialogState();
}

class _MoveStudentDialogState extends ConsumerState<MoveStudentDialog> {
  int? _newGroupId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('نقل الطالب إلى مجموعة أخرى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الطالب: ${widget.student.name} (${widget.student.studentCode})',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'المجموعة الحالية: ${widget.student.groupName ?? '—'}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            const Text('اختر المجموعة الجديدة *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            groupsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (groups) {
                final eligible = groups.where((g) => g.isActive && g.id != widget.student.groupId).toList();
                if (eligible.isEmpty) {
                  return const Text('لا توجد مجموعات نشطة أخرى متاحة للنقل إليها.',
                      style: TextStyle(color: AppColors.overduePrimary, fontSize: 13));
                }
                _newGroupId ??= eligible.first.id;

                return DropdownButtonFormField<int>(
                  initialValue: _newGroupId,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: eligible.map((g) => DropdownMenuItem<int>(
                    value: g.id,
                    child: Text(g.name),
                  )).toList(),
                  onChanged: (val) => setState(() => _newGroupId = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // Historical integrity notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pendingBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pendingBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.pendingText),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ملاحظة هامة: نقل الطالب سيؤثر فقط على الاشتراكات المستقبلية. الاشتراكات السابقة في المجموعة القديمة ستظل محفوظة بالكامل دون أي تعديل.',
                      style: TextStyle(fontSize: 12, color: AppColors.pendingText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _newGroupId == null)
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(studentsProvider.notifier).moveStudentGroup(widget.student.id, _newGroupId!);
                    if (context.mounted) Navigator.of(context).pop(true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.overduePrimary),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('تأكيد النقل'),
        ),
      ],
    );
  }
}
