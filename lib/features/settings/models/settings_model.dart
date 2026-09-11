class AppSettings {
  final bool enableReminders;
  final bool notifyOneDayBefore;
  final bool notifyDueDay;
  final bool notifyOverdue;
  final String overdueFrequency; // 'once' | 'daily' | 'every_3_days' | 'weekly'

  AppSettings({
    this.enableReminders = true,
    this.notifyOneDayBefore = true,
    this.notifyDueDay = true,
    this.notifyOverdue = true,
    this.overdueFrequency = 'once',
  });

  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      enableReminders: map['enable_reminders'] != 'false',
      notifyOneDayBefore: map['notify_one_day_before'] != 'false',
      notifyDueDay: map['notify_due_day'] != 'false',
      notifyOverdue: map['notify_overdue'] != 'false',
      overdueFrequency: map['overdue_frequency'] ?? 'once',
    );
  }

  Map<String, String> toMap() {
    return {
      'enable_reminders': enableReminders.toString(),
      'notify_one_day_before': notifyOneDayBefore.toString(),
      'notify_due_day': notifyDueDay.toString(),
      'notify_overdue': notifyOverdue.toString(),
      'overdue_frequency': overdueFrequency,
    };
  }

  AppSettings copyWith({
    bool? enableReminders,
    bool? notifyOneDayBefore,
    bool? notifyDueDay,
    bool? notifyOverdue,
    String? overdueFrequency,
  }) {
    return AppSettings(
      enableReminders: enableReminders ?? this.enableReminders,
      notifyOneDayBefore: notifyOneDayBefore ?? this.notifyOneDayBefore,
      notifyDueDay: notifyDueDay ?? this.notifyDueDay,
      notifyOverdue: notifyOverdue ?? this.notifyOverdue,
      overdueFrequency: overdueFrequency ?? this.overdueFrequency,
    );
  }
}
