import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

class MatchingPair {
  final int id;
  final String word;
  final String translation;
  bool isMatched;

  MatchingPair({
    required this.id,
    required this.word,
    required this.translation,
    this.isMatched = false,
  });

  MatchingPair copyWith({bool? isMatched}) {
    return MatchingPair(
      id: id,
      word: word,
      translation: translation,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

class MatchingState {
  final List<MatchingPair> pairs;
  final List<String> shuffledWords;
  final List<String> shuffledTranslations;
  final int? selectedWordIndex;
  final int? selectedTranslationIndex;
  final int matchedCount;
  final int attempts;
  final int currentRound;
  final int totalRounds;
  final bool isLoading;
  final String? error;
  final String? lernSetName;
  final List<Flashcard> allCards;
  final bool showWrongFeedback;
  final int wrongWordIndex;
  final int wrongTranslationIndex;

  MatchingState({
    this.pairs = const [],
    this.shuffledWords = const [],
    this.shuffledTranslations = const [],
    this.selectedWordIndex,
    this.selectedTranslationIndex,
    this.matchedCount = 0,
    this.attempts = 0,
    this.currentRound = 1,
    this.totalRounds = 1,
    this.isLoading = true,
    this.error,
    this.lernSetName,
    this.allCards = const [],
    this.showWrongFeedback = false,
    this.wrongWordIndex = -1,
    this.wrongTranslationIndex = -1,
  });

  bool get isRoundComplete => matchedCount >= pairs.length && pairs.isNotEmpty;
  bool get isFinished => isRoundComplete && currentRound >= totalRounds;
  int get pairsPerRound => 5;

  MatchingState copyWith({
    List<MatchingPair>? pairs,
    List<String>? shuffledWords,
    List<String>? shuffledTranslations,
    int? selectedWordIndex,
    int? selectedTranslationIndex,
    int? matchedCount,
    int? attempts,
    int? currentRound,
    int? totalRounds,
    bool? isLoading,
    String? error,
    String? lernSetName,
    List<Flashcard>? allCards,
    bool? showWrongFeedback,
    int? wrongWordIndex,
    int? wrongTranslationIndex,
    bool clearWordSelection = false,
    bool clearTranslationSelection = false,
  }) {
    return MatchingState(
      pairs: pairs ?? this.pairs,
      shuffledWords: shuffledWords ?? this.shuffledWords,
      shuffledTranslations: shuffledTranslations ?? this.shuffledTranslations,
      selectedWordIndex: clearWordSelection ? null : (selectedWordIndex ?? this.selectedWordIndex),
      selectedTranslationIndex: clearTranslationSelection ? null : (selectedTranslationIndex ?? this.selectedTranslationIndex),
      matchedCount: matchedCount ?? this.matchedCount,
      attempts: attempts ?? this.attempts,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
      allCards: allCards ?? this.allCards,
      showWrongFeedback: showWrongFeedback ?? this.showWrongFeedback,
      wrongWordIndex: wrongWordIndex ?? this.wrongWordIndex,
      wrongTranslationIndex: wrongTranslationIndex ?? this.wrongTranslationIndex,
    );
  }
}

class MatchingNotifier extends StateNotifier<MatchingState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;
  final int lernSetId;
  final Random _random = Random();

  MatchingNotifier(
    this._flashcardRepository,
    this._lernSetRepository,
    this.lernSetId,
  ) : super(MatchingState()) {
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
      final totalRounds = (shuffledCards.length / state.pairsPerRound).ceil();

      state = MatchingState(
        allCards: shuffledCards,
        currentRound: 1,
        totalRounds: totalRounds,
        isLoading: false,
        lernSetName: lernSet.name,
      );

      _setupRound();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRound() {
    final startIndex = (state.currentRound - 1) * state.pairsPerRound;
    final endIndex = (startIndex + state.pairsPerRound).clamp(0, state.allCards.length);

    final roundCards = state.allCards.sublist(startIndex, endIndex);

    final pairs = roundCards.map((card) => MatchingPair(
      id: card.id,
      word: card.word,
      translation: card.translation,
    )).toList();

    final words = pairs.map((p) => p.word).toList()..shuffle(_random);
    final translations = pairs.map((p) => p.translation).toList()..shuffle(_random);

    state = state.copyWith(
      pairs: pairs,
      shuffledWords: words,
      shuffledTranslations: translations,
      matchedCount: 0,
      clearWordSelection: true,
      clearTranslationSelection: true,
    );
  }

  void selectWord(int index) {
    if (state.showWrongFeedback) return;

    final word = state.shuffledWords[index];
    final pair = state.pairs.firstWhere((p) => p.word == word);
    if (pair.isMatched) return;

    state = state.copyWith(selectedWordIndex: index);
    _checkMatch();
  }

  void selectTranslation(int index) {
    if (state.showWrongFeedback) return;

    final translation = state.shuffledTranslations[index];
    final pair = state.pairs.firstWhere((p) => p.translation == translation);
    if (pair.isMatched) return;

    state = state.copyWith(selectedTranslationIndex: index);
    _checkMatch();
  }

  void _checkMatch() {
    if (state.selectedWordIndex == null || state.selectedTranslationIndex == null) {
      return;
    }

    final selectedWord = state.shuffledWords[state.selectedWordIndex!];
    final selectedTranslation = state.shuffledTranslations[state.selectedTranslationIndex!];

    final matchingPair = state.pairs.firstWhere(
      (p) => p.word == selectedWord,
    );

    state = state.copyWith(attempts: state.attempts + 1);

    if (matchingPair.translation == selectedTranslation) {
      // Correct match
      final updatedPairs = state.pairs.map((p) {
        if (p.word == selectedWord) {
          return p.copyWith(isMatched: true);
        }
        return p;
      }).toList();

      state = state.copyWith(
        pairs: updatedPairs,
        matchedCount: state.matchedCount + 1,
        clearWordSelection: true,
        clearTranslationSelection: true,
      );
    } else {
      // Wrong match - show feedback briefly
      state = state.copyWith(
        showWrongFeedback: true,
        wrongWordIndex: state.selectedWordIndex!,
        wrongTranslationIndex: state.selectedTranslationIndex!,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!state.showWrongFeedback) return;
        state = state.copyWith(
          showWrongFeedback: false,
          wrongWordIndex: -1,
          wrongTranslationIndex: -1,
          clearWordSelection: true,
          clearTranslationSelection: true,
        );
      });
    }
  }

  void nextRound() {
    if (state.currentRound >= state.totalRounds) return;

    state = state.copyWith(currentRound: state.currentRound + 1);
    _setupRound();
  }

  void restart() {
    final shuffledCards = List<Flashcard>.from(state.allCards)..shuffle(_random);
    final totalRounds = (shuffledCards.length / state.pairsPerRound).ceil();

    state = MatchingState(
      allCards: shuffledCards,
      currentRound: 1,
      totalRounds: totalRounds,
      attempts: 0,
      isLoading: false,
      lernSetName: state.lernSetName,
    );

    _setupRound();
  }
}

final matchingProvider = StateNotifierProvider.autoDispose
    .family<MatchingNotifier, MatchingState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  return MatchingNotifier(flashcardRepo, lernSetRepo, lernSetId);
});
