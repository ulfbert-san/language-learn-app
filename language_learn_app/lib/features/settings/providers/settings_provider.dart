import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _syllableLanguageKey = 'syllable_language';
const String defaultLanguage = 'de';

class SettingsState {
  final String syllableLanguage;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.syllableLanguage = defaultLanguage,
    this.isLoading = true,
    this.error,
  });

  SettingsState copyWith({
    String? syllableLanguage,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      syllableLanguage: syllableLanguage ?? this.syllableLanguage,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString(_syllableLanguageKey) ?? defaultLanguage;
      state = SettingsState(
        syllableLanguage: language,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setSyllableLanguage(String language) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syllableLanguageKey, language);
      state = state.copyWith(
        syllableLanguage: language,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final syllableLanguageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).syllableLanguage;
});
