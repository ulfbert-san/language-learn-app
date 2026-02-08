import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'secure_storage.dart';

class AnthropicService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-3-haiku-20240307';

  final SecureStorageService _secureStorage;

  AnthropicService(this._secureStorage);

  Future<String?> _getApiKey() async {
    return await _secureStorage.getApiKey();
  }

  Future<String> _sendRequest(String systemPrompt, String userMessage) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API-Key nicht konfiguriert. Bitte in Einstellungen hinterlegen.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage}
        ],
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'API-Fehler: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['content'] as List;
    if (content.isNotEmpty) {
      return content[0]['text'] as String;
    }
    throw Exception('Keine Antwort erhalten');
  }

  Future<String> generateExampleSentence(String word, String translation, String sourceLanguage, String targetLanguage) async {
    const systemPrompt = '''Du bist ein Sprachlehrer, der Beispielsätze für Vokabeln generiert.
Generiere einen einfachen, natürlichen Beispielsatz mit dem gegebenen Wort.
Antworte NUR mit dem Beispielsatz, ohne Erklärungen.''';

    final userMessage = '''Generiere einen Beispielsatz auf $sourceLanguage mit dem Wort "$word" (Übersetzung: $translation auf $targetLanguage).
Der Satz sollte einfach und für Sprachlerner geeignet sein.''';

    return await _sendRequest(systemPrompt, userMessage);
  }

  Future<Map<String, String>> generateFillInBlank(String word, String translation, String sourceLanguage, String targetLanguage) async {
    const systemPrompt = '''Du bist ein Sprachlehrer, der Lückentexte für Vokabeln erstellt.
Antworte im folgenden Format (ohne weitere Erklärungen):
SATZ: [Satz mit ___ als Lücke]
LÖSUNG: [Das fehlende Wort]''';

    final userMessage = '''Erstelle einen Lückentext auf $sourceLanguage, bei dem das Wort "$word" (Übersetzung: $translation auf $targetLanguage) fehlt.
Der Satz sollte einfach sein und die Lücke sollte durch ___ markiert werden.''';

    final response = await _sendRequest(systemPrompt, userMessage);

    // Parse response
    final lines = response.split('\n');
    String sentence = '';
    String solution = '';

    for (final line in lines) {
      if (line.startsWith('SATZ:')) {
        sentence = line.substring(5).trim();
      } else if (line.startsWith('LÖSUNG:')) {
        solution = line.substring(7).trim();
      }
    }

    if (sentence.isEmpty) {
      sentence = response.replaceAll(word, '___');
      solution = word;
    }

    return {
      'sentence': sentence,
      'solution': solution.isNotEmpty ? solution : word,
    };
  }

  Future<List<Map<String, String>>> generateConjugations(String verb, String translation) async {
    const systemPrompt = '''Du bist ein Sprachlehrer für Verbkonjugationen.
WICHTIG: Erkenne die Sprache des Verbs und konjugiere es IN DIESER SPRACHE.
Gib NUR die Konjugationstabelle aus, KEINE Einleitung, KEINE Erklärungen.
Format pro Zeile: PERSON: VERBFORM
Verwende die Personalpronomen der Sprache des Verbs.

Beispiel für Türkisch (açmak):
ben: açıyorum
sen: açıyorsun
o: açıyor
biz: açıyoruz
siz: açıyorsunuz
onlar: açıyorlar

Beispiel für Spanisch (hablar):
yo: hablo
tú: hablas
él/ella: habla
nosotros: hablamos
vosotros: habláis
ellos: hablan''';

    final userMessage = '''Konjugiere das Verb "$verb" (bedeutet: $translation) im Präsens.
Erkenne die Sprache des Verbs und verwende die passenden Personalpronomen dieser Sprache.
Gib NUR die Tabelle aus, nichts anderes.''';

    final response = await _sendRequest(systemPrompt, userMessage);

    final conjugations = <Map<String, String>>[];
    final lines = response.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.contains(':') && !trimmed.toLowerCase().startsWith('beispiel')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          final person = parts[0].trim();
          final form = parts.sublist(1).join(':').trim();
          // Filter out empty entries and explanatory text
          if (person.isNotEmpty && form.isNotEmpty && person.length < 20) {
            conjugations.add({
              'person': person,
              'form': form,
            });
          }
        }
      }
    }

    return conjugations;
  }
}

final anthropicServiceProvider = Provider<AnthropicService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AnthropicService(secureStorage);
});
