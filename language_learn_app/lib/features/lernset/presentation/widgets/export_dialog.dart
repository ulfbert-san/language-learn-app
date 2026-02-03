import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/separators.dart';
import '../../providers/lernset_provider.dart';

class ExportDialog extends StatefulWidget {
  final List<FlashcardInput> flashcards;

  const ExportDialog({super.key, required this.flashcards});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _wordSeparator = Separators.tab;
  String _cardSeparator = Separators.newLine;
  String _customWordSeparator = '';
  String _customCardSeparator = '';
  bool _useCustomWordSeparator = false;
  bool _useCustomCardSeparator = false;
  bool _sortAlphabetically = false;

  String get _effectiveWordSeparator =>
      _useCustomWordSeparator ? _customWordSeparator : _wordSeparator;

  String get _effectiveCardSeparator =>
      _useCustomCardSeparator ? _customCardSeparator : _cardSeparator;

  String _generateExportText() {
    var cards = widget.flashcards
        .where((c) => c.word.isNotEmpty && c.translation.isNotEmpty)
        .toList();

    if (_sortAlphabetically) {
      cards = List.from(cards)
        ..sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    }

    return cards
        .map((c) => '${c.word}$_effectiveWordSeparator${c.translation}')
        .join(_effectiveCardSeparator);
  }

  @override
  Widget build(BuildContext context) {
    final exportText = _generateExportText();

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
                    'Exportieren',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
                          'Zwischen Zeilen',
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
                'Optionen',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  Checkbox(
                    value: _sortAlphabetically,
                    onChanged: (value) => setState(() {
                      _sortAlphabetically = value ?? false;
                    }),
                  ),
                  const Text('Alphabetisch ordnen'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Kopiere den Text unten und füge ihn ein. Er ist schreibgeschützt.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Lernset-Inhalt',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      exportText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: exportText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Text in Zwischenablage kopiert'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Text kopieren'),
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
