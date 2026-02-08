import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

class TypingState {
  final List<Flashcard> cards;
  final int currentIndex;
  final int score;
  final String userInput;
  final bool isAnswered;
  final bool isCorrect;
  final bool isLoading;
  final String? error;
  final String? lernSetName;

  TypingState({
    this.cards = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.userInput = '',
    this.isAnswered = false,
    this.isCorrect = false,
    this.isLoading = true,
    this.error,
    this.lernSetName,
  });

  int get totalCards => cards.length;
  int get currentNumber => currentIndex + 1;
  double get progress => totalCards > 0 ? currentIndex / totalCards : 0;
  bool get isFinished => currentIndex >= totalCards;
  Flashcard? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  TypingState copyWith({
    List<Flashcard>? cards,
    int? currentIndex,
    int? score,
    String? userInput,
    bool? isAnswered,
    bool? isCorrect,
    bool? isLoading,
    String? error,
    String? lernSetName,
  }) {
    return TypingState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      userInput: userInput ?? this.userInput,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
    );
  }
}

class TypingNotifier extends StateNotifier<TypingState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;
  final int lernSetId;
  final Random _random = Random();

  TypingNotifier(
    this._flashcardRepository,
    this._lernSetRepository,
    this.lernSetId,
  ) : super(TypingState()) {
    loadSession();
  }

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final cards = await _flashcardRepository.getFlashcardsByLernSet(lernSetId);
      final lernSet = await _lernSetRepository.getLernSetById(lernSetId);

      if (cards.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Keine Karteikarten vorhanden',
        );
        return;
      }

      final shuffledCards = List<Flashcard>.from(cards)..shuffle(_random);

      state = TypingState(
        cards: shuffledCards,
        currentIndex: 0,
        score: 0,
        isLoading: false,
        lernSetName: lernSet.name,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateInput(String input) {
    if (state.isAnswered) return;
    state = state.copyWith(userInput: input);
  }

  void submitAnswer() {
    if (state.isAnswered || state.currentCard == null) return;

    final correctAnswer = state.currentCard!.translation.toLowerCase().trim();
    final userAnswer = state.userInput.toLowerCase().trim();
    final isCorrect = userAnswer == correctAnswer;

    state = state.copyWith(
      isAnswered: true,
      isCorrect: isCorrect,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  void nextCard() {
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.totalCards) {
      state = state.copyWith(currentIndex: nextIndex);
      return;
    }

    state = state.copyWith(
      currentIndex: nextIndex,
      userInput: '',
      isAnswered: false,
      isCorrect: false,
    );
  }

  void restart() {
    final shuffledCards = List<Flashcard>.from(state.cards)..shuffle(_random);
    state = TypingState(
      cards: shuffledCards,
      currentIndex: 0,
      score: 0,
      isLoading: false,
      lernSetName: state.lernSetName,
    );
  }
}

final typingProvider = StateNotifierProvider.autoDispose
    .family<TypingNotifier, TypingState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  return TypingNotifier(flashcardRepo, lernSetRepo, lernSetId);
});
