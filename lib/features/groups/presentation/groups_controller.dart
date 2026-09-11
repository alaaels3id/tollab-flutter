import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../models/group_model.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

class GroupsNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final GroupRepository _repository;

  GroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  Future<void> loadGroups({bool activeOnly = false}) async {
    state = const AsyncValue.loading();
    try {
      final groups = await _repository.getAllGroups(activeOnly: activeOnly);
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroup({
    required String name,
    required int monthlyFeeCents,
    required int dueDay,
    String? description,
  }) async {
    await _repository.createGroup(
      name: name,
      monthlyFeeCents: monthlyFeeCents,
      dueDay: dueDay,
      description: description,
    );
    await loadGroups();
  }

  Future<void> updateGroup(GroupModel group) async {
    await _repository.updateGroup(group);
    await loadGroups();
  }

  Future<void> toggleStatus(int id, bool active) async {
    await _repository.toggleGroupStatus(id, active);
    await loadGroups();
  }

  Future<void> deleteGroup(int id, {bool force = false}) async {
    await _repository.deleteGroup(id, force: force);
    await loadGroups();
  }
}

final groupsProvider = StateNotifierProvider<GroupsNotifier, AsyncValue<List<GroupModel>>>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return GroupsNotifier(repo);
});
