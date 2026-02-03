import 'package:flutter/material.dart';

import '../../../../core/constants/separators.dart';
import '../../providers/lernset_provider.dart';

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _textController = TextEditingController();
  String _wordSeparator = Separators.tab;
  String _cardSeparator = Separators.newLine;
  String _customWordSeparator = '';
  String _customCardSeparator = '';
  bool _useCustomWordSeparator = false;
  bool _useCustomCardSeparator = false;

  String get _effectiveWordSeparator =>
      _useCustomWordSeparator ? _customWordSeparator : _wordSeparator;

  String get _effectiveCardSeparator =>
      _useCustomCardSeparator ? _customCardSeparator : _cardSeparator;

  List<FlashcardInput> _parseInput() {
    final text = _textController.text;
    if (text.isEmpty) return [];

    final wordSep = _effectiveWordSeparator;
    final cardSep = _effectiveCardSeparator;

    if (wordSep.isEmpty || cardSep.isEmpty) return [];

    return text
        .split(cardSep)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split(wordSep);
          if (parts.length >= 2) {
            return FlashcardInput(
              word: parts[0].trim(),
              translation: parts.sublist(1).join(wordSep).trim(),
            );
          }
          return null;
        })
        .whereType<FlashcardInput>()
        .where((c) => c.word.isNotEmpty && c.translation.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsedCards = _parseInput();

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daten importieren',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kopiere deine Daten (aus Word, Excel, Google Docs usw.) und füge sie hier ein.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Wort 1\tDefinition 1\nWort 2\tDefinition 2\nWort 3\tDefinition 3',
                    border: const OutlineInputBorder(),
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zwischen Begriff und Definition',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildRadioOption(
                          'Tab',
                          Separators.tab,
                          _wordSeparator,
                          !_useCustomWordSeparator,
                          (value) => setState(() {
                            _wordSeparator = value;
                            _useCustomWordSeparator = false;
                          }),
                        ),
                        _buildRadioOption(
                          'Komma',
                          Separators.comma,
                          _wordSeparator,
                          !_useCustomWordSeparator,
                          (value) => setState(() {
                            _wordSeparator = value;
                            _useCustomWordSeparator = false;
                          }),
                        ),
                        Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: _useCustomWordSeparator,
                              onChanged: (value) => setState(() {
                                _useCustomWordSeparator = value!;
                              }),
                            ),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Nutzerdefiniert',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) => setState(() {
                                  _customWordSeparator = value;
                                  _useCustomWordSeparator = true;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zwischen Karten',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildRadioOption(
                          'Neue Zeile',
                          Separators.newLine,
                          _cardSeparator,
                          !_useCustomCardSeparator,
                          (value) => setState(() {
                            _cardSeparator = value;
                            _useCustomCardSeparator = false;
                          }),
                        ),
                        _buildRadioOption(
                          'Semikolon',
                          Separators.semicolon,
                          _cardSeparator,
                          !_useCustomCardSeparator,
                          (value) => setState(() {
                            _cardSeparator = value;
                            _useCustomCardSeparator = false;
                          }),
                        ),
                        Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: _useCustomCardSeparator,
                              onChanged: (value) => setState(() {
                                _useCustomCardSeparator = value!;
                              }),
                            ),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Nutzerdefiniert',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) => setState(() {
                                  _customCardSeparator = value;
                                  _useCustomCardSeparator = true;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Vorschau ${parsedCards.length} Karten',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: parsedCards.isEmpty
                    ? const Center(
                        child: Text(
                          'Es gibt keine Inhalte, die in der Vorschau angezeigt werden können.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: parsedCards.length,
                        itemBuilder: (context, index) {
                          final card = parsedCards[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${card.word}\t${card.translation}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Import abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: parsedCards.isEmpty
                        ? null
                        : () => Navigator.pop(context, parsedCards),
                    child: const Text('Importieren'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    String groupValue,
    bool isInGroup,
    void Function(String) onChanged,
  ) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: isInGroup ? groupValue : null,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        Text(label),
      ],
    );
  }
}
