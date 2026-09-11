import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/archive_repository.dart';
import '../models/archive_model.dart';

final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) {
  return ArchiveRepository();
});

class ArchiveState {
  final int month;
  final int year;
  final List<Map<String, int>> availablePeriods;
  final AsyncValue<MonthArchiveSummary> summary;

  ArchiveState({
    required this.month,
    required this.year,
    required this.availablePeriods,
    required this.summary,
  });

  ArchiveState copyWith({
    int? month,
    int? year,
    List<Map<String, int>>? availablePeriods,
    AsyncValue<MonthArchiveSummary>? summary,
  }) {
    return ArchiveState(
      month: month ?? this.month,
      year: year ?? this.year,
      availablePeriods: availablePeriods ?? this.availablePeriods,
      summary: summary ?? this.summary,
    );
  }
}

class ArchiveNotifier extends StateNotifier<ArchiveState> {
  final ArchiveRepository _repository;

  ArchiveNotifier(this._repository)
      : super(ArchiveState(
          month: DateTime.now().month,
          year: DateTime.now().year,
          availablePeriods: [],
          summary: const AsyncValue.loading(),
        )) {
    init();
  }

  Future<void> init() async {
    final periods = await _repository.getAvailablePeriods();
    state = state.copyWith(availablePeriods: periods);
    await loadArchive(state.month, state.year);
  }

  Future<void> loadArchive(int month, int year) async {
    state = state.copyWith(
      month: month,
      year: year,
      summary: const AsyncValue.loading(),
    );
    try {
      final summary = await _repository.getMonthArchive(month, year);
      state = state.copyWith(summary: AsyncValue.data(summary));
    } catch (e, st) {
      state = state.copyWith(summary: AsyncValue.error(e, st));
    }
  }
}

final archiveProvider = StateNotifierProvider<ArchiveNotifier, ArchiveState>((ref) {
  final repo = ref.watch(archiveRepositoryProvider);
  return ArchiveNotifier(repo);
});
