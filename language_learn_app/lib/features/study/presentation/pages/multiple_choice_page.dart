import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/multiple_choice_provider.dart';

class MultipleChoicePage extends ConsumerWidget {
  final int lernSetId;

  const MultipleChoicePage({super.key, required this.lernSetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multipleChoiceProvider(lernSetId));

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
        title: Text(state.lernSetName ?? 'Multiple Choice'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
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
                  // Question counter
                  Text(
                    'Frage ${state.currentQuestionNumber} / ${state.totalQuestions}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  // Question (word)
                  Text(
                    state.currentCard?.word ?? '',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Answer options
                  ...state.currentOptions.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnswerButton(
                          text: option,
                          isSelected: state.selectedAnswer == option,
                          isCorrect: option == state.correctAnswer,
                          isAnswered: state.isAnswered,
                          onTap: state.isAnswered
                              ? null
                              : () {
                                  ref
                                      .read(multipleChoiceProvider(lernSetId)
                                          .notifier)
                                      .submitAnswer(option);
                                },
                        ),
                      )),
                  const Spacer(),
                  // Score display
                  Text(
                    'Punktzahl: ${state.score} / ${state.currentQuestionNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Next button
                  if (state.isAnswered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(multipleChoiceProvider(lernSetId).notifier)
                              .nextQuestion();
                        },
                        child: const Text('Weiter'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(
      BuildContext context, WidgetRef ref, MultipleChoiceState state) {
    final percentage = state.totalQuestions > 0
        ? (state.score / state.totalQuestions * 100).round()
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
                '${state.score} von ${state.totalQuestions} richtig',
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
                      ref
                          .read(multipleChoiceProvider(lernSetId).notifier)
                          .restartQuiz();
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

class _AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback? onTap;

  const _AnswerButton({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? borderColor;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.2);
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red.withOpacity(0.2);
        borderColor = Colors.red;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAnswered && isCorrect
                ? Colors.green
                : (isAnswered && isSelected && !isCorrect)
                    ? Colors.red
                    : null,
          ),
        ),
      ),
    );
  }
}
