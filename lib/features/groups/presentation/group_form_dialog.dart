import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/group_model.dart';
import 'group_form_screen.dart';
import 'groups_controller.dart';

class GroupFormDialog extends StatefulWidget {
  final GroupModel? groupToEdit;

  const GroupFormDialog({super.key, this.groupToEdit});

  static Future<bool> show(BuildContext context, {GroupModel? groupToEdit}) async {
    final result = await GroupFormScreen.navigate(context, groupToEdit: groupToEdit);
    return result ?? false;
  }

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _feeController;
  late TextEditingController _dueDayController;
  late TextEditingController _descController;
  bool _isLoading = false;

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

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final fee = double.parse(_feeController.text.trim());
      final feeCents = CurrencyFormatter.egpToCents(fee);
      final dueDay = int.parse(_dueDayController.text.trim());
      final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();

      if (widget.groupToEdit != null) {
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
        Navigator.of(context).pop(true);
      }
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
    final isEditing = widget.groupToEdit != null;

    return Consumer(
      builder: (context, ref, _) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسم المجموعة *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'مثال: الصف الثالث الثانوي - مجموعة أ'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المجموعة' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('قيمة الاشتراك (ج.م) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _feeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '300'),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('يوم الاستحقاق (1-31) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _dueDayController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '10'),
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
                  const SizedBox(height: 14),

                  const Text('ملاحظات أو وصف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'مثال: مواعيد الحصص: الأحد والثلاثاء 5 مساءً'),
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
              onPressed: _isLoading ? null : () => _submit(ref),
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'حفظ التعديلات' : 'إضافة المجموعة'),
            ),
          ],
        );
      },
    );
  }
}
