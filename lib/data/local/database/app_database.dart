import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import database tables
part 'app_database.g.dart';

/// Expenses table definition
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get remark => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()();
  TextColumn get method => text()();
  TextColumn get description => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Budgets table definition
class Budgets extends Table {
  TextColumn get monthId => text()();
  TextColumn get userId => text()();
  RealColumn get total => real()();
  RealColumn get left => real()();
  TextColumn get categoriesJson => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {monthId, userId};
}

/// Sync queue table for tracking operations that need to be synchronized
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType =>
      text()(); // 'expense', 'budget', or 'user_settings'
  TextColumn get entityId => text()();
  TextColumn get userId => text()();
  TextColumn get operation => text()(); // 'add', 'update', 'delete'
  DateTimeColumn get timestamp => dateTime()();
}

/// Users table for storing user information and settings
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  TextColumn get theme => text().withDefault(const Constant('dark'))();
  BoolColumn get allowNotification =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoBudget => boolean().withDefault(const Constant(false))();
  BoolColumn get improveAccuracy =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Create database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budgie.sqlite'));
    return NativeDatabase(file);
  });
}

/// Main application database
@DriftDatabase(tables: [Expenses, Budgets, SyncQueue, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          // Add new settings columns to Users table
          await m.addColumn(
              users, users.allowNotification as GeneratedColumn<Object>);
          await m.addColumn(users, users.autoBudget as GeneratedColumn<Object>);
          await m.addColumn(
              users, users.improveAccuracy as GeneratedColumn<Object>);
        }
      },
    );
  }
}
