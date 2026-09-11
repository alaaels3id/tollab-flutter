class StudentModel {
  final int id;
  final String studentCode;
  final String name;
  final String? phone;
  final int groupId;
  final String? groupName;
  final int? groupFeeCents;
  final int? groupDueDay;
  final String status; // 'active' | 'inactive'
  final String? notes;
  final String createdAt;
  final String updatedAt;

  StudentModel({
    required this.id,
    required this.studentCode,
    required this.name,
    this.phone,
    required this.groupId,
    this.groupName,
    this.groupFeeCents,
    this.groupDueDay,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as int,
      studentCode: map['student_code'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      groupId: map['group_id'] as int,
      groupName: map['group_name'] as String?,
      groupFeeCents: map['monthly_fee_cents'] as int?,
      groupDueDay: map['due_day'] as int?,
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'student_code': studentCode,
      'name': name,
      'phone': phone,
      'group_id': groupId,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  StudentModel copyWith({
    int? id,
    String? studentCode,
    String? name,
    String? phone,
    int? groupId,
    String? groupName,
    int? groupFeeCents,
    int? groupDueDay,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentCode: studentCode ?? this.studentCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupFeeCents: groupFeeCents ?? this.groupFeeCents,
      groupDueDay: groupDueDay ?? this.groupDueDay,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
