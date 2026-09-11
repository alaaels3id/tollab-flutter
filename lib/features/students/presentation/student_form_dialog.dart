import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../groups/presentation/groups_controller.dart';
import '../models/student_model.dart';
import 'student_form_screen.dart';
import 'students_controller.dart';

class StudentFormDialog extends ConsumerStatefulWidget {
  final StudentModel? studentToEdit;
  final int? initialGroupId;

  const StudentFormDialog({super.key, this.studentToEdit, this.initialGroupId});

  static Future<bool> show(
    BuildContext context, {
    StudentModel? studentToEdit,
    int? initialGroupId,
  }) async {
    final result = await StudentFormScreen.navigate(
      context,
      studentToEdit: studentToEdit,
      initialGroupId: initialGroupId,
    );
    return result ?? false;
  }

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  int? _selectedGroupId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.studentToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _selectedGroupId = s?.groupId ?? widget.initialGroupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المجموعة الدراسية'), backgroundColor: AppColors.overduePrimary),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (widget.studentToEdit != null) {
        final updated = widget.studentToEdit!.copyWith(
          name: name,
          phone: phone,
          notes: notes,
        );
        await ref.read(studentsProvider.notifier).updateStudent(updated);
      } else {
        await ref.read(studentsProvider.notifier).addStudent(
          name: name,
          groupId: _selectedGroupId!,
          phone: phone,
          notes: notes,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.overduePrimary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.studentToEdit != null;
    final groupsAsync = ref.watch(groupsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEditing ? 'تعديل بيانات الطالب' : 'إضافة طالب جديد',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اسم الطالب *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'مثال: أحمد محمد علي'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الطالب' : null,
              ),
              const SizedBox(height: 14),

              if (!isEditing) ...[
                const Text('المجموعة الدراسية *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                groupsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ في تحميل المجموعات: $e'),
                  data: (groups) {
                    final activeGroups = groups.where((g) => g.isActive).toList();
                    if (activeGroups.isEmpty) {
                      return const Text('لا توجد مجموعات نشطة متاحة. يرجى إنشاء مجموعة أولاً.',
                          style: TextStyle(color: AppColors.overduePrimary));
                    }
                    if (_selectedGroupId == null && activeGroups.isNotEmpty) {
                      _selectedGroupId = activeGroups.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedGroupId,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      items: activeGroups.map((g) => DropdownMenuItem<int>(
                        value: g.id,
                        child: Text(g.name),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedGroupId = val),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

              const Text('رقم الهاتف (اختياري)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '01XXXXXXXXX'),
              ),
              const SizedBox(height: 14),

              const Text('ملاحظات (اختياري)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'مستوى الطالب أو ولي الأمر...'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEditing ? 'حفظ التعديلات' : 'إضافة الطالب'),
        ),
      ],
    );
  }
}
