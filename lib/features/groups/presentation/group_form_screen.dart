import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/group_model.dart';
import 'groups_controller.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  final GroupModel? groupToEdit;

  const GroupFormScreen({super.key, this.groupToEdit});

  static Future<bool?> navigate(BuildContext context, {GroupModel? groupToEdit}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => GroupFormScreen(groupToEdit: groupToEdit),
      ),
    );
  }

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _feeController;
  late TextEditingController _dueDayController;
  late TextEditingController _descController;
  bool _isLoading = false;

  bool get isEditing => widget.groupToEdit != null;

  @override
  void initState() {
    super.initState();
    final g = widget.groupToEdit;
    _nameController = TextEditingController(text: g?.name ?? '');
    _feeController = TextEditingController(text: g != null ? g.monthlyFeeEgp.toStringAsFixed(0) : '300');
    _dueDayController = TextEditingController(text: g != null ? g.dueDay.toString() : '10');
    _descController = TextEditingController(text: g?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _dueDayController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final fee = double.parse(_feeController.text.trim());
      final feeCents = CurrencyFormatter.egpToCents(fee);
      final dueDay = int.parse(_dueDayController.text.trim());
      final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();

      if (isEditing) {
        final updated = widget.groupToEdit!.copyWith(
          name: name,
          monthlyFeeCents: feeCents,
          dueDay: dueDay,
          description: desc,
        );
        await ref.read(groupsProvider.notifier).updateGroup(updated);
      } else {
        await ref.read(groupsProvider.notifier).addGroup(
              name: name,
              monthlyFeeCents: feeCents,
              dueDay: dueDay,
              description: desc,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تعديل المجموعة بنجاح' : 'تمت إضافة المجموعة بنجاح'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة',
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
                // Header Avatar & Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Group Name
                const Text(
                  'اسم المجموعة *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'مثال: الصف الثالث الثانوي - مجموعة أ',
                    prefixIcon: Icon(Icons.school_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المجموعة' : null,
                ),
                const SizedBox(height: 20),

                // Fee & Due Day Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'قيمة الاشتراك (ج.م) *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: '300',
                              prefixIcon: Icon(Icons.payments_outlined, color: AppColors.textSecondary),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              final numVal = double.tryParse(v.trim());
                              if (numVal == null || numVal < 0) return 'قيمة غير صالحة';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'يوم الاستحقاق (1-31) *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dueDayController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: '10',
                              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              final day = int.tryParse(v.trim());
                              if (day == null || day < 1 || day > 31) return 'بين 1 و 31';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notes / Description
                const Text(
                  'ملاحظات أو وصف',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'مثال: مواعيد الحصص: الأحد والثلاثاء 5 مساءً',
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
                  isEditing ? 'حفظ التعديلات' : 'إضافة المجموعة',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
