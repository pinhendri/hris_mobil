import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications(
            id TEXT PRIMARY KEY,
            title TEXT,
            message TEXT,
            type TEXT,
            created_at INTEGER,
            is_read INTEGER
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> insertNotification(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'notifications',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markAsRead(String id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await database;
    await db.update('notifications', {'is_read': 1});
  }

  Future<void> clearAllNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }
}
