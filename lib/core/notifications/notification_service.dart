import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../../features/payments/data/payment_repository.dart';
import '../../features/settings/data/settings_repository.dart';

class NotificationEvaluationResult {
  final int triggeredCount;
  final String message;
  NotificationEvaluationResult({required this.triggeredCount, required this.message});
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }

    final darwinImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (darwinImpl != null) {
      await darwinImpl.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Sends immediate system notification banner
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tollab_reminders',
      'تنبيهات طُلاّب',
      channelDescription: 'تنبيهات مواعيد الاشتراكات والأقساط المتأخرة',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  /// Sends an immediate test notification to verify system notification presentation
  Future<void> sendTestNotification() async {
    await initialize();
    await requestPermissions();
    await showNotification(
      id: 999999,
      title: 'إشعار تجريبي من طُلاّب 🔔',
      body: 'تم استلام الإشعار بنجاح! نظام التنبيهات يعمل بشكل سليم على جهازك.',
    );
  }

  /// Checks if a notification of type has already been logged for this period and group
  Future<bool> isNotificationSent(int periodId, int groupId, String type, Database db) async {
    final rows = await db.rawQuery('''
      SELECT id FROM notification_logs
      WHERE monthly_period_id = ? AND group_id = ? AND notification_type = ?
    ''', [periodId, groupId, type]);
    return rows.isNotEmpty;
  }

  /// Records a sent notification to prevent duplication
  Future<void> recordNotificationLog(int periodId, int groupId, String type, Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'notification_logs',
      {
        'monthly_period_id': periodId,
        'group_id': groupId,
        'notification_type': type,
        'sent_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Evaluates reminders for today, tomorrow, and overdue payments
  Future<NotificationEvaluationResult> evaluateNotifications() async {
    final settings = await SettingsRepository().getSettings();
    if (!settings.enableReminders) {
      return NotificationEvaluationResult(triggeredCount: 0, message: 'التنبيهات معطلة في الإعدادات');
    }

    final db = await DatabaseHelper.instance.database;
    final paymentRepo = PaymentRepository();

    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    final todayDay = now.day;
    final tomorrowDay = now.add(const Duration(days: 1)).day;

    await paymentRepo.generateMonthlyRecords(month, year);
    final periodId = await paymentRepo.ensureMonthlyPeriod(month, year);
    await paymentRepo.refreshOverdueStatuses(periodId);

    // Fetch active groups
    final groups = await db.rawQuery('''
      SELECT 
        g.id, 
        g.name, 
        g.due_day, 
        g.monthly_fee_cents,
        COUNT(s.id) as student_count
      FROM groups g
      LEFT JOIN students s ON s.group_id = g.id AND s.status = 'active'
      WHERE g.status = 'active'
      GROUP BY g.id
    ''');

    int triggeredCount = 0;

    for (final g in groups) {
      final groupId = g['id'] as int;
      final groupName = g['name'] as String;
      final dueDay = g['due_day'] as int;
      final feeCents = g['monthly_fee_cents'] as int;
      final studentCount = (g['student_count'] as num?)?.toInt() ?? 0;
      final feeStr = CurrencyFormatter.formatEgp(feeCents);

      // 1. One day before reminder
      if (settings.notifyOneDayBefore && dueDay == tomorrowDay) {
        final alreadySent = await isNotificationSent(periodId, groupId, 'one_day_before', db);
        if (!alreadySent) {
          final title = 'تذكير بموعد الاشتراك: $groupName';
          final body = 'غداً هو موعد سداد الاشتراك الشهري لمجموعة "$groupName". قيمة الاشتراك: $feeStr، عدد الطلاب: $studentCount.';
          await showNotification(id: groupId * 10 + 1, title: title, body: body);
          await recordNotificationLog(periodId, groupId, 'one_day_before', db);
          triggeredCount++;
        }
      }

      // 2. Due date notification
      if (settings.notifyDueDay && dueDay == todayDay) {
        final alreadySent = await isNotificationSent(periodId, groupId, 'due_day', db);
        if (!alreadySent) {
          final title = 'موعد سداد الاشتراك اليوم: $groupName';
          final body = 'اليوم هو موعد سداد الاشتراك الشهري لمجموعة "$groupName". نرجو متابعة تحصيل الاشتراكات.';
          await showNotification(id: groupId * 10 + 2, title: title, body: body);
          await recordNotificationLog(periodId, groupId, 'due_day', db);
          triggeredCount++;
        }
      }

      // 3. Overdue notification
      if (settings.notifyOverdue && todayDay > dueDay) {
        final alreadySent = await isNotificationSent(periodId, groupId, 'overdue', db);
        if (!alreadySent) {
          final overdueRows = await db.rawQuery('''
            SELECT COUNT(*) as overdue_count
            FROM monthly_payments
            WHERE monthly_period_id = ? AND group_id = ? AND status = 'overdue'
          ''', [periodId, groupId]);

          final overdueCount = Sqflite.firstIntValue(overdueRows) ?? 0;
          if (overdueCount > 0) {
            final title = 'اشتراكات متأخرة: $groupName';
            final body = 'يوجد $overdueCount طلاب في مجموعة "$groupName" لم يسددوا الاشتراك حتى الآن.';
            await showNotification(id: groupId * 10 + 3, title: title, body: body);
            await recordNotificationLog(periodId, groupId, 'overdue', db);
            triggeredCount++;
          }
        }
      }
    }

    return NotificationEvaluationResult(
      triggeredCount: triggeredCount,
      message: triggeredCount > 0
          ? 'تم إرسال $triggeredCount إشعار بنجاح'
          : 'لا توجد تنبيهات جديدة مستحقة حالياً',
    );
  }
}
