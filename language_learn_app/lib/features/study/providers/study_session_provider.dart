import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

class StudySessionState {
  final List<Flashcard> cards;
  final int currentIndex;
  final bool isFlipped;
  final bool isSwapped;
  final bool isLoading;
  final String? error;
  final String? lernSetName;

  StudySessionState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isSwapped = false,
    this.isLoading = true,
    this.error,
    this.lernSetName,
  });

  Flashcard? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  String get frontText {
    if (currentCard == null) return '';
    return isSwapped ? currentCard!.translation : currentCard!.word;
  }

  String get backText {
    if (currentCard == null) return '';
    return isSwapped ? currentCard!.word : currentCard!.translation;
  }

  int get totalCards => cards.length;
  int get currentPosition => currentIndex + 1;

  StudySessionState copyWith({
    List<Flashcard>? cards,
    int? currentIndex,
    bool? isFlipped,
    bool? isSwapped,
    bool? isLoading,
    String? error,
    String? lernSetName,
  }) {
    return StudySessionState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isSwapped: isSwapped ?? this.isSwapped,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
    );
  }
}

class StudySessionNotifier extends StateNotifier<StudySessionState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;

  StudySessionNotifier(this._flashcardRepository, this._lernSetRepository)
      : super(StudySessionState());

  Future<void> loadCards(int lernSetId) async {
    state = state.copyWith(isLoading: true);
    try {
      final cards = await _flashcardRepository.getFlashcardsByLernSet(lernSetId);
      final lernSet = await _lernSetRepository.getLernSetById(lernSetId);
      state = StudySessionState(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isSwapped: false,
        isLoading: false,
        lernSetName: lernSet.name,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void flip() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  void nextCard() {
    if (state.currentIndex < state.cards.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isFlipped: false,
      );
    } else {
      // Restart from beginning
      state = state.copyWith(
        currentIndex: 0,
        isFlipped: false,
      );
    }
  }

  void previousCard() {
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        isFlipped: false,
      );
    }
  }

  void toggleSwap() {
    state = state.copyWith(
      isSwapped: !state.isSwapped,
      isFlipped: false,
    );
  }

  void shuffleRemaining() {
    if (state.cards.isEmpty) return;

    final random = Random();

    // Keep cards before current index
    final beforeCurrent = state.cards.sublist(0, state.currentIndex);

    // Shuffle cards from current index onwards (including current)
    final remaining = List<Flashcard>.from(
      state.cards.sublist(state.currentIndex),
    );

    // Fisher-Yates shuffle
    for (var i = remaining.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = remaining[i];
      remaining[i] = remaining[j];
      remaining[j] = temp;
    }

    state = state.copyWith(
      cards: [...beforeCurrent, ...remaining],
      isFlipped: false,
    );
  }

  void goToCard(int index) {
    if (index >= 0 && index < state.cards.length) {
      state = state.copyWith(
        currentIndex: index,
        isFlipped: false,
      );
    }
  }
}

final studySessionProvider = StateNotifierProvider.family
    .autoDispose<StudySessionNotifier, StudySessionState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  final notifier = StudySessionNotifier(flashcardRepo, lernSetRepo);
  notifier.loadCards(lernSetId);
  return notifier;
});
