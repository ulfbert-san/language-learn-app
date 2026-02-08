import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/lernset_repository.dart';

// Tetromino types
enum TetrominoType { I, O, T, S, Z, L, J }

// Game phases
enum GamePhase {
  placingBlocks,
  answeringQuestion,
  showingAnswer,
  gameOver,
}

// Tetromino colors
const Map<TetrominoType, Color> tetrominoColors = {
  TetrominoType.I: Color(0xFF00F0F0), // Cyan
  TetrominoType.O: Color(0xFFF0F000), // Yellow
  TetrominoType.T: Color(0xFFA000F0), // Purple
  TetrominoType.S: Color(0xFF00F000), // Green
  TetrominoType.Z: Color(0xFFF00000), // Red
  TetrominoType.L: Color(0xFFF0A000), // Orange
  TetrominoType.J: Color(0xFF0000F0), // Blue
};

// Tetromino shapes (4x4 matrices for each rotation)
const Map<TetrominoType, List<List<List<int>>>> tetrominoShapes = {
  TetrominoType.I: [
    [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 1, 0],
      [0, 0, 1, 0],
      [0, 0, 1, 0],
      [0, 0, 1, 0]
    ],
    [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 1, 0, 0]
    ],
  ],
  TetrominoType.O: [
    [
      [0, 0, 0, 0],
      [0, 1, 1, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [0, 1, 1, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [0, 1, 1, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [0, 1, 1, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0]
    ],
  ],
  TetrominoType.T: [
    [
      [0, 1, 0, 0],
      [1, 1, 1, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [0, 1, 1, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [1, 1, 1, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [1, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
  ],
  TetrominoType.S: [
    [
      [0, 1, 1, 0],
      [1, 1, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [0, 1, 1, 0],
      [0, 0, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [0, 1, 1, 0],
      [1, 1, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [1, 0, 0, 0],
      [1, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
  ],
  TetrominoType.Z: [
    [
      [1, 1, 0, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 1, 0],
      [0, 1, 1, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [1, 1, 0, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [1, 1, 0, 0],
      [1, 0, 0, 0],
      [0, 0, 0, 0]
    ],
  ],
  TetrominoType.L: [
    [
      [0, 0, 1, 0],
      [1, 1, 1, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 1, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [1, 1, 1, 0],
      [1, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [1, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
  ],
  TetrominoType.J: [
    [
      [1, 0, 0, 0],
      [1, 1, 1, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 1, 0],
      [0, 1, 0, 0],
      [0, 1, 0, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 0, 0, 0],
      [1, 1, 1, 0],
      [0, 0, 1, 0],
      [0, 0, 0, 0]
    ],
    [
      [0, 1, 0, 0],
      [0, 1, 0, 0],
      [1, 1, 0, 0],
      [0, 0, 0, 0]
    ],
  ],
};

class TetrisCell {
  final bool filled;
  final Color? color;

  const TetrisCell({this.filled = false, this.color});
}

class FallingPiece {
  final TetrominoType type;
  final int x;
  final int y;
  final int rotation;

  FallingPiece({
    required this.type,
    this.x = 3,
    this.y = 0,
    this.rotation = 0,
  });

  List<List<int>> get shape => tetrominoShapes[type]![rotation % 4];
  Color get color => tetrominoColors[type]!;

  FallingPiece copyWith({int? x, int? y, int? rotation}) {
    return FallingPiece(
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: (rotation ?? this.rotation) % 4,
    );
  }
}

class VocabTetrisState {
  final bool isLoading;
  final String? error;
  final String? lernSetName;

  final List<List<TetrisCell>> grid;
  final FallingPiece? currentPiece;
  final List<TetrominoType> nextPieces;

  final GamePhase phase;
  final int blocksPlacedThisTurn;

  final List<Flashcard> cards;
  final List<int> remainingCardIndices;
  final List<int> wrongCardIndices; // Cards answered wrong, to retry later
  final int? currentCardIndex;
  final String userInput;
  final bool? answerResult; // null = not answered, true = correct, false = wrong

  final int linesCleared;
  final int wordsCorrect;
  final int wordsAttempted;
  final int score;

  VocabTetrisState({
    this.isLoading = true,
    this.error,
    this.lernSetName,
    this.grid = const [],
    this.currentPiece,
    this.nextPieces = const [],
    this.phase = GamePhase.placingBlocks,
    this.blocksPlacedThisTurn = 0,
    this.cards = const [],
    this.remainingCardIndices = const [],
    this.wrongCardIndices = const [],
    this.currentCardIndex,
    this.userInput = '',
    this.answerResult,
    this.linesCleared = 0,
    this.wordsCorrect = 0,
    this.wordsAttempted = 0,
    this.score = 0,
  });

  Flashcard? get currentCard =>
      currentCardIndex != null && currentCardIndex! < cards.length
          ? cards[currentCardIndex!]
          : null;

  bool get isGameOver => phase == GamePhase.gameOver;
  int get totalCards => cards.length;

  VocabTetrisState copyWith({
    bool? isLoading,
    String? error,
    String? lernSetName,
    List<List<TetrisCell>>? grid,
    FallingPiece? currentPiece,
    bool clearCurrentPiece = false,
    List<TetrominoType>? nextPieces,
    GamePhase? phase,
    int? blocksPlacedThisTurn,
    List<Flashcard>? cards,
    List<int>? remainingCardIndices,
    List<int>? wrongCardIndices,
    int? currentCardIndex,
    bool clearCurrentCardIndex = false,
    String? userInput,
    bool? answerResult,
    bool clearAnswerResult = false,
    int? linesCleared,
    int? wordsCorrect,
    int? wordsAttempted,
    int? score,
  }) {
    return VocabTetrisState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lernSetName: lernSetName ?? this.lernSetName,
      grid: grid ?? this.grid,
      currentPiece: clearCurrentPiece ? null : (currentPiece ?? this.currentPiece),
      nextPieces: nextPieces ?? this.nextPieces,
      phase: phase ?? this.phase,
      blocksPlacedThisTurn: blocksPlacedThisTurn ?? this.blocksPlacedThisTurn,
      cards: cards ?? this.cards,
      remainingCardIndices: remainingCardIndices ?? this.remainingCardIndices,
      wrongCardIndices: wrongCardIndices ?? this.wrongCardIndices,
      currentCardIndex: clearCurrentCardIndex ? null : (currentCardIndex ?? this.currentCardIndex),
      userInput: userInput ?? this.userInput,
      answerResult: clearAnswerResult ? null : (answerResult ?? this.answerResult),
      linesCleared: linesCleared ?? this.linesCleared,
      wordsCorrect: wordsCorrect ?? this.wordsCorrect,
      wordsAttempted: wordsAttempted ?? this.wordsAttempted,
      score: score ?? this.score,
    );
  }
}

class VocabTetrisNotifier extends StateNotifier<VocabTetrisState> {
  final FlashcardRepository _flashcardRepository;
  final LernSetRepository _lernSetRepository;
  final int lernSetId;
  final Random _random = Random();
  Timer? _dropTimer;

  static const int gridWidth = 10;
  static const int gridHeight = 20;
  static const int dropIntervalMs = 800;

  VocabTetrisNotifier(
    this._flashcardRepository,
    this._lernSetRepository,
    this.lernSetId,
  ) : super(VocabTetrisState()) {
    loadGame();
  }

  @override
  void dispose() {
    _dropTimer?.cancel();
    super.dispose();
  }

  Future<void> loadGame() async {
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

      final grid = List.generate(
        gridHeight,
        (_) => List.generate(gridWidth, (_) => const TetrisCell()),
      );

      final indices = List.generate(cards.length, (i) => i);
      indices.shuffle(_random);

      final firstPiece = _randomTetrominoType();
      final nextPieces = [_randomTetrominoType()];

      state = VocabTetrisState(
        isLoading: false,
        lernSetName: lernSet.name,
        grid: grid,
        currentPiece: FallingPiece(type: firstPiece),
        nextPieces: nextPieces,
        phase: GamePhase.placingBlocks,
        blocksPlacedThisTurn: 0,
        cards: cards,
        remainingCardIndices: indices,
      );

      _startDropTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  TetrominoType _randomTetrominoType() {
    return TetrominoType.values[_random.nextInt(TetrominoType.values.length)];
  }

  void _startDropTimer() {
    _dropTimer?.cancel();
    _dropTimer = Timer.periodic(
      const Duration(milliseconds: dropIntervalMs),
      (_) => _moveDown(),
    );
  }

  void _stopDropTimer() {
    _dropTimer?.cancel();
    _dropTimer = null;
  }

  // === COLLISION DETECTION ===

  bool _checkCollision(FallingPiece piece, List<List<TetrisCell>> grid) {
    final shape = piece.shape;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if (shape[row][col] == 0) continue;

        final gridX = piece.x + col;
        final gridY = piece.y + row;

        if (gridX < 0 || gridX >= gridWidth) return true;
        if (gridY >= gridHeight) return true;
        if (gridY < 0) continue;

        if (grid[gridY][gridX].filled) return true;
      }
    }

    return false;
  }

  // === MOVEMENT ===

  void moveLeft() {
    if (state.phase != GamePhase.placingBlocks) return;
    if (state.currentPiece == null) return;

    final moved = state.currentPiece!.copyWith(x: state.currentPiece!.x - 1);
    if (!_checkCollision(moved, state.grid)) {
      state = state.copyWith(currentPiece: moved);
    }
  }

  void moveRight() {
    if (state.phase != GamePhase.placingBlocks) return;
    if (state.currentPiece == null) return;

    final moved = state.currentPiece!.copyWith(x: state.currentPiece!.x + 1);
    if (!_checkCollision(moved, state.grid)) {
      state = state.copyWith(currentPiece: moved);
    }
  }

  void rotate() {
    if (state.phase != GamePhase.placingBlocks) return;
    if (state.currentPiece == null) return;

    final rotated = _rotatePiece(state.currentPiece!, state.grid);
    if (rotated != null) {
      state = state.copyWith(currentPiece: rotated);
    }
  }

  FallingPiece? _rotatePiece(FallingPiece piece, List<List<TetrisCell>> grid) {
    final newRotation = (piece.rotation + 1) % 4;
    final rotatedPiece = piece.copyWith(rotation: newRotation);

    if (!_checkCollision(rotatedPiece, grid)) {
      return rotatedPiece;
    }

    // Wall kicks
    final kicks = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [-1, -1],
      [1, -1],
      [-2, 0],
      [2, 0],
    ];

    for (final kick in kicks) {
      final kickedPiece = rotatedPiece.copyWith(
        x: rotatedPiece.x + kick[0],
        y: rotatedPiece.y + kick[1],
      );
      if (!_checkCollision(kickedPiece, grid)) {
        return kickedPiece;
      }
    }

    return null;
  }

  void softDrop() {
    if (state.phase != GamePhase.placingBlocks) return;
    _moveDown();
  }

  void hardDrop() {
    if (state.phase != GamePhase.placingBlocks) return;
    if (state.currentPiece == null) return;

    var piece = state.currentPiece!;
    while (!_checkCollision(piece.copyWith(y: piece.y + 1), state.grid)) {
      piece = piece.copyWith(y: piece.y + 1);
    }

    state = state.copyWith(currentPiece: piece);
    _lockPiece();
  }

  void _moveDown() {
    if (state.phase != GamePhase.placingBlocks) return;
    if (state.currentPiece == null) return;

    final moved = state.currentPiece!.copyWith(y: state.currentPiece!.y + 1);

    if (!_checkCollision(moved, state.grid)) {
      state = state.copyWith(currentPiece: moved);
    } else {
      _lockPiece();
    }
  }

  // === LOCKING AND LINE CLEARING ===

  void _lockPiece() {
    _stopDropTimer();

    if (state.currentPiece == null) return;

    final gridCopy = state.grid.map((row) => List<TetrisCell>.from(row)).toList();
    final piece = state.currentPiece!;
    final shape = piece.shape;

    // Lock piece into grid
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if (shape[row][col] == 0) continue;

        final gridX = piece.x + col;
        final gridY = piece.y + row;

        if (gridY >= 0 && gridY < gridHeight && gridX >= 0 && gridX < gridWidth) {
          gridCopy[gridY][gridX] = TetrisCell(filled: true, color: piece.color);
        }
      }
    }

    // Clear complete lines
    final linesCleared = _clearLines(gridCopy);
    final newLinesCleared = state.linesCleared + linesCleared;
    final lineScore = linesCleared * 100;

    final newBlocksPlaced = state.blocksPlacedThisTurn + 1;

    // Check if 3 blocks placed -> switch to vocabulary
    if (newBlocksPlaced >= 3) {
      final nextCardIndex = _getNextCardIndex();

      state = state.copyWith(
        grid: gridCopy,
        clearCurrentPiece: true,
        linesCleared: newLinesCleared,
        score: state.score + lineScore,
        blocksPlacedThisTurn: 0,
        phase: GamePhase.answeringQuestion,
        currentCardIndex: nextCardIndex,
        userInput: '',
        clearAnswerResult: true,
      );
    } else {
      _spawnNextPiece(gridCopy, newLinesCleared, lineScore, newBlocksPlaced);
    }
  }

  int _clearLines(List<List<TetrisCell>> grid) {
    int linesCleared = 0;
    int writeRow = gridHeight - 1;

    for (int readRow = gridHeight - 1; readRow >= 0; readRow--) {
      if (_isLineFull(grid[readRow])) {
        linesCleared++;
        continue;
      }

      if (writeRow != readRow) {
        grid[writeRow] = List.from(grid[readRow]);
      }
      writeRow--;
    }

    while (writeRow >= 0) {
      grid[writeRow] = List.generate(gridWidth, (_) => const TetrisCell());
      writeRow--;
    }

    return linesCleared;
  }

  bool _isLineFull(List<TetrisCell> row) {
    return row.every((cell) => cell.filled);
  }

  void _spawnNextPiece(
    List<List<TetrisCell>> grid,
    int linesCleared,
    int lineScore,
    int blocksPlaced,
  ) {
    final nextType = state.nextPieces.first;
    final newPiece = FallingPiece(type: nextType);

    // Check game over
    if (_checkCollision(newPiece, grid)) {
      state = state.copyWith(
        grid: grid,
        clearCurrentPiece: true,
        linesCleared: linesCleared,
        score: state.score + lineScore,
        phase: GamePhase.gameOver,
      );
      return;
    }

    final newNextPieces = [
      ...state.nextPieces.sublist(1),
      _randomTetrominoType(),
    ];

    state = state.copyWith(
      grid: grid,
      currentPiece: newPiece,
      nextPieces: newNextPieces,
      linesCleared: linesCleared,
      score: state.score + lineScore,
      blocksPlacedThisTurn: blocksPlaced,
    );

    _startDropTimer();
  }

  // === VOCABULARY ===

  int? _getNextCardIndex() {
    var remaining = List<int>.from(state.remainingCardIndices);
    var wrongList = List<int>.from(state.wrongCardIndices);

    if (remaining.isNotEmpty) {
      // Still have words in current round
      final nextIndex = remaining.removeAt(0);
      state = state.copyWith(remainingCardIndices: remaining);
      return nextIndex;
    }

    if (wrongList.isNotEmpty) {
      // Current round done, but have wrong words to retry
      wrongList.shuffle(_random);
      final nextIndex = wrongList.removeAt(0);
      state = state.copyWith(
        remainingCardIndices: wrongList,
        wrongCardIndices: [],
      );
      return nextIndex;
    }

    // All words done and all correct - reshuffle all for new round
    remaining = List.generate(state.cards.length, (i) => i);
    remaining.shuffle(_random);

    if (remaining.isEmpty) return null;

    final nextIndex = remaining.removeAt(0);
    state = state.copyWith(
      remainingCardIndices: remaining,
      wrongCardIndices: [],
    );

    return nextIndex;
  }

  void updateInput(String input) {
    if (state.phase != GamePhase.answeringQuestion) return;
    state = state.copyWith(userInput: input);
  }

  void submitAnswer() {
    if (state.phase != GamePhase.answeringQuestion) return;
    if (state.currentCard == null) return;

    final correctAnswer = state.currentCard!.translation.toLowerCase().trim();
    final userAnswer = state.userInput.toLowerCase().trim();
    final isCorrect = userAnswer == correctAnswer;

    if (isCorrect) {
      state = state.copyWith(
        answerResult: true,
        wordsAttempted: state.wordsAttempted + 1,
        wordsCorrect: state.wordsCorrect + 1,
        score: state.score + 50,
      );
      _startNewTetrisRound();
    } else {
      // Wrong answer - add to wrong list, show answer then continue to next word
      final newWrongList = [...state.wrongCardIndices, state.currentCardIndex!];
      state = state.copyWith(
        answerResult: false,
        phase: GamePhase.showingAnswer,
        wordsAttempted: state.wordsAttempted + 1,
        wrongCardIndices: newWrongList,
      );
    }
  }

  void dontKnow() {
    if (state.phase != GamePhase.answeringQuestion) return;
    if (state.currentCardIndex == null) return;

    // Add to wrong list, show answer
    final newWrongList = [...state.wrongCardIndices, state.currentCardIndex!];
    state = state.copyWith(
      phase: GamePhase.showingAnswer,
      wordsAttempted: state.wordsAttempted + 1,
      wrongCardIndices: newWrongList,
    );
  }

  void continueToNextWord() {
    if (state.phase != GamePhase.showingAnswer) return;

    // Get next word
    final nextCardIndex = _getNextCardIndex();

    if (nextCardIndex != null) {
      // More words to answer
      state = state.copyWith(
        phase: GamePhase.answeringQuestion,
        currentCardIndex: nextCardIndex,
        userInput: '',
        clearAnswerResult: true,
      );
    } else {
      // No more words - back to Tetris
      _startNewTetrisRound();
    }
  }

  void _startNewTetrisRound() {
    final nextType = state.nextPieces.first;
    final newPiece = FallingPiece(type: nextType);

    // Check game over
    if (_checkCollision(newPiece, state.grid)) {
      state = state.copyWith(phase: GamePhase.gameOver);
      return;
    }

    final newNextPieces = [
      ...state.nextPieces.sublist(1),
      _randomTetrominoType(),
    ];

    state = state.copyWith(
      currentPiece: newPiece,
      nextPieces: newNextPieces,
      phase: GamePhase.placingBlocks,
      blocksPlacedThisTurn: 0,
      clearCurrentCardIndex: true,
      userInput: '',
      clearAnswerResult: true,
    );

    _startDropTimer();
  }

  void restart() {
    _stopDropTimer();
    loadGame();
  }

  // Ghost piece position (for preview)
  int getGhostY() {
    if (state.currentPiece == null) return 0;

    var ghostY = state.currentPiece!.y;
    while (!_checkCollision(
      state.currentPiece!.copyWith(y: ghostY + 1),
      state.grid,
    )) {
      ghostY++;
    }
    return ghostY;
  }
}

final vocabTetrisProvider = StateNotifierProvider.autoDispose
    .family<VocabTetrisNotifier, VocabTetrisState, int>((ref, lernSetId) {
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final lernSetRepo = ref.watch(lernSetRepositoryProvider);
  return VocabTetrisNotifier(flashcardRepo, lernSetRepo, lernSetId);
});
