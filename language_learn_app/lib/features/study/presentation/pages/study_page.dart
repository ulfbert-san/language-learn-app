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
              // Counter centered with control icons on the right
              Row(
                children: [
                  // Spacer to balance the buttons on the right
                  const SizedBox(width: 96),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${state.currentPosition} / ${state.totalCards}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref
                          .read(studySessionProvider(widget.lernSetId).notifier)
                          .toggleSwap();
                    },
                    icon: Icon(
                      Icons.swap_horiz,
                      color: state.isSwapped
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Vertauschen',
                  ),
                  IconButton(
                    onPressed: () {
                      ref
                          .read(studySessionProvider(widget.lernSetId).notifier)
                          .shuffleRemaining();
                    },
                    icon: const Icon(Icons.shuffle),
                    tooltip: 'Mischen',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Learning modes grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _LearningModeCard(
                    icon: Icons.quiz,
                    label: 'Multiple Choice',
                    onTap: () {
                      context.pushNamed(
                        'multipleChoice',
                        pathParameters: {
                          'lernSetId': widget.lernSetId.toString()
                        },
                      );
                    },
                  ),
                  _LearningModeCard(
                    icon: Icons.keyboard,
                    label: 'Schreiben',
                    onTap: () {
                      context.pushNamed(
                        'typing',
                        pathParameters: {
                          'lernSetId': widget.lernSetId.toString()
                        },
                      );
                    },
                  ),
                  _LearningModeCard(
                    icon: Icons.link,
                    label: 'Zuordnung',
                    onTap: () {
                      context.pushNamed(
                        'matching',
                        pathParameters: {
                          'lernSetId': widget.lernSetId.toString()
                        },
                      );
                    },
                  ),
                  _LearningModeCard(
                    icon: Icons.inventory_2,
                    label: 'Leitner',
                    onTap: () {
                      context.pushNamed(
                        'spacedRepetition',
                        pathParameters: {
                          'lernSetId': widget.lernSetId.toString()
                        },
                      );
                    },
                  ),
                  _LearningModeCard(
                    icon: Icons.extension,
                    label: 'Wortbau',
                    onTap: () {
                      context.pushNamed(
                        'buildTheWord',
                        pathParameters: {
                          'lernSetId': widget.lernSetId.toString()
                        },
                      );
                    },
                  ),
                  _LearningModeCard(
                    icon: Icons.grid_4x4,
                    label: 'Vokabel Tetris',
                    onTap: () {
                      context.pushNamed(
                        'vocabTetris',
                        pathParameters: {
                          'lernSetId': widget.lernSetId.toString()
                        },
                      );
                    },
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

class _LearningModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LearningModeCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
