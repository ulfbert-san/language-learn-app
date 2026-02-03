import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/providers/home_provider.dart';
import '../../providers/lernset_provider.dart';
import '../widgets/flashcard_input_row.dart';
import '../widgets/import_dialog.dart';
import '../widgets/export_dialog.dart';

class CreateEditLernSetPage extends ConsumerStatefulWidget {
  final int? lernSetId;
  final int? folderId;

  const CreateEditLernSetPage({
    super.key,
    this.lernSetId,
    this.folderId,
  });

  @override
  ConsumerState<CreateEditLernSetPage> createState() =>
      _CreateEditLernSetPageState();
}

class _CreateEditLernSetPageState extends ConsumerState<CreateEditLernSetPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _initialized = false;

  bool get isEditing => widget.lernSetId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lernSetEditorProvider);

    // Initialize state
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isEditing) {
          ref
              .read(lernSetEditorProvider.notifier)
              .loadLernSet(widget.lernSetId!);
        } else if (widget.folderId != null) {
          ref
              .read(lernSetEditorProvider.notifier)
              .setFolderId(widget.folderId);
        }
      });
    }

    // Sync text controllers with state
    if (_nameController.text != state.name && state.name.isNotEmpty) {
      _nameController.text = state.name;
    }
    if (_descriptionController.text != state.description &&
        state.description.isNotEmpty) {
      _descriptionController.text = state.description;
    }

    if (state.isLoading && isEditing && state.flashcards.length <= 1) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'LernSet bearbeiten' : 'Neues Lernset erstellen'),
        automaticallyImplyLeading: false,
        actions: [
          OutlinedButton(
            onPressed: state.isLoading ? null : () => _save(context, false),
            child: const Text('Erstellen'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: state.isLoading ? null : () => _save(context, true),
            child: const Text('Erstellen und üben'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'Gib deinem LernSet einen Namen',
              ),
              onChanged: (value) {
                ref.read(lernSetEditorProvider.notifier).setName(value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung hinzufügen...',
                hintText: 'Optional: Beschreibe dein LernSet',
              ),
              maxLines: 2,
              onChanged: (value) {
                ref.read(lernSetEditorProvider.notifier).setDescription(value);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showImportDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Importieren'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: state.flashcards.any((c) =>
                          c.word.isNotEmpty && c.translation.isNotEmpty)
                      ? () => _showExportDialog(context, state.flashcards)
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportieren'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.flashcards.length,
              itemBuilder: (context, index) {
                final card = state.flashcards[index];
                return FlashcardInputRow(
                  key: ValueKey('card_$index'),
                  index: index,
                  word: card.word,
                  translation: card.translation,
                  canDelete: state.flashcards.length > 1,
                  onWordChanged: (value) {
                    ref
                        .read(lernSetEditorProvider.notifier)
                        .updateFlashcard(index, word: value);
                  },
                  onTranslationChanged: (value) {
                    ref
                        .read(lernSetEditorProvider.notifier)
                        .updateFlashcard(index, translation: value);
                  },
                  onDelete: () {
                    ref
                        .read(lernSetEditorProvider.notifier)
                        .removeFlashcard(index);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(lernSetEditorProvider.notifier).addFlashcard();
                },
                icon: const Icon(Icons.add),
                label: const Text('Karte hinzufügen'),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: state.isLoading ? null : () => _save(context, false),
                  child: const Text('Erstellen'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: state.isLoading ? null : () => _save(context, true),
                  child: const Text('Erstellen und üben'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final result = await showDialog<List<FlashcardInput>>(
      context: context,
      builder: (context) => const ImportDialog(),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(lernSetEditorProvider.notifier).importFlashcards(result);
    }
  }

  Future<void> _showExportDialog(
      BuildContext context, List<FlashcardInput> cards) async {
    await showDialog(
      context: context,
      builder: (context) => ExportDialog(flashcards: cards),
    );
  }

  Future<void> _save(BuildContext context, bool openStudy) async {
    final notifier = ref.read(lernSetEditorProvider.notifier);
    final lernSetId = await notifier.save(existingId: widget.lernSetId);

    if (lernSetId != null && mounted) {
      ref.invalidate(lernSetsProvider);

      if (openStudy) {
        context.goNamed(
          'study',
          pathParameters: {'lernSetId': lernSetId.toString()},
        );
      } else {
        context.goNamed('home');
      }
    }
  }
}
