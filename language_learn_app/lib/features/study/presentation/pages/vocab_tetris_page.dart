import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/vocab_tetris_provider.dart';
import '../widgets/tetris_grid.dart';
import '../widgets/tetris_controls.dart';

class VocabTetrisPage extends ConsumerStatefulWidget {
  final int lernSetId;

  const VocabTetrisPage({super.key, required this.lernSetId});

  @override
  ConsumerState<VocabTetrisPage> createState() => _VocabTetrisPageState();
}

class _VocabTetrisPageState extends ConsumerState<VocabTetrisPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _gameFocusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _gameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabTetrisProvider(widget.lernSetId));

    // Listen for phase changes to handle text input
    ref.listen<VocabTetrisState>(vocabTetrisProvider(widget.lernSetId),
        (previous, next) {
      if (previous?.phase != next.phase) {
        if (next.phase == GamePhase.answeringQuestion) {
          _textController.clear();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _focusNode.requestFocus();
          });
        } else if (next.phase == GamePhase.placingBlocks) {
          _gameFocusNode.requestFocus();
        }
      }
    });

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return _buildErrorScreen(state.error!);
    }

    if (state.isGameOver) {
      return _buildGameOverScreen(state);
    }

    // Switch between Tetris view and Vocabulary view
    return state.phase == GamePhase.placingBlocks
        ? _buildTetrisView(state)
        : _buildVocabularyView(state);
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fehler: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildTetrisView(VocabTetrisState state) {
    final notifier = ref.read(vocabTetrisProvider(widget.lernSetId).notifier);

    return KeyboardListener(
      focusNode: _gameFocusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, notifier),
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.lernSetName ?? 'Vokabel Tetris'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Score: ${state.score}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator (blocks placed this turn)
            _BlocksPlacedIndicator(count: state.blocksPlacedThisTurn),

            Expanded(
              child: Row(
                children: [
                  // Main game grid
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TetrisGrid(
                        grid: state.grid,
                        currentPiece: state.currentPiece,
                        ghostY: notifier.getGhostY(),
                      ),
                    ),
                  ),
                  // Side panel
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Naechstes:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          NextPiecePreview(
                            type: state.nextPieces.isNotEmpty
                                ? state.nextPieces.first
                                : null,
                          ),
                          const Spacer(),
                          _StatDisplay(
                            icon: Icons.layers,
                            label: 'Zeilen',
                            value: '${state.linesCleared}',
                          ),
                          const SizedBox(height: 8),
                          _StatDisplay(
                            icon: Icons.check_circle,
                            label: 'Woerter',
                            value: '${state.wordsCorrect}',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Touch controls
            TetrisControls(
              onLeft: notifier.moveLeft,
              onRight: notifier.moveRight,
              onRotate: notifier.rotate,
              onSoftDrop: notifier.softDrop,
              onHardDrop: notifier.hardDrop,
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event, VocabTetrisNotifier notifier) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        notifier.moveLeft();
        break;
      case LogicalKeyboardKey.arrowRight:
        notifier.moveRight();
        break;
      case LogicalKeyboardKey.arrowUp:
        notifier.rotate();
        break;
      case LogicalKeyboardKey.arrowDown:
        notifier.softDrop();
        break;
      case LogicalKeyboardKey.space:
        notifier.hardDrop();
        break;
    }
  }

  Widget _buildVocabularyView(VocabTetrisState state) {
    final isShowingAnswer = state.phase == GamePhase.showingAnswer;
    final notifier = ref.read(vocabTetrisProvider(widget.lernSetId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uebersetze!'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Score: ${state.score}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Word to translate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      'Uebersetze:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentCard?.word ?? '',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Input field
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: !isShowingAnswer,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Deine Uebersetzung',
                border: const OutlineInputBorder(),
                suffixIcon: state.answerResult != null
                    ? Icon(
                        state.answerResult! ? Icons.check_circle : Icons.cancel,
                        color: state.answerResult! ? Colors.green : Colors.red,
                      )
                    : null,
              ),
              onChanged: (value) {
                notifier.updateInput(value);
              },
              onSubmitted: (_) {
                if (!isShowingAnswer) {
                  notifier.submitAnswer();
                }
              },
            ),

            const SizedBox(height: 24),

            // Show correct answer if in showing phase
            if (isShowingAnswer) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Richtige Antwort:',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentCard?.translation ?? '',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isShowingAnswer) ...[
                  OutlinedButton(
                    onPressed: notifier.dontKnow,
                    child: const Text('Weiss nicht'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: notifier.submitAnswer,
                    child: const Text('Pruefen'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      _textController.clear();
                      notifier.continueToNextWord();
                    },
                    child: const Text('Weiter'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverScreen(VocabTetrisState state) {
    final percentage = state.wordsAttempted > 0
        ? (state.wordsCorrect / state.wordsAttempted * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiel vorbei'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.score >= 500 ? Icons.emoji_events : Icons.videogame_asset,
                size: 80,
                color: state.score >= 500 ? Colors.amber : Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                '${state.score}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Punkte',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _GameOverStat(
                icon: Icons.layers,
                label: 'Zeilen geloescht',
                value: '${state.linesCleared}',
              ),
              const SizedBox(height: 8),
              _GameOverStat(
                icon: Icons.check_circle,
                label: 'Woerter richtig',
                value: '${state.wordsCorrect} / ${state.wordsAttempted}',
              ),
              const SizedBox(height: 8),
              _GameOverStat(
                icon: Icons.percent,
                label: 'Trefferquote',
                value: '$percentage%',
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Zurueck'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(vocabTetrisProvider(widget.lernSetId).notifier)
                          .restart();
                    },
                    child: const Text('Nochmal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlocksPlacedIndicator extends StatelessWidget {
  final int count;

  const _BlocksPlacedIndicator({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bloecke: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (int i = 0; i < 3; i++) ...[
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i < count
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: i < count
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatDisplay({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}

class _GameOverStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GameOverStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
