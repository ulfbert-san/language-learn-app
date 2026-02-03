import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'folder_repository.dart';

class FlashcardRepository {
  final AppDatabase _db;

  FlashcardRepository(this._db);

  Future<List<Flashcard>> getFlashcardsByLernSet(int lernSetId) =>
      _db.getFlashcardsByLernSet(lernSetId);

  Stream<List<Flashcard>> watchFlashcardsByLernSet(int lernSetId) =>
      _db.watchFlashcardsByLernSet(lernSetId);

  Future<int> createFlashcard({
    required int lernSetId,
    required String word,
    required String translation,
    required int position,
  }) {
    return _db.insertFlashcard(FlashcardsCompanion(
      lernSetId: Value(lernSetId),
      word: Value(word),
      translation: Value(translation),
      position: Value(position),
    ));
  }

  Future<void> createFlashcards(
    int lernSetId,
    List<({String word, String translation})> cards,
  ) {
    final companions = cards.asMap().entries.map((entry) {
      return FlashcardsCompanion(
        lernSetId: Value(lernSetId),
        word: Value(entry.value.word),
        translation: Value(entry.value.translation),
        position: Value(entry.key),
      );
    }).toList();
    return _db.insertFlashcards(companions);
  }

  Future<bool> updateFlashcard(Flashcard flashcard) =>
      _db.updateFlashcard(flashcard);

  Future<int> deleteFlashcard(int id) => _db.deleteFlashcard(id);

  Future<int> deleteAllByLernSet(int lernSetId) =>
      _db.deleteFlashcardsByLernSet(lernSetId);
}

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FlashcardRepository(db);
});
