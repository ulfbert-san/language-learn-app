import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

class FolderRepository {
  final AppDatabase _db;

  FolderRepository(this._db);

  Future<List<Folder>> getAllFolders() => _db.getAllFolders();

  Stream<List<Folder>> watchAllFolders() => _db.watchAllFolders();

  Future<Folder> getFolderById(int id) => _db.getFolderById(id);

  Future<int> createFolder(String name) {
    return _db.insertFolder(FoldersCompanion(
      name: Value(name),
    ));
  }

  Future<bool> updateFolder(Folder folder) => _db.updateFolder(folder);

  Future<int> deleteFolder(int id) => _db.deleteFolder(id);
}

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FolderRepository(db);
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
