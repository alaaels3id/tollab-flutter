import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../groups/presentation/group_form_screen.dart';
import '../../groups/presentation/groups_controller.dart';
import '../models/student_model.dart';
import 'students_controller.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  final StudentModel? studentToEdit;
  final int? initialGroupId;

  const StudentFormScreen({
    super.key,
    this.studentToEdit,
    this.initialGroupId,
  });

  static Future<bool?> navigate(
    BuildContext context, {
    StudentModel? studentToEdit,
    int? initialGroupId,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => StudentFormScreen(
          studentToEdit: studentToEdit,
          initialGroupId: initialGroupId,
        ),
      ),
    );
  }

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  int? _selectedGroupId;
  bool _isLoading = false;

  bool get isEditing => widget.studentToEdit != null;

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
    if (_selectedGroupId == null && !isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المجموعة الدراسية'),
          backgroundColor: AppColors.overduePrimary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (isEditing) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تعديل بيانات الطالب بنجاح' : 'تمت إضافة الطالب بنجاح'),
            backgroundColor: AppColors.paidPrimary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.overduePrimary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل بيانات الطالب' : 'إضافة طالب جديد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Avatar & Info Card
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name field
                const Text(
                  'اسم الطالب *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'مثال: أحمد محمد علي',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الطالب' : null,
                ),
                const SizedBox(height: 20),

                // Group field (only for new students)
                if (!isEditing) ...[
                  const Text(
                    'المجموعة الدراسية *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  groupsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('خطأ في تحميل المجموعات: $e'),
                    data: (groups) {
                      final activeGroups = groups.where((g) => g.isActive).toList();
                      if (activeGroups.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.overdueBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.overdueBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: AppColors.overduePrimary, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'لا توجد مجموعات نشطة متاحة. يرجى إنشاء مجموعة أولاً.',
                                      style: TextStyle(
                                        color: AppColors.overdueText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => GroupFormScreen.navigate(context),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('إنشاء مجموعة الآن'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  foregroundColor: AppColors.overdueText,
                                  side: const BorderSide(color: AppColors.overduePrimary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_selectedGroupId == null && activeGroups.isNotEmpty) {
                        _selectedGroupId = activeGroups.first.id;
                      }

                      return DropdownButtonFormField<int>(
                        initialValue: _selectedGroupId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.groups_outlined, color: AppColors.textSecondary),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: activeGroups
                            .map((g) => DropdownMenuItem<int>(
                                  value: g.id,
                                  child: Text(g.name),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedGroupId = val),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Phone field
                const Text(
                  'رقم الهاتف (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '01XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes field
                const Text(
                  'ملاحظات (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'مستوى الطالب أو ولي الأمر...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  isEditing ? 'حفظ التعديلات' : 'إضافة الطالب',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
