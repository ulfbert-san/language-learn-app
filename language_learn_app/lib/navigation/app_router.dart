import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/folders/presentation/pages/folder_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/lernset/presentation/pages/create_edit_lernset_page.dart';
import '../features/study/presentation/pages/study_page.dart';
import '../features/study/presentation/pages/multiple_choice_page.dart';
import '../features/study/presentation/pages/typing_page.dart';
import '../features/study/presentation/pages/matching_page.dart';
import '../features/study/presentation/pages/spaced_repetition_page.dart';
import '../features/study/presentation/pages/build_the_word_page.dart';
import '../features/study/presentation/pages/vocab_tetris_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'app_drawer.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithDrawer(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/folder/:folderId',
            name: 'folder',
            pageBuilder: (context, state) {
              final folderId = int.parse(state.pathParameters['folderId']!);
              return NoTransitionPage(
                child: FolderPage(folderId: folderId),
              );
            },
          ),
          GoRoute(
            path: '/lernset/create',
            name: 'createLernset',
            pageBuilder: (context, state) {
              final folderId = state.uri.queryParameters['folderId'];
              return NoTransitionPage(
                child: CreateEditLernSetPage(
                  folderId: folderId != null ? int.parse(folderId) : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/lernset/:id/edit',
            name: 'editLernset',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: CreateEditLernSetPage(lernSetId: id),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId',
            name: 'study',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: StudyPage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId/quiz',
            name: 'multipleChoice',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: MultipleChoicePage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId/typing',
            name: 'typing',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: TypingPage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId/matching',
            name: 'matching',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: MatchingPage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId/spaced-repetition',
            name: 'spacedRepetition',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: SpacedRepetitionPage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId/build-word',
            name: 'buildTheWord',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: BuildTheWordPage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/study/:lernSetId/vocab-tetris',
            name: 'vocabTetris',
            pageBuilder: (context, state) {
              final lernSetId = int.parse(state.pathParameters['lernSetId']!);
              return MaterialPage(
                child: VocabTetrisPage(lernSetId: lernSetId),
              );
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: SettingsPage(),
              );
            },
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithDrawer extends StatelessWidget {
  final Widget child;

  const ScaffoldWithDrawer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Learn'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
