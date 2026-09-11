import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../archive/presentation/archive_screen.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../payments/presentation/payments_screen.dart';
import 'package:flutter/services.dart';
import '../../../core/notifications/firebase_messaging_service.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          // Finance & Archive Section
          const Text(
            'الاشتراكات والأرشيف',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.credit_card_rounded, color: Colors.white),
                  ),
                  title: const Text('الاشتراكات الشهرية', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('متابعة سداد واشتراكات الطلاب لهذا الشهر'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                    child: const Icon(Icons.archive_outlined, color: AppColors.secondary),
                  ),
                  title: const Text('الأرشيف الشهري', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('سجل الاشتراكات والمدفوعات للأشهر السابقة'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ArchiveScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification Settings Section
          const Text(
            'تنبيهات مواعيد الاشتراكات',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          settingsState.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('خطأ في تحميل الإعدادات: $err'),
              ),
            ),
            data: (settings) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('تفعيل التنبيهات المحلية', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('إرسال إشعارات على الهاتف بمواعيد الاشتراكات'),
                        value: settings.enableReminders,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).updateSettings(
                                settings.copyWith(enableReminders: val),
                              );
                        },
                      ),
                      if (settings.enableReminders) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('تذكير قبل الموعد بيوم واحد'),
                          subtitle: const Text('إشعار قبل يوم استحقاق المجموعة بيوم'),
                          value: settings.notifyOneDayBefore,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(notifyOneDayBefore: val),
                                );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('إشعار في يوم الاستحقاق'),
                          subtitle: const Text('إشعار بأن اليوم هو موعد السداد'),
                          value: settings.notifyDueDay,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(notifyDueDay: val),
                                );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('إشعار بالاشتراكات المتأخرة'),
                          subtitle: const Text('تنبيه بوجود طلاب متأخرين عن السداد بعد موعد الاستحقاق'),
                          value: settings.notifyOverdue,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(notifyOverdue: val),
                                );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(settingsProvider.notifier).sendTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إرسال الإشعار التجريبي بنجاح! 🔔'),
                            backgroundColor: AppColors.paidPrimary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تعذر إرسال الإشعار: $e'),
                            backgroundColor: AppColors.overduePrimary,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('إرسال إشعار تجريبي فوري'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await ref.read(settingsProvider.notifier).testNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.message), backgroundColor: AppColors.secondary),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('فحص وإرسال التنبيهات المستحقة الآن'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final token = await FirebaseMessagingService.instance.getOrFetchToken();
                    if (context.mounted) {
                      if (token != null && token.isNotEmpty) {
                        await Clipboard.setData(ClipboardData(text: token));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ رمز الجهاز (FCM Token) بنجاح! يمكنك استخدامه في Firebase Console.'),
                              backgroundColor: AppColors.paidPrimary,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر جلب رمز FCM. تأكد من تشغيل التطبيق على جهاز فعلي يدعم APNs.'),
                            backgroundColor: AppColors.overduePrimary,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('نسخ رمز الجهاز للإشعارات (FCM Token)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup & Restore Section
          const Text(
            'النسخ الاحتياطي واستعادة البيانات',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.paidBg,
                    child: Icon(Icons.upload_file, color: AppColors.paidPrimary),
                  ),
                  title: const Text('تصدير نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('حفظ ملف قاعدة البيانات ومشاركته أو تخزينه في مكان آمن'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    try {
                      final backupPath = await ref.read(settingsProvider.notifier).exportBackup();
                      await Share.shareXFiles(
                        [XFile(backupPath)],
                        text: 'نسخة احتياطية من قاعدة بيانات تطبيق طُلاّب',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ أثناء التصدير: $e'), backgroundColor: AppColors.overduePrimary),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.overdueBg,
                    child: Icon(Icons.restore, color: AppColors.overduePrimary),
                  ),
                  title: const Text('استعادة نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('استيراد قاعدة بيانات سابقة واستبدال البيانات الحالية'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'تحذير: استعادة النسخة الاحتياطية',
                      message:
                          'استعادة النسخة الاحتياطية ستقوم باستبدال كافة البيانات الحالية في التطبيق بالبيانات الموجودة في الملف المختار. هل تريد المتابعة؟',
                      confirmText: 'اختيار ملف الاستعادة',
                      isDestructive: true,
                    );

                    if (!confirmed) return;

                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      final path = result.files.single.path!;
                      final success = await ref.read(settingsProvider.notifier).restoreBackup(path);
                      if (context.mounted) {
                        if (success) {
                          ref.read(dashboardProvider.notifier).loadStats();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت استعادة البيانات بنجاح!'),
                              backgroundColor: AppColors.paidPrimary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('فشلت عملية الاستعادة. تأكد من صحة الملف.'),
                              backgroundColor: AppColors.overduePrimary,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info Section
          const Text(
            'عن التطبيق',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/icon.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('طُلاّب (Tollab)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('إدارة المجموعات والاشتراكات الشهرية', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('الإصدار 1.0.0 • بدون إنترنت (Local-First)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
