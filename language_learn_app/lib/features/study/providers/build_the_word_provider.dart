import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:hyphenatorx/languages/language_de_1996.dart';
import 'package:hyphenatorx/languages/language_tr.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';
import '../../settings/providers/settings_provider.dart';

class WordBlock {
  final String text;
  final int originalIndex;

  WordBlock({required this.text, required this.originalIndex});
}

class BuildTheWordState {
  final List<Flashcard> cards;
  final int currentIndex;
  final int score;
  final List<WordBlock> availableBlocks;
  final List<WordBlock?> placedBlocks;
  final int totalSlots;
  final bool isAnswered;
  final bool isCorrect;
  final bool isLoading;
  final String? error;
  final String? lernSetName;
  final String effectiveLanguage;

  BuildTheWordState({
    this.cards = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.availableBlocks = const [],
    this.placedBlocks = const [],
    this.totalSlots = 0,
    this.isAnswered = false,
    this.isCorrect = false,
    this.isLoading = true,
    this.error,
    this.lernSetName,
    this.effectiveLanguage = 'de',
  });

  int get totalCards => cards.length;
  int get currentNumber => currentIndex + 1;
  double get progress => totalCards > 0 ? currentIndex / totalCards : 0;
  bool get isFinished => currentIndex >= totalCards;
  Flashcard? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  bool get allSlotsFilled {
    if (placedBlocks.isEmpty) return false;
    return placedBlocks.every((block) => block != null);
  }

  String get constructedWord {
    return placedBlocks
        .where((b) => b != null)
        .map((b) => b!.text)
        .join();
  }

  BuildTheWordState copyWith({
    List<Flashcard>? cards,
    int? currentIndex,
    int? score,
    List<WordBlock>? availableBlocks,
    List<WordBlock?>? placedBlocks,
    int? totalSlots,
    bool? isAnswered,
    bool? isCorrect,
    bool? isLoading,
    String? error,
    String? lernSetName,
    String? effectiveLanguage,
  }) {
    return BuildTheWordState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      availableBlocks: availableBlocks ?? this.availableBlocks,
      placedBlocks: placedBlocks ?? this.placedBlocks,
      totalSlots: totalSlots ?? this.totalSlots,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
      effectiveLanguage: effectiveLanguage ?? this.effectiveLanguage,
    );
  }
}

class BuildTheWordNotifier extends StateNotifier<BuildTheWordState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;
  final int lernSetId;
  final String globalLanguage;
  final Random _random = Random();

  late final Hyphenator _hyphenatorDe;
  late final Hyphenator _hyphenatorTr;

  BuildTheWordNotifier(
    this._flashcardRepository,
    this._lernSetRepository,
    this.lernSetId,
    this.globalLanguage,
  ) : super(BuildTheWordState()) {
    _hyphenatorDe = Hyphenator(Language_de_1996());
    _hyphenatorTr = Hyphenator(Language_tr());
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
      final effectiveLanguage = lernSet.language ?? globalLanguage;

      state = BuildTheWordState(
        cards: shuffledCards,
        currentIndex: 0,
        score: 0,
        isLoading: false,
        lernSetName: lernSet.name,
        effectiveLanguage: effectiveLanguage,
      );

      _generateBlocks();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<String> _getSyllables(String word) {
    final hyphenator =
        state.effectiveLanguage == 'tr' ? _hyphenatorTr : _hyphenatorDe;

    try {
      final syllables = hyphenator.syllablesWord(word);
      if (syllables.isNotEmpty) {
        return syllables;
      }
    } catch (_) {
      // Fallback to simple splitting if hyphenation fails
    }

    // Fallback: split into chunks of 2-3 characters
    return _fallbackSplit(word);
  }

  List<String> _fallbackSplit(String word) {
    final chunks = <String>[];
    int index = 0;

    while (index < word.length) {
      final remaining = word.length - index;
      int chunkSize;

      if (remaining <= 3) {
        chunkSize = remaining;
      } else if (remaining == 4) {
        chunkSize = 2;
      } else {
        chunkSize = word.length >= 6 ? 3 : 2;
        if (remaining - chunkSize == 1) {
          chunkSize = 2;
        }
      }

      chunks.add(word.substring(index, index + chunkSize));
      index += chunkSize;
    }

    return chunks;
  }

  void _generateBlocks() {
    final word = state.currentCard?.word ?? '';
    if (word.isEmpty) return;

    final syllables = _getSyllables(word);
    final blocks = <WordBlock>[];

    for (int i = 0; i < syllables.length; i++) {
      blocks.add(WordBlock(text: syllables[i], originalIndex: i));
    }

    final shuffledBlocks = List<WordBlock>.from(blocks)..shuffle(_random);

    state = state.copyWith(
      availableBlocks: shuffledBlocks,
      placedBlocks: List.filled(blocks.length, null),
      totalSlots: blocks.length,
      isAnswered: false,
      isCorrect: false,
    );
  }

  void placeBlock(int blockIndex) {
    if (state.isAnswered) return;
    if (blockIndex >= state.availableBlocks.length) return;

    final block = state.availableBlocks[blockIndex];

    // Find first empty slot
    final emptySlotIndex = state.placedBlocks.indexWhere((b) => b == null);
    if (emptySlotIndex == -1) return;

    final newAvailable = List<WordBlock>.from(state.availableBlocks);
    newAvailable.removeAt(blockIndex);

    final newPlaced = List<WordBlock?>.from(state.placedBlocks);
    newPlaced[emptySlotIndex] = block;

    state = state.copyWith(
      availableBlocks: newAvailable,
      placedBlocks: newPlaced,
    );
  }

  void removeBlock(int slotIndex) {
    if (state.isAnswered) return;
    if (slotIndex >= state.placedBlocks.length) return;

    final block = state.placedBlocks[slotIndex];
    if (block == null) return;

    final newAvailable = List<WordBlock>.from(state.availableBlocks)..add(block);
    final newPlaced = List<WordBlock?>.from(state.placedBlocks);

    // Shift blocks left to fill the gap
    for (int i = slotIndex; i < newPlaced.length - 1; i++) {
      newPlaced[i] = newPlaced[i + 1];
    }
    newPlaced[newPlaced.length - 1] = null;

    state = state.copyWith(
      availableBlocks: newAvailable,
      placedBlocks: newPlaced,
    );
  }

  void submitAnswer() {
    if (state.isAnswered) return;
    if (!state.allSlotsFilled) return;

    final correctWord = state.currentCard!.word;
    final constructedWord = state.constructedWord;
    final isCorrect = constructedWord == correctWord;

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
      availableBlocks: [],
      placedBlocks: [],
      isAnswered: false,
      isCorrect: false,
    );

    _generateBlocks();
  }

  void restart() {
    final shuffledCards = List<Flashcard>.from(state.cards)..shuffle(_random);
    state = BuildTheWordState(
      cards: shuffledCards,
      currentIndex: 0,
      score: 0,
      isLoading: false,
      lernSetName: state.lernSetName,
      effectiveLanguage: state.effectiveLanguage,
    );
    _generateBlocks();
  }
}

final buildTheWordProvider = StateNotifierProvider.autoDispose
    .family<BuildTheWordNotifier, BuildTheWordState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  final globalLanguage = ref.watch(syllableLanguageProvider);
  return BuildTheWordNotifier(flashcardRepo, lernSetRepo, lernSetId, globalLanguage);
});
