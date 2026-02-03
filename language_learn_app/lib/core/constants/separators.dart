class Separators {
  // Separators between word and definition
  static const String tab = '\t';
  static const String comma = ',';

  // Separators between cards
  static const String newLine = '\n';
  static const String semicolon = ';';

  // Display names for UI
  static const Map<String, String> wordSeparatorNames = {
    tab: 'Tab',
    comma: 'Komma',
  };

  static const Map<String, String> cardSeparatorNames = {
    newLine: 'Neue Zeile',
    semicolon: 'Semikolon',
  };
}
