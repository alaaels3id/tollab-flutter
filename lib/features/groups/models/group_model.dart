class GroupModel {
  final int id;
  final String name;
  final int monthlyFeeCents;
  final int dueDay;
  final String? description;
  final String status; // 'active' | 'inactive'
  final int studentCount;
  final String createdAt;
  final String updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.monthlyFeeCents,
    required this.dueDay,
    this.description,
    required this.status,
    this.studentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  double get monthlyFeeEgp => monthlyFeeCents / 100.0;

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as int,
      name: map['name'] as String,
      monthlyFeeCents: map['monthly_fee_cents'] as int,
      dueDay: map['due_day'] as int,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'active',
      studentCount: (map['student_count'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'monthly_fee_cents': monthlyFeeCents,
      'due_day': dueDay,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  GroupModel copyWith({
    int? id,
    String? name,
    int? monthlyFeeCents,
    int? dueDay,
    String? description,
    String? status,
    int? studentCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyFeeCents: monthlyFeeCents ?? this.monthlyFeeCents,
      dueDay: dueDay ?? this.dueDay,
      description: description ?? this.description,
      status: status ?? this.status,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
