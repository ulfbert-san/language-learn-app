import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/study_session_provider.dart';
import '../widgets/flip_card.dart';

class StudyPage extends ConsumerStatefulWidget {
  final int lernSetId;

  const StudyPage({super.key, required this.lernSetId});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  double _dragStartX = 0;
  double _dragCurrentX = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studySessionProvider(widget.lernSetId));

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
            onPressed: () => context.goNamed('home'),
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

    if (state.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(state.lernSetName ?? 'Lernen'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed('home'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.style_outlined,
                size: 80,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Karteikarten',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Füge Karteikarten zu diesem LernSet hinzu',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goNamed(
                  'editLernset',
                  pathParameters: {'id': widget.lernSetId.toString()},
                ),
                child: const Text('LernSet bearbeiten'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.lernSetName ?? 'Lernen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.goNamed(
              'editLernset',
              pathParameters: {'id': widget.lernSetId.toString()},
            ),
            tooltip: 'LernSet bearbeiten',
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
          _dragCurrentX = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          _dragCurrentX = details.globalPosition.dx;
        },
        onHorizontalDragEnd: (details) {
          final diff = _dragCurrentX - _dragStartX;
          final notifier =
              ref.read(studySessionProvider(widget.lernSetId).notifier);

          if (diff.abs() > 50) {
            if (diff > 0) {
              // Swipe right - previous card
              notifier.previousCard();
            } else {
              // Swipe left - next card
              notifier.nextCard();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FlipCard(
                    frontText: state.frontText,
                    backText: state.backText,
                    isFlipped: state.isFlipped,
                    onFlip: () {
                      ref
                          .read(studySessionProvider(widget.lernSetId).notifier)
                          .flip();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Card counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.currentIndex > 0
                        ? () {
                            ref
                                .read(studySessionProvider(widget.lernSetId)
                                    .notifier)
                                .previousCard();
                          }
                        : null,
                  ),
                  Text(
                    '${state.currentPosition} / ${state.totalCards}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      ref
                          .read(
                              studySessionProvider(widget.lernSetId).notifier)
                          .nextCard();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(
                              studySessionProvider(widget.lernSetId).notifier)
                          .toggleSwap();
                    },
                    icon: Icon(
                      Icons.swap_horiz,
                      color: state.isSwapped
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    label: Text(
                      'Vertauschen',
                      style: TextStyle(
                        color: state.isSwapped
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(
                              studySessionProvider(widget.lernSetId).notifier)
                          .shuffleRemaining();
                    },
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Mischen'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Hint text
              Text(
                state.isSwapped
                    ? 'Übersetzung wird zuerst gezeigt'
                    : 'Tippe auf die Karte zum Umdrehen, wische zum Navigieren',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
