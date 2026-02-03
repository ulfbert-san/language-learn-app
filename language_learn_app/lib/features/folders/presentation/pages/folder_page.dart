import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/providers/home_provider.dart';
import '../../../home/presentation/widgets/lernset_card.dart';
import '../../providers/folders_provider.dart';

class FolderPage extends ConsumerWidget {
  final int folderId;

  const FolderPage({super.key, required this.folderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final lernSetsAsync = ref.watch(lernSetsByFolderProvider(folderId));

    final folderName = foldersAsync.whenOrNull(
      data: (folders) =>
          folders.where((f) => f.id == folderId).firstOrNull?.name,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName ?? 'Ordner'),
        automaticallyImplyLeading: false,
      ),
      body: lernSetsAsync.when(
        data: (lernSets) {
          if (lernSets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ordner ist leer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Füge LernSets zu diesem Ordner hinzu',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
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
                  ref.invalidate(lernSetsByFolderProvider(folderId));
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Fehler: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed(
          'createLernset',
          queryParameters: {'folderId': folderId.toString()},
        ),
        tooltip: 'Neues LernSet erstellen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
