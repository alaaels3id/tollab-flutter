import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/student_repository.dart';
import '../models/student_model.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

class StudentsFilter {
  final String query;
  final int? groupId;
  final String? status;

  const StudentsFilter({
    this.query = '',
    this.groupId,
    this.status,
  });

  StudentsFilter copyWith({
    String? query,
    int? groupId,
    bool clearGroup = false,
    String? status,
    bool clearStatus = false,
  }) {
    return StudentsFilter(
      query: query ?? this.query,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class StudentsNotifier extends StateNotifier<AsyncValue<List<StudentModel>>> {
  final StudentRepository _repository;
  StudentsFilter _filter = const StudentsFilter();

  StudentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  StudentsFilter get filter => _filter;

  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _repository.getAllStudents(
        query: _filter.query,
        groupId: _filter.groupId,
        status: _filter.status,
      );
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setFilter(StudentsFilter filter) {
    _filter = filter;
    loadStudents();
  }

  Future<void> addStudent({
    required String name,
    required int groupId,
    String? phone,
    String? notes,
  }) async {
    await _repository.createStudent(
      name: name,
      groupId: groupId,
      phone: phone,
      notes: notes,
    );
    await loadStudents();
  }

  Future<void> updateStudent(StudentModel student) async {
    await _repository.updateStudent(student);
    await loadStudents();
  }

  Future<void> moveStudentGroup(int studentId, int newGroupId) async {
    await _repository.moveStudentGroup(studentId, newGroupId);
    await loadStudents();
  }

  Future<void> toggleStatus(int id, bool active) async {
    await _repository.toggleStudentStatus(id, active);
    await loadStudents();
  }

  Future<void> deleteStudent(int id, {bool force = false}) async {
    await _repository.deleteStudent(id, force: force);
    await loadStudents();
  }
}

final studentsProvider = StateNotifierProvider<StudentsNotifier, AsyncValue<List<StudentModel>>>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return StudentsNotifier(repo);
});
