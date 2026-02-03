import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/home_provider.dart';
import '../widgets/lernset_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lernSetsAsync = ref.watch(lernSetsProvider);

    return Scaffold(
      body: lernSetsAsync.when(
        data: (lernSets) {
          if (lernSets.isEmpty) {
            return Center(
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
                    'Noch keine LernSets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erstelle dein erstes LernSet!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(lernSetsProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: lernSets.length,
              itemBuilder: (context, index) {
                final lernSet = lernSets[index];
                return LernSetCard(
                  lernSet: lernSet,
                  onTap: () => context.goNamed(
                    'study',
                    pathParameters: {'lernSetId': lernSet.id.toString()},
                  ),
                  onEdit: () => context.goNamed(
                    'editLernset',
                    pathParameters: {'id': lernSet.id.toString()},
                  ),
                  onDelete: () async {
                    await ref
                        .read(lernSetsProvider.notifier)
                        .deleteLernSet(lernSet.id);
                  },
                  onAssignToFolder: (folderId) async {
                    await ref
                        .read(lernSetsProvider.notifier)
                        .assignToFolder(lernSet.id, folderId);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(lernSetsProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('createLernset'),
        tooltip: 'Neues LernSet erstellen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
