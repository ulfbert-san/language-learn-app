import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/typing_provider.dart';

class TypingPage extends ConsumerStatefulWidget {
  final int lernSetId;

  const TypingPage({super.key, required this.lernSetId});

  @override
  ConsumerState<TypingPage> createState() => _TypingPageState();
}

class _TypingPageState extends ConsumerState<TypingPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(typingProvider(widget.lernSetId));

    ref.listen<TypingState>(typingProvider(widget.lernSetId), (previous, next) {
      if (previous?.currentIndex != next.currentIndex && !next.isFinished) {
        _controller.clear();
        _focusNode.requestFocus();
      }
    });

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
      return _buildResultScreen(context, state);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.lernSetName ?? 'Schreiben'),
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
                  const SizedBox(height: 32),
                  // Word to translate
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Übersetze:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.currentCard?.word ?? '',
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
                  // Input field
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    enabled: !state.isAnswered,
                    decoration: InputDecoration(
                      labelText: 'Deine Übersetzung',
                      border: const OutlineInputBorder(),
                      suffixIcon: state.isAnswered
                          ? Icon(
                              state.isCorrect ? Icons.check_circle : Icons.cancel,
                              color: state.isCorrect ? Colors.green : Colors.red,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      ref.read(typingProvider(widget.lernSetId).notifier).updateInput(value);
                    },
                    onSubmitted: (_) {
                      if (!state.isAnswered) {
                        ref.read(typingProvider(widget.lernSetId).notifier).submitAnswer();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Feedback
                  if (state.isAnswered) ...[
                    Container(
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
                              'Richtige Antwort: ${state.currentCard?.translation}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Score
                  Text(
                    'Punktzahl: ${state.score} / ${state.currentNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      if (!state.isAnswered)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(typingProvider(widget.lernSetId).notifier).submitAnswer();
                            },
                            child: const Text('Prüfen'),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(typingProvider(widget.lernSetId).notifier).nextCard();
                            },
                            child: const Text('Weiter'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context, TypingState state) {
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
                      ref.read(typingProvider(widget.lernSetId).notifier).restart();
                      _controller.clear();
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
