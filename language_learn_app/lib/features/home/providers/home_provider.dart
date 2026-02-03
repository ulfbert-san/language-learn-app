import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/lernset_repository.dart';

class LernSetsNotifier extends AsyncNotifier<List<LernSet>> {
  @override
  Future<List<LernSet>> build() async {
    final repository = ref.watch(lernSetRepositoryProvider);
    return repository.getAllLernSets();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> deleteLernSet(int id) async {
    final repository = ref.read(lernSetRepositoryProvider);
    await repository.deleteLernSet(id);
    ref.invalidateSelf();
  }

  Future<void> assignToFolder(int lernSetId, int? folderId) async {
    final repository = ref.read(lernSetRepositoryProvider);
    await repository.assignToFolder(lernSetId, folderId);
    ref.invalidateSelf();
  }
}

final lernSetsProvider =
    AsyncNotifierProvider<LernSetsNotifier, List<LernSet>>(LernSetsNotifier.new);

final lernSetsByFolderProvider =
    FutureProvider.family<List<LernSet>, int?>((ref, folderId) async {
  final repository = ref.watch(lernSetRepositoryProvider);
  return repository.getLernSetsByFolder(folderId);
});

final flashcardCountProvider =
    FutureProvider.family<int, int>((ref, lernSetId) async {
  final repository = ref.watch(lernSetRepositoryProvider);
  return repository.getFlashcardCount(lernSetId);
});
