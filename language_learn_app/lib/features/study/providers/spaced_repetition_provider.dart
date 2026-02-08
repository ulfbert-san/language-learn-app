import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

class SpacedRepetitionState {
  final List<Flashcard> dueCards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final String? error;
  final String? lernSetName;
  final Map<int, int> boxLevelCounts;
  final int cardsReviewed;
  final int correctCount;

  SpacedRepetitionState({
    this.dueCards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = true,
    this.error,
    this.lernSetName,
    this.boxLevelCounts = const {},
    this.cardsReviewed = 0,
    this.correctCount = 0,
  });

  int get totalDue => dueCards.length;
  bool get isFinished => currentIndex >= dueCards.length && dueCards.isNotEmpty;
  Flashcard? get currentCard =>
      dueCards.isNotEmpty && currentIndex < dueCards.length
          ? dueCards[currentIndex]
          : null;

  // Leitner intervals in days
  static const Map<int, int> boxIntervals = {
    1: 1,   // Box 1: review daily
    2: 2,   // Box 2: review every 2 days
    3: 4,   // Box 3: review every 4 days
    4: 7,   // Box 4: review weekly
    5: 14,  // Box 5: review every 2 weeks
  };

  SpacedRepetitionState copyWith({
    List<Flashcard>? dueCards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    String? error,
    String? lernSetName,
    Map<int, int>? boxLevelCounts,
    int? cardsReviewed,
    int? correctCount,
  }) {
    return SpacedRepetitionState(
      dueCards: dueCards ?? this.dueCards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
      boxLevelCounts: boxLevelCounts ?? this.boxLevelCounts,
      cardsReviewed: cardsReviewed ?? this.cardsReviewed,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}

class SpacedRepetitionNotifier extends StateNotifier<SpacedRepetitionState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;
  final int lernSetId;

  SpacedRepetitionNotifier(
    this._flashcardRepository,
    this._lernSetRepository,
    this.lernSetId,
  ) : super(SpacedRepetitionState()) {
    loadSession();
  }

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final dueCards = await _flashcardRepository.getFlashcardsDueForReview(lernSetId);
      final lernSet = await _lernSetRepository.getLernSetById(lernSetId);
      final boxCounts = await _flashcardRepository.getBoxLevelCounts(lernSetId);

      state = SpacedRepetitionState(
        dueCards: dueCards,
        currentIndex: 0,
        isLoading: false,
        lernSetName: lernSet.name,
        boxLevelCounts: boxCounts,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void flip() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> markCorrect() async {
    final card = state.currentCard;
    if (card == null) return;

    // Move to next box (max 5)
    final newBoxLevel = (card.boxLevel + 1).clamp(1, 5);
    final interval = SpacedRepetitionState.boxIntervals[newBoxLevel] ?? 1;
    final nextReview = DateTime.now().add(Duration(days: interval));

    await _flashcardRepository.updateFlashcardBoxLevel(
      card.id,
      newBoxLevel,
      nextReview,
    );

    _nextCard(correct: true);
  }

  Future<void> markIncorrect() async {
    final card = state.currentCard;
    if (card == null) return;

    // Reset to box 1
    final nextReview = DateTime.now().add(const Duration(days: 1));

    await _flashcardRepository.updateFlashcardBoxLevel(
      card.id,
      1,
      nextReview,
    );

    _nextCard(correct: false);
  }

  void _nextCard({required bool correct}) {
    final newCounts = Map<int, int>.from(state.boxLevelCounts);
    final card = state.currentCard!;

    // Update counts
    final oldBox = card.boxLevel;
    final newBox = correct ? (oldBox + 1).clamp(1, 5) : 1;

    if (oldBox != newBox) {
      newCounts[oldBox] = (newCounts[oldBox] ?? 1) - 1;
      newCounts[newBox] = (newCounts[newBox] ?? 0) + 1;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      isFlipped: false,
      boxLevelCounts: newCounts,
      cardsReviewed: state.cardsReviewed + 1,
      correctCount: correct ? state.correctCount + 1 : state.correctCount,
    );
  }

  Future<void> restart() async {
    await loadSession();
  }
}

final spacedRepetitionProvider = StateNotifierProvider.autoDispose
    .family<SpacedRepetitionNotifier, SpacedRepetitionState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  return SpacedRepetitionNotifier(flashcardRepo, lernSetRepo, lernSetId);
});
