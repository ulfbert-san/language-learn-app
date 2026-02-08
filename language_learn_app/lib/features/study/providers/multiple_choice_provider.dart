import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

class MultipleChoiceState {
  final List<Flashcard> cards;
  final int currentQuestionIndex;
  final int score;
  final List<String> currentOptions;
  final String correctAnswer;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isLoading;
  final String? error;
  final String? lernSetName;

  MultipleChoiceState({
    this.cards = const [],
    this.currentQuestionIndex = 0,
    this.score = 0,
    this.currentOptions = const [],
    this.correctAnswer = '',
    this.selectedAnswer,
    this.isAnswered = false,
    this.isLoading = true,
    this.error,
    this.lernSetName,
  });

  int get totalQuestions => cards.length;
  int get currentQuestionNumber => currentQuestionIndex + 1;
  double get progress =>
      totalQuestions > 0 ? currentQuestionIndex / totalQuestions : 0;
  bool get isFinished => currentQuestionIndex >= totalQuestions;
  Flashcard? get currentCard =>
      cards.isNotEmpty && currentQuestionIndex < cards.length
          ? cards[currentQuestionIndex]
          : null;

  MultipleChoiceState copyWith({
    List<Flashcard>? cards,
    int? currentQuestionIndex,
    int? score,
    List<String>? currentOptions,
    String? correctAnswer,
    String? selectedAnswer,
    bool? isAnswered,
    bool? isLoading,
    String? error,
    String? lernSetName,
  }) {
    return MultipleChoiceState(
      cards: cards ?? this.cards,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      currentOptions: currentOptions ?? this.currentOptions,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      selectedAnswer: selectedAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
    );
  }
}

class MultipleChoiceNotifier extends StateNotifier<MultipleChoiceState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;
  final int lernSetId;
  final Random _random = Random();

  MultipleChoiceNotifier(
    this._flashcardRepository,
    this._lernSetRepository,
    this.lernSetId,
  ) : super(MultipleChoiceState()) {
    loadQuiz();
  }

  Future<void> loadQuiz() async {
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

      // Shuffle cards for quiz
      final shuffledCards = List<Flashcard>.from(cards)..shuffle(_random);

      state = MultipleChoiceState(
        cards: shuffledCards,
        currentQuestionIndex: 0,
        score: 0,
        isLoading: false,
        lernSetName: lernSet.name,
      );

      _generateOptions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _generateOptions() {
    final currentCard = state.currentCard;
    if (currentCard == null) return;

    final correctAnswer = currentCard.translation;
    final otherCards = state.cards
        .where((c) => c.id != currentCard.id)
        .toList();

    // Get 3 random wrong answers
    otherCards.shuffle(_random);
    final wrongAnswers = otherCards
        .take(3)
        .map((c) => c.translation)
        .toList();

    // If we don't have enough cards, fill with placeholders
    while (wrongAnswers.length < 3) {
      wrongAnswers.add('---');
    }

    // Combine and shuffle options
    final options = [correctAnswer, ...wrongAnswers]..shuffle(_random);

    state = state.copyWith(
      currentOptions: options,
      correctAnswer: correctAnswer,
      selectedAnswer: null,
      isAnswered: false,
    );
  }

  void submitAnswer(String answer) {
    if (state.isAnswered) return;

    final isCorrect = answer == state.correctAnswer;
    state = state.copyWith(
      selectedAnswer: answer,
      isAnswered: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  void nextQuestion() {
    final nextIndex = state.currentQuestionIndex + 1;

    if (nextIndex >= state.totalQuestions) {
      // Quiz finished
      state = state.copyWith(currentQuestionIndex: nextIndex);
      return;
    }

    state = state.copyWith(
      currentQuestionIndex: nextIndex,
      selectedAnswer: null,
      isAnswered: false,
    );
    _generateOptions();
  }

  void restartQuiz() {
    final shuffledCards = List<Flashcard>.from(state.cards)..shuffle(_random);
    state = MultipleChoiceState(
      cards: shuffledCards,
      currentQuestionIndex: 0,
      score: 0,
      isLoading: false,
      lernSetName: state.lernSetName,
    );
    _generateOptions();
  }
}

final multipleChoiceProvider = StateNotifierProvider.autoDispose
    .family<MultipleChoiceNotifier, MultipleChoiceState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  return MultipleChoiceNotifier(flashcardRepo, lernSetRepo, lernSetId);
});
