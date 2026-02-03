import 'package:flutter/material.dart';

class FlashcardInputRow extends StatelessWidget {
  final int index;
  final String word;
  final String translation;
  final bool canDelete;
  final void Function(String) onWordChanged;
  final void Function(String) onTranslationChanged;
  final VoidCallback onDelete;

  const FlashcardInputRow({
    super.key,
    required this.index,
    required this.word,
    required this.translation,
    required this.canDelete,
    required this.onWordChanged,
    required this.onTranslationChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Karte löschen',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: word,
                    decoration: const InputDecoration(
                      labelText: 'BEGRIFF',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onWordChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: translation,
                    decoration: const InputDecoration(
                      labelText: 'DEFINITION',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onTranslationChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
