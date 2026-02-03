import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

class FlashcardInput {
  final String word;
  final String translation;

  FlashcardInput({required this.word, required this.translation});
}

class LernSetEditorState {
  final String name;
  final String description;
  final List<FlashcardInput> flashcards;
  final int? folderId;
  final bool isLoading;
  final String? error;

  LernSetEditorState({
    this.name = '',
    this.description = '',
    this.flashcards = const [],
    this.folderId,
    this.isLoading = false,
    this.error,
  });

  LernSetEditorState copyWith({
    String? name,
    String? description,
    List<FlashcardInput>? flashcards,
    int? folderId,
    bool? isLoading,
    String? error,
  }) {
    return LernSetEditorState(
      name: name ?? this.name,
      description: description ?? this.description,
      flashcards: flashcards ?? this.flashcards,
      folderId: folderId ?? this.folderId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LernSetEditorNotifier extends StateNotifier<LernSetEditorState> {
  final LernSetRepository _lernSetRepository;
  final FlashcardRepository _flashcardRepository;

  LernSetEditorNotifier(this._lernSetRepository, this._flashcardRepository)
      : super(LernSetEditorState(
          flashcards: [FlashcardInput(word: '', translation: '')],
        ));

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setFolderId(int? folderId) {
    state = state.copyWith(folderId: folderId);
  }

  void updateFlashcard(int index, {String? word, String? translation}) {
    final cards = List<FlashcardInput>.from(state.flashcards);
    cards[index] = FlashcardInput(
      word: word ?? cards[index].word,
      translation: translation ?? cards[index].translation,
    );
    state = state.copyWith(flashcards: cards);
  }

  void addFlashcard() {
    final cards = List<FlashcardInput>.from(state.flashcards);
    cards.add(FlashcardInput(word: '', translation: ''));
    state = state.copyWith(flashcards: cards);
  }

  void removeFlashcard(int index) {
    if (state.flashcards.length <= 1) return;
    final cards = List<FlashcardInput>.from(state.flashcards);
    cards.removeAt(index);
    state = state.copyWith(flashcards: cards);
  }

  void importFlashcards(List<FlashcardInput> imported) {
    final cards = List<FlashcardInput>.from(state.flashcards);
    // Remove empty cards at the end
    while (cards.isNotEmpty &&
        cards.last.word.isEmpty &&
        cards.last.translation.isEmpty) {
      cards.removeLast();
    }
    cards.addAll(imported);
    if (cards.isEmpty) {
      cards.add(FlashcardInput(word: '', translation: ''));
    }
    state = state.copyWith(flashcards: cards);
  }

  Future<void> loadLernSet(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      final lernSet = await _lernSetRepository.getLernSetById(id);
      final flashcards =
          await _flashcardRepository.getFlashcardsByLernSet(id);

      state = LernSetEditorState(
        name: lernSet.name,
        description: lernSet.description ?? '',
        folderId: lernSet.folderId,
        flashcards: flashcards.isEmpty
            ? [FlashcardInput(word: '', translation: '')]
            : flashcards
                .map((f) =>
                    FlashcardInput(word: f.word, translation: f.translation))
                .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<int?> save({int? existingId}) async {
    if (state.name.isEmpty) {
      state = state.copyWith(error: 'Name ist erforderlich');
      return null;
    }

    final validCards = state.flashcards
        .where((c) => c.word.isNotEmpty && c.translation.isNotEmpty)
        .toList();

    if (validCards.isEmpty) {
      state = state.copyWith(error: 'Mindestens eine Karteikarte ist erforderlich');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      int lernSetId;

      if (existingId != null) {
        final existing = await _lernSetRepository.getLernSetById(existingId);
        final updated = LernSet(
          id: existing.id,
          name: state.name,
          description: state.description.isEmpty ? null : state.description,
          folderId: state.folderId,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await _lernSetRepository.updateLernSet(updated);
        await _flashcardRepository.deleteAllByLernSet(existingId);
        lernSetId = existingId;
      } else {
        lernSetId = await _lernSetRepository.createLernSet(
          name: state.name,
          description: state.description.isEmpty ? null : state.description,
          folderId: state.folderId,
        );
      }

      await _flashcardRepository.createFlashcards(
        lernSetId,
        validCards.map((c) => (word: c.word, translation: c.translation)).toList(),
      );

      state = state.copyWith(isLoading: false);
      return lernSetId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final lernSetEditorProvider =
    StateNotifierProvider.autoDispose<LernSetEditorNotifier, LernSetEditorState>(
        (ref) {
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  return LernSetEditorNotifier(lernSetRepo, flashcardRepo);
});
