import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _notificationsTable = 'notifications';
  static const String _offlineQueueTable = 'offline_queue';
  static const String _attendanceDraftsTable = 'attendance_drafts';
  static const String _appCacheTable = 'app_cache';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'hris_mobile.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createNotificationsTable(db);
        await _createOfflineQueueTable(db);
        await _createAttendanceDraftsTable(db);
        await _createAppCacheTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createOfflineQueueTable(db);
          await _createAttendanceDraftsTable(db);
        }
        if (oldVersion < 3) {
          await _createAppCacheTable(db);
        }
        if (oldVersion < 4) {
          await _ensureOfflineQueueSchema(db);
          await _ensureAttendanceDraftsSchema(db);
        }
      },
      onOpen: (db) async {
        await _createNotificationsTable(db);
        await _createOfflineQueueTable(db);
        await _createAttendanceDraftsTable(db);
        await _createAppCacheTable(db);
        await _ensureOfflineQueueSchema(db);
        await _ensureAttendanceDraftsSchema(db);
      },
    );
  }

  Future<void> _createNotificationsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_notificationsTable(
        id TEXT PRIMARY KEY,
        title TEXT,
        message TEXT,
        type TEXT,
        created_at INTEGER,
        is_read INTEGER
      )
    ''');
  }

  Future<void> _createOfflineQueueTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_offlineQueueTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feature TEXT NOT NULL,
        action TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT NOT NULL,
        employee_uuid TEXT,
        c_code TEXT,
        date TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
  }

  Future<void> _createAttendanceDraftsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_attendanceDraftsTable(
        employee_uuid TEXT NOT NULL,
        date TEXT NOT NULL,
        c_code TEXT NOT NULL DEFAULT '',
        clock_in TEXT,
        clock_out TEXT,
        clock_in_photo TEXT,
        clock_out_photo TEXT,
        clock_in_location TEXT,
        clock_out_location TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (employee_uuid, date, c_code)
      )
    ''');
  }

  Future<void> _createAppCacheTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_appCacheTable(
        cache_key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensureOfflineQueueSchema(Database db) async {
    final columns = await _tableColumns(db, _offlineQueueTable);
    if (columns.isEmpty) {
      await _createOfflineQueueTable(db);
      return;
    }

    if (!columns.contains('c_code')) {
      await db.execute(
        'ALTER TABLE $_offlineQueueTable ADD COLUMN c_code TEXT',
      );
    }
  }

  Future<void> _ensureAttendanceDraftsSchema(Database db) async {
    final columns = await _tableColumns(db, _attendanceDraftsTable);
    if (columns.isEmpty) {
      await _createAttendanceDraftsTable(db);
      return;
    }

    final primaryKeyColumns = await _tablePrimaryKeyColumns(
      db,
      _attendanceDraftsTable,
    );
    final requiresMigration =
        !columns.contains('c_code') ||
        primaryKeyColumns.length != 3 ||
        primaryKeyColumns[0] != 'employee_uuid' ||
        primaryKeyColumns[1] != 'date' ||
        primaryKeyColumns[2] != 'c_code';

    if (!requiresMigration) {
      return;
    }

    const legacyTable = 'attendance_drafts_legacy';
    final legacyHasCompanyCode = columns.contains('c_code');

    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS $legacyTable');
      await txn.execute(
        'ALTER TABLE $_attendanceDraftsTable RENAME TO $legacyTable',
      );
      await _createAttendanceDraftsTable(txn);

      final selectCompanyCode = legacyHasCompanyCode
          ? "COALESCE(c_code, '')"
          : "''";

      await txn.execute('''
        INSERT OR REPLACE INTO $_attendanceDraftsTable (
          employee_uuid,
          date,
          c_code,
          clock_in,
          clock_out,
          clock_in_photo,
          clock_out_photo,
          clock_in_location,
          clock_out_location,
          sync_status,
          updated_at
        )
        SELECT
          employee_uuid,
          date,
          $selectCompanyCode,
          clock_in,
          clock_out,
          clock_in_photo,
          clock_out_photo,
          clock_in_location,
          clock_out_location,
          sync_status,
          updated_at
        FROM $legacyTable
      ''');

      await txn.execute('DROP TABLE IF EXISTS $legacyTable');
    });
  }

  Future<Set<String>> _tableColumns(
    DatabaseExecutor db,
    String tableName,
  ) async {
    if (!await _tableExists(db, tableName)) {
      return <String>{};
    }

    final rows = await db.rawQuery('PRAGMA table_info($tableName)');
    return rows
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  Future<List<String>> _tablePrimaryKeyColumns(
    DatabaseExecutor db,
    String tableName,
  ) async {
    if (!await _tableExists(db, tableName)) {
      return const <String>[];
    }

    final rows = await db.rawQuery('PRAGMA table_info($tableName)');
    final primaryKeyRows = rows
        .map((row) => Map<String, Object?>.from(row))
        .toList();
    primaryKeyRows.sort(
      (a, b) => ((a['pk'] as int?) ?? 0).compareTo(((b['pk'] as int?) ?? 0)),
    );

    return primaryKeyRows
        .where((row) => ((row['pk'] as int?) ?? 0) > 0)
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await database;
    return await db.query(_notificationsTable, orderBy: 'created_at DESC');
  }

  Future<void> insertNotification(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      _notificationsTable,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markAsRead(String id) async {
    final db = await database;
    await db.update(
      _notificationsTable,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await database;
    await db.update(_notificationsTable, {'is_read': 1});
  }

  Future<void> clearAllNotifications() async {
    final db = await database;
    await db.delete(_notificationsTable);
  }

  Future<int> insertOfflineQueueItem(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(_offlineQueueTable, data);
  }

  Future<List<Map<String, dynamic>>> getOfflineQueueItems({
    String? feature,
    String? employeeUuid,
    String? companyCode,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (feature != null) {
      whereClauses.add('feature = ?');
      whereArgs.add(feature);
    }

    if (employeeUuid != null) {
      whereClauses.add('employee_uuid = ?');
      whereArgs.add(employeeUuid);
    }

    if (companyCode != null) {
      whereClauses.add('c_code = ?');
      whereArgs.add(companyCode);
    }

    return db.query(
      _offlineQueueTable,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at ASC',
    );
  }

  Future<int> countOfflineQueueItems({
    String? feature,
    String? employeeUuid,
    String? companyCode,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (feature != null) {
      whereClauses.add('feature = ?');
      whereArgs.add(feature);
    }

    if (employeeUuid != null) {
      whereClauses.add('employee_uuid = ?');
      whereArgs.add(employeeUuid);
    }

    if (companyCode != null) {
      whereClauses.add('c_code = ?');
      whereArgs.add(companyCode);
    }

    final whereSql = whereClauses.isNotEmpty
        ? ' WHERE ${whereClauses.join(' AND ')}'
        : '';
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_offlineQueueTable$whereSql',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateOfflineQueueItem(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(_offlineQueueTable, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOfflineQueueItem(int id) async {
    final db = await database;
    await db.delete(_offlineQueueTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertAttendanceDraft(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      _attendanceDraftsTable,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getAttendanceDraft(
    String employeeUuid,
    String date,
    String companyCode,
  ) async {
    final db = await database;
    final result = await db.query(
      _attendanceDraftsTable,
      where: 'employee_uuid = ? AND date = ? AND c_code = ?',
      whereArgs: [employeeUuid, date, companyCode],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAttendanceDrafts({
    String? employeeUuid,
    String? companyCode,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (employeeUuid != null) {
      whereClauses.add('employee_uuid = ?');
      whereArgs.add(employeeUuid);
    }

    if (companyCode != null) {
      whereClauses.add('c_code = ?');
      whereArgs.add(companyCode);
    }

    return db.query(
      _attendanceDraftsTable,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, updated_at DESC',
    );
  }

  Future<void> deleteAttendanceDraft(
    String employeeUuid,
    String date,
    String companyCode,
  ) async {
    final db = await database;
    await db.delete(
      _attendanceDraftsTable,
      where: 'employee_uuid = ? AND date = ? AND c_code = ?',
      whereArgs: [employeeUuid, date, companyCode],
    );
  }

  Future<void> saveCache(String cacheKey, String value) async {
    final db = await database;
    await db.insert(_appCacheTable, {
      'cache_key': cacheKey,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getCache(String cacheKey) async {
    final db = await database;
    final result = await db.query(
      _appCacheTable,
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['value']?.toString();
  }

  Future<void> deleteCache(String cacheKey) async {
    final db = await database;
    await db.delete(
      _appCacheTable,
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }
}
