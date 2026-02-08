import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/spaced_repetition_provider.dart';
import '../widgets/flip_card.dart';

class SpacedRepetitionPage extends ConsumerWidget {
  final int lernSetId;

  const SpacedRepetitionPage({super.key, required this.lernSetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spacedRepetitionProvider(lernSetId));

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

    if (state.dueCards.isEmpty) {
      return _buildNoDueCardsScreen(context, state);
    }

    if (state.isFinished) {
      return _buildResultScreen(context, ref, state);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.lernSetName ?? 'Leitner'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Box level indicators
            _BoxLevelIndicator(boxLevelCounts: state.boxLevelCounts),
            const SizedBox(height: 16),
            // Progress
            Text(
              'Karte ${state.currentIndex + 1} / ${state.totalDue}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            // Current card box level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getBoxColor(state.currentCard?.boxLevel ?? 1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBoxColor(state.currentCard?.boxLevel ?? 1),
                ),
              ),
              child: Text(
                'Box ${state.currentCard?.boxLevel ?? 1}',
                style: TextStyle(
                  color: _getBoxColor(state.currentCard?.boxLevel ?? 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Flashcard
            Expanded(
              child: Center(
                child: FlipCard(
                  frontText: state.currentCard?.word ?? '',
                  backText: state.currentCard?.translation ?? '',
                  isFlipped: state.isFlipped,
                  onFlip: () {
                    ref.read(spacedRepetitionProvider(lernSetId).notifier).flip();
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Instructions
            if (!state.isFlipped)
              Text(
                'Tippe auf die Karte, um die Antwort zu sehen',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              )
            else
              Text(
                'Wusstest du die Antwort?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            // Answer buttons (only shown when flipped)
            if (state.isFlipped)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(spacedRepetitionProvider(lernSetId).notifier)
                            .markIncorrect();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Falsch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(spacedRepetitionProvider(lernSetId).notifier)
                            .markCorrect();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Richtig'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDueCardsScreen(BuildContext context, SpacedRepetitionState state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.lernSetName ?? 'Leitner'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _BoxLevelIndicator(boxLevelCounts: state.boxLevelCounts),
            const Spacer(),
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Alles erledigt!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Keine Karten zur Wiederholung fällig.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Komm später wieder, um deinen Fortschritt zu festigen!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Zurück'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(
      BuildContext context, WidgetRef ref, SpacedRepetitionState state) {
    final percentage = state.cardsReviewed > 0
        ? (state.correctCount / state.cardsReviewed * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ergebnis'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _BoxLevelIndicator(boxLevelCounts: state.boxLevelCounts),
            const Spacer(),
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
              '${state.correctCount} von ${state.cardsReviewed} richtig',
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
            const Spacer(),
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
                    ref.read(spacedRepetitionProvider(lernSetId).notifier).restart();
                  },
                  child: const Text('Nochmal prüfen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getResultMessage(int percentage) {
    if (percentage >= 90) return 'Ausgezeichnet! Deine Karten wandern nach oben!';
    if (percentage >= 70) return 'Gut gemacht! Weiter so!';
    if (percentage >= 50) return 'Die Wiederholung hilft!';
    return 'Übung macht den Meister!';
  }

  Color _getBoxColor(int boxLevel) {
    switch (boxLevel) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _BoxLevelIndicator extends StatelessWidget {
  final Map<int, int> boxLevelCounts;

  const _BoxLevelIndicator({required this.boxLevelCounts});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final boxLevel = index + 1;
        final count = boxLevelCounts[boxLevel] ?? 0;
        return _BoxIndicator(
          boxLevel: boxLevel,
          count: count,
        );
      }),
    );
  }
}

class _BoxIndicator extends StatelessWidget {
  final int boxLevel;
  final int count;

  const _BoxIndicator({
    required this.boxLevel,
    required this.count,
  });

  Color get _color {
    switch (boxLevel) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _interval {
    switch (boxLevel) {
      case 1:
        return '1T';
      case 2:
        return '2T';
      case 3:
        return '4T';
      case 4:
        return '7T';
      case 5:
        return '14T';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Box $boxLevel',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          _interval,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
