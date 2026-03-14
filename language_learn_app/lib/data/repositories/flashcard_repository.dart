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

  Future<void> upsertFlashcards(
    int lernSetId,
    List<({int? id, String word, String translation, bool isContentChanged})> cards,
  ) async {
    // Collect IDs of existing cards that are still present
    final keepIds = cards
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toList();

    // Delete cards that were removed by the user
    await _db.deleteFlashcardsNotInSet(lernSetId, keepIds);

    // Process each card
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      if (card.id != null) {
        // Existing card: update fields, reset progress only if content changed
        await _db.updateFlashcardFields(
          card.id!,
          word: card.word,
          translation: card.translation,
          position: i,
          resetProgress: card.isContentChanged,
        );
      } else {
        // New card: insert with default box level
        await _db.insertFlashcard(FlashcardsCompanion(
          lernSetId: Value(lernSetId),
          word: Value(card.word),
          translation: Value(card.translation),
          position: Value(i),
        ));
      }
    }
  }

  // Spaced Repetition
  Future<List<Flashcard>> getFlashcardsDueForReview(int lernSetId) =>
      _db.getFlashcardsDueForReview(lernSetId);

  Future<void> updateFlashcardBoxLevel(int cardId, int boxLevel, DateTime? nextReview) =>
      _db.updateFlashcardBoxLevel(cardId, boxLevel, nextReview);

  Future<Map<int, int>> getBoxLevelCounts(int lernSetId) =>
      _db.getBoxLevelCounts(lernSetId);
}

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FlashcardRepository(db);
});
