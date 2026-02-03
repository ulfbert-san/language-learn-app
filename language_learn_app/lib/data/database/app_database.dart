import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/flashcards_table.dart';
import 'tables/folders_table.dart';
import 'tables/lernsets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Folders, LernSets, Flashcards])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Folder operations
  Future<List<Folder>> getAllFolders() => select(folders).get();

  Stream<List<Folder>> watchAllFolders() => select(folders).watch();

  Future<Folder> getFolderById(int id) =>
      (select(folders)..where((f) => f.id.equals(id))).getSingle();

  Future<int> insertFolder(FoldersCompanion folder) =>
      into(folders).insert(folder);

  Future<bool> updateFolder(Folder folder) => update(folders).replace(folder);

  Future<int> deleteFolder(int id) =>
      (delete(folders)..where((f) => f.id.equals(id))).go();

  // LernSet operations
  Future<List<LernSet>> getAllLernSets() => select(lernSets).get();

  Stream<List<LernSet>> watchAllLernSets() => select(lernSets).watch();

  Future<List<LernSet>> getLernSetsByFolder(int? folderId) {
    if (folderId == null) {
      return (select(lernSets)..where((l) => l.folderId.isNull())).get();
    }
    return (select(lernSets)..where((l) => l.folderId.equals(folderId))).get();
  }

  Stream<List<LernSet>> watchLernSetsByFolder(int? folderId) {
    if (folderId == null) {
      return (select(lernSets)..where((l) => l.folderId.isNull())).watch();
    }
    return (select(lernSets)..where((l) => l.folderId.equals(folderId))).watch();
  }

  Future<LernSet> getLernSetById(int id) =>
      (select(lernSets)..where((l) => l.id.equals(id))).getSingle();

  Future<int> insertLernSet(LernSetsCompanion lernSet) =>
      into(lernSets).insert(lernSet);

  Future<bool> updateLernSet(LernSet lernSet) =>
      update(lernSets).replace(lernSet);

  Future<int> deleteLernSet(int id) =>
      (delete(lernSets)..where((l) => l.id.equals(id))).go();

  Future<void> assignLernSetToFolder(int lernSetId, int? folderId) async {
    await (update(lernSets)..where((l) => l.id.equals(lernSetId))).write(
      LernSetsCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Flashcard operations
  Future<List<Flashcard>> getFlashcardsByLernSet(int lernSetId) =>
      (select(flashcards)
            ..where((f) => f.lernSetId.equals(lernSetId))
            ..orderBy([(f) => OrderingTerm.asc(f.position)]))
          .get();

  Stream<List<Flashcard>> watchFlashcardsByLernSet(int lernSetId) =>
      (select(flashcards)
            ..where((f) => f.lernSetId.equals(lernSetId))
            ..orderBy([(f) => OrderingTerm.asc(f.position)]))
          .watch();

  Future<int> insertFlashcard(FlashcardsCompanion flashcard) =>
      into(flashcards).insert(flashcard);

  Future<void> insertFlashcards(List<FlashcardsCompanion> cards) =>
      batch((batch) => batch.insertAll(flashcards, cards));

  Future<bool> updateFlashcard(Flashcard flashcard) =>
      update(flashcards).replace(flashcard);

  Future<int> deleteFlashcard(int id) =>
      (delete(flashcards)..where((f) => f.id.equals(id))).go();

  Future<int> deleteFlashcardsByLernSet(int lernSetId) =>
      (delete(flashcards)..where((f) => f.lernSetId.equals(lernSetId))).go();

  Future<int> getFlashcardCount(int lernSetId) async {
    final count = flashcards.id.count();
    final query = selectOnly(flashcards)
      ..addColumns([count])
      ..where(flashcards.lernSetId.equals(lernSetId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'language_learn_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
