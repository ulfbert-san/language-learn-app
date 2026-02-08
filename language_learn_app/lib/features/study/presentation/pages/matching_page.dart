import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/matching_provider.dart';

class MatchingPage extends ConsumerWidget {
  final int lernSetId;

  const MatchingPage({super.key, required this.lernSetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingProvider(lernSetId));

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

    if (state.isRoundComplete && !state.isFinished) {
      return _buildRoundCompleteScreen(context, ref, state);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.lernSetName ?? 'Zuordnung'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Round indicator
            Text(
              'Runde ${state.currentRound} / ${state.totalRounds}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verbinde die Paare',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Matching area
            Expanded(
              child: Row(
                children: [
                  // Words column
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Wörter',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.shuffledWords.length,
                            itemBuilder: (context, index) {
                              final word = state.shuffledWords[index];
                              final pair = state.pairs.firstWhere((p) => p.word == word);
                              final isMatched = pair.isMatched;
                              final isSelected = state.selectedWordIndex == index;
                              final isWrong = state.showWrongFeedback &&
                                  state.wrongWordIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _MatchingTile(
                                  text: word,
                                  isMatched: isMatched,
                                  isSelected: isSelected,
                                  isWrong: isWrong,
                                  onTap: isMatched
                                      ? null
                                      : () {
                                          ref
                                              .read(matchingProvider(lernSetId)
                                                  .notifier)
                                              .selectWord(index);
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Translations column
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Übersetzungen',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.shuffledTranslations.length,
                            itemBuilder: (context, index) {
                              final translation = state.shuffledTranslations[index];
                              final pair = state.pairs
                                  .firstWhere((p) => p.translation == translation);
                              final isMatched = pair.isMatched;
                              final isSelected =
                                  state.selectedTranslationIndex == index;
                              final isWrong = state.showWrongFeedback &&
                                  state.wrongTranslationIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _MatchingTile(
                                  text: translation,
                                  isMatched: isMatched,
                                  isSelected: isSelected,
                                  isWrong: isWrong,
                                  onTap: isMatched
                                      ? null
                                      : () {
                                          ref
                                              .read(matchingProvider(lernSetId)
                                                  .notifier)
                                              .selectTranslation(index);
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress
            Text(
              '${state.matchedCount} / ${state.pairs.length} Paare gefunden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundCompleteScreen(
      BuildContext context, WidgetRef ref, MatchingState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runde abgeschlossen'),
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
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Runde ${state.currentRound} abgeschlossen!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Noch ${state.totalRounds - state.currentRound} Runden übrig',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  ref.read(matchingProvider(lernSetId).notifier).nextRound();
                },
                child: const Text('Nächste Runde'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen(
      BuildContext context, WidgetRef ref, MatchingState state) {
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
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                'Geschafft!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '${state.allCards.length} Paare in ${state.attempts} Versuchen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _getEfficiencyMessage(state.allCards.length, state.attempts),
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
                      ref.read(matchingProvider(lernSetId).notifier).restart();
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

  String _getEfficiencyMessage(int pairs, int attempts) {
    final efficiency = pairs / attempts;
    if (efficiency >= 0.9) return 'Perfekt! Kaum Fehler!';
    if (efficiency >= 0.7) return 'Sehr gut!';
    if (efficiency >= 0.5) return 'Gut gemacht!';
    return 'Weiter üben!';
  }
}

class _MatchingTile extends StatelessWidget {
  final String text;
  final bool isMatched;
  final bool isSelected;
  final bool isWrong;
  final VoidCallback? onTap;

  const _MatchingTile({
    required this.text,
    required this.isMatched,
    required this.isSelected,
    required this.isWrong,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? borderColor;

    if (isMatched) {
      backgroundColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
    } else if (isWrong) {
      backgroundColor = Colors.red.withOpacity(0.2);
      borderColor = Colors.red;
    } else if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isMatched ? 0.5 : 1.0,
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isMatched ? Colors.green : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
