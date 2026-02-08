import 'package:flutter/material.dart';

class FlashcardInputRow extends StatefulWidget {
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
  State<FlashcardInputRow> createState() => _FlashcardInputRowState();
}

class _FlashcardInputRowState extends State<FlashcardInputRow> {
  late final TextEditingController _wordController;
  late final TextEditingController _translationController;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word);
    _translationController = TextEditingController(text: widget.translation);
  }

  @override
  void didUpdateWidget(FlashcardInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word && _wordController.text != widget.word) {
      _wordController.text = widget.word;
    }
    if (oldWidget.translation != widget.translation &&
        _translationController.text != widget.translation) {
      _translationController.text = widget.translation;
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    super.dispose();
  }

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
                  '${widget.index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (widget.canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Karte löschen',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      labelText: 'BEGRIFF',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onWordChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _translationController,
                    decoration: const InputDecoration(
                      labelText: 'DEFINITION',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onTranslationChanged,
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
