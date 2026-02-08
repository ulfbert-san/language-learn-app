import 'package:drift/drift.dart';

import 'lernsets_table.dart';

class Flashcards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lernSetId => integer().references(LernSets, #id)();
  TextColumn get word => text().withLength(min: 1, max: 500)();
  TextColumn get translation => text().withLength(min: 1, max: 500)();
  IntColumn get position => integer()();
  // Spaced Repetition (Leitner System)
  IntColumn get boxLevel => integer().withDefault(const Constant(1))();
  DateTimeColumn get nextReview => dateTime().nullable()();
}
