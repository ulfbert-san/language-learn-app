import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../providers/home_provider.dart';

class LernSetCard extends ConsumerWidget {
  final LernSet lernSet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(int? folderId)? onAssignToFolder;

  const LernSetCard({
    super.key,
    required this.lernSet,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onAssignToFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardCountAsync = ref.watch(flashcardCountProvider(lernSet.id));

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lernSet.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 8),
                            Text('Löschen'),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),
              if (lernSet.description != null &&
                  lernSet.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lernSet.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.style, size: 16),
                  const SizedBox(width: 4),
                  cardCountAsync.when(
                    data: (count) => Text(
                      '$count Karten',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    loading: () => const Text('...'),
                    error: (_, __) => const Text('?'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LernSet löschen'),
        content: Text(
          'Möchtest du "${lernSet.name}" wirklich löschen? Alle Karteikarten werden ebenfalls gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
