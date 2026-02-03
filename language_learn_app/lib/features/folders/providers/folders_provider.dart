import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/folder_repository.dart';

class FoldersNotifier extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() async {
    final repository = ref.watch(folderRepositoryProvider);
    return repository.getAllFolders();
  }

  Future<void> createFolder(String name) async {
    final repository = ref.read(folderRepositoryProvider);
    await repository.createFolder(name);
    ref.invalidateSelf();
  }

  Future<void> renameFolder(int id, String newName) async {
    final repository = ref.read(folderRepositoryProvider);
    final folder = await repository.getFolderById(id);
    final updatedFolder = Folder(
      id: folder.id,
      name: newName,
      createdAt: folder.createdAt,
    );
    await repository.updateFolder(updatedFolder);
    ref.invalidateSelf();
  }

  Future<void> deleteFolder(int id) async {
    final repository = ref.read(folderRepositoryProvider);
    await repository.deleteFolder(id);
    ref.invalidateSelf();
  }
}

final foldersProvider =
    AsyncNotifierProvider<FoldersNotifier, List<Folder>>(FoldersNotifier.new);
