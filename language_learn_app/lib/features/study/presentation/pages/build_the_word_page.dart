import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/build_the_word_provider.dart';

class BuildTheWordPage extends ConsumerWidget {
  final int lernSetId;

  const BuildTheWordPage({super.key, required this.lernSetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buildTheWordProvider(lernSetId));

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
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
              Text('Fehler: ${state.error}'),
            ],
          ),
        ),
      );
    }

    if (state.isFinished) {
      return _buildResultScreen(context, ref, state);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.lernSetName ?? 'Wortbau'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: Colors.grey[800],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Karte ${state.currentNumber} / ${state.totalCards}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Translation hint
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Baue das Wort für:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.currentCard?.translation ?? '',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Available blocks
                  _buildAvailableBlocks(context, ref, state),
                  const SizedBox(height: 24),
                  // Placement slots
                  _buildPlacementSlots(context, ref, state),
                  const SizedBox(height: 16),
                  // Feedback
                  if (state.isAnswered) _buildFeedback(context, state),
                  const Spacer(),
                  // Score
                  Text(
                    'Punktzahl: ${state.score} / ${state.currentNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  _buildActionButton(context, ref, state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableBlocks(
    BuildContext context,
    WidgetRef ref,
    BuildTheWordState state,
  ) {
    if (state.availableBlocks.isEmpty) {
      return const SizedBox(height: 60);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: state.availableBlocks.asMap().entries.map((entry) {
        final index = entry.key;
        final block = entry.value;
        return _BlockTile(
          text: block.text,
          isPlaced: false,
          isDisabled: state.isAnswered,
          onTap: () {
            ref.read(buildTheWordProvider(lernSetId).notifier).placeBlock(index);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPlacementSlots(
    BuildContext context,
    WidgetRef ref,
    BuildTheWordState state,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: state.placedBlocks.asMap().entries.map((entry) {
        final index = entry.key;
        final block = entry.value;

        if (block == null) {
          return const _SlotPlaceholder();
        }

        return _BlockTile(
          text: block.text,
          isPlaced: true,
          isDisabled: state.isAnswered,
          isCorrect: state.isAnswered && state.isCorrect,
          isWrong: state.isAnswered && !state.isCorrect,
          onTap: () {
            ref.read(buildTheWordProvider(lernSetId).notifier).removeBlock(index);
          },
        );
      }).toList(),
    );
  }

  Widget _buildFeedback(BuildContext context, BuildTheWordState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.isCorrect
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.isCorrect ? Colors.green : Colors.red,
        ),
      ),
      child: Column(
        children: [
          Text(
            state.isCorrect ? 'Richtig!' : 'Falsch!',
            style: TextStyle(
              color: state.isCorrect ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (!state.isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Richtige Antwort: ${state.currentCard?.word}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    BuildTheWordState state,
  ) {
    if (!state.isAnswered) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: state.allSlotsFilled
              ? () {
                  ref.read(buildTheWordProvider(lernSetId).notifier).submitAnswer();
                }
              : null,
          child: const Text('Prüfen'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ref.read(buildTheWordProvider(lernSetId).notifier).nextCard();
        },
        child: const Text('Weiter'),
      ),
    );
  }

  Widget _buildResultScreen(
    BuildContext context,
    WidgetRef ref,
    BuildTheWordState state,
  ) {
    final percentage = state.totalCards > 0
        ? (state.score / state.totalCards * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ergebnis'),
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
                percentage >= 70 ? Icons.emoji_events : Icons.school,
                size: 80,
                color: percentage >= 70 ? Colors.amber : Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.score} von ${state.totalCards} richtig',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _getResultMessage(percentage),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Zurück'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(buildTheWordProvider(lernSetId).notifier).restart();
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

  String _getResultMessage(int percentage) {
    if (percentage >= 90) return 'Ausgezeichnet!';
    if (percentage >= 70) return 'Gut gemacht!';
    if (percentage >= 50) return 'Weiter üben!';
    return 'Nicht aufgeben, versuch es nochmal!';
  }
}

class _BlockTile extends StatelessWidget {
  final String text;
  final bool isPlaced;
  final bool isDisabled;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _BlockTile({
    required this.text,
    required this.isPlaced,
    required this.onTap,
    this.isDisabled = false,
    this.isCorrect = false,
    this.isWrong = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? borderColor;

    if (isCorrect) {
      backgroundColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
    } else if (isWrong) {
      backgroundColor = Colors.red.withOpacity(0.2);
      borderColor = Colors.red;
    } else if (isPlaced) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor ?? Theme.of(context).colorScheme.outline,
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}

class _SlotPlaceholder extends StatelessWidget {
  const _SlotPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minWidth: 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Text(
        '___',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
