import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/monthly_payment_model.dart';
import 'payments_controller.dart';

class RecordPaymentDialog extends StatefulWidget {
  final MonthlyPaymentModel payment;

  const RecordPaymentDialog({super.key, required this.payment});

  static Future<bool> show(BuildContext context, {required MonthlyPaymentModel payment}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => RecordPaymentDialog(payment: payment),
    );
    return result ?? false;
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default amount to full due amount if unpaid, or existing paid amount
    final initialPaid = widget.payment.amountPaidEgp > 0
        ? widget.payment.amountPaidEgp
        : widget.payment.amountDueEgp;
    _amountController = TextEditingController(text: initialPaid.toStringAsFixed(0));
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _submit(WidgetRef ref) async {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح'), backgroundColor: AppColors.overduePrimary),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final amountPaidCents = CurrencyFormatter.egpToCents(amount);
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      await ref.read(paymentsProvider.notifier).recordPayment(
        paymentId: widget.payment.id,
        amountPaidCents: amountPaidCents,
        notes: notes,
      );

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
    final p = widget.payment;

    return Consumer(
      builder: (context, ref, _) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('تسجيل / تعديل السداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              StatusBadge(status: p.status),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Summary Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.studentNameSnapshot,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(p.studentCode,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('المجموعة: ${p.groupNameSnapshot}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('تاريخ الاستحقاق: ${DateFormatter.formatFullArabicDate(p.dueDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المبلغ المطلوب: ${CurrencyFormatter.formatEgp(p.amountDueCents)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('المسدد حالياً: ${CurrencyFormatter.formatEgp(p.amountPaidCents)}',
                              style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('المبلغ المدفوع (ج.م) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'أدخل المبلغ'),
                ),
                const SizedBox(height: 10),

                // Quick Amount Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('سداد كامل'),
                      avatar: const Icon(Icons.check, size: 16, color: AppColors.paidPrimary),
                      onPressed: () => _setAmount(p.amountDueEgp),
                    ),
                    if (p.amountDueEgp > 0) ...[
                      ActionChip(
                        label: const Text('نصف القيمة'),
                        avatar: const Icon(Icons.pie_chart, size: 16, color: AppColors.partialPrimary),
                        onPressed: () => _setAmount(p.amountDueEgp / 2),
                      ),
                    ],
                    ActionChip(
                      label: const Text('إلغاء السداد (0)'),
                      avatar: const Icon(Icons.clear, size: 16, color: AppColors.overduePrimary),
                      onPressed: () => _setAmount(0),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('ملاحظات السداد (اختياري)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'مثال: تم السداد نقداً / فودافون كاش'),
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
              onPressed: _isLoading ? null : () => _submit(ref),
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ السداد'),
            ),
          ],
        );
      },
    );
  }
}
