import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'folder_repository.dart';

class LernSetRepository {
  final AppDatabase _db;

  LernSetRepository(this._db);

  Future<List<LernSet>> getAllLernSets() => _db.getAllLernSets();

  Stream<List<LernSet>> watchAllLernSets() => _db.watchAllLernSets();

  Future<List<LernSet>> getLernSetsByFolder(int? folderId) =>
      _db.getLernSetsByFolder(folderId);

  Stream<List<LernSet>> watchLernSetsByFolder(int? folderId) =>
      _db.watchLernSetsByFolder(folderId);

  Future<LernSet> getLernSetById(int id) => _db.getLernSetById(id);

  Future<int> createLernSet({
    required String name,
    String? description,
    int? folderId,
  }) {
    return _db.insertLernSet(LernSetsCompanion(
      name: Value(name),
      description: Value(description),
      folderId: Value(folderId),
    ));
  }

  Future<bool> updateLernSet(LernSet lernSet) => _db.updateLernSet(lernSet);

  Future<int> deleteLernSet(int id) async {
    await _db.deleteFlashcardsByLernSet(id);
    return _db.deleteLernSet(id);
  }

  Future<void> assignToFolder(int lernSetId, int? folderId) =>
      _db.assignLernSetToFolder(lernSetId, folderId);

  Future<int> getFlashcardCount(int lernSetId) =>
      _db.getFlashcardCount(lernSetId);
}

final lernSetRepositoryProvider = Provider<LernSetRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LernSetRepository(db);
});
