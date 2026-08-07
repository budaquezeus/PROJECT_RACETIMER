import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'race_timer.db');
    return await openDatabase(
      path,
      version: 2, // Upgrade versi database
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE run_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            time_seconds REAL,
            top_speed REAL,
            date_created TEXT,
            cp1_dist REAL, cp1_time REAL, cp1_speed REAL,
            cp2_dist REAL, cp2_time REAL, cp2_speed REAL,
            cp3_dist REAL, cp3_time REAL, cp3_speed REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS run_records');
          await db.execute('''
            CREATE TABLE run_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT,
              time_seconds REAL,
              top_speed REAL,
              date_created TEXT,
              cp1_dist REAL, cp1_time REAL, cp1_speed REAL,
              cp2_dist REAL, cp2_time REAL, cp2_speed REAL,
              cp3_dist REAL, cp3_time REAL, cp3_speed REAL
            )
          ''');
        }
      },
    );
  }

  Future<int> insertRecord(Map<String, dynamic> record) async {
    final dbClient = await db;
    return await dbClient.insert('run_records', record);
  }

  Future<List<Map<String, dynamic>>> getRecords() async {
    final dbClient = await db;
    return await dbClient.query('run_records', orderBy: 'id DESC');
  }

  Future<int> deleteRecord(int id) async {
    final dbClient = await db;
    return await dbClient.delete('run_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllRecords() async {
    final dbClient = await db;
    return await dbClient.delete('run_records');
  }
}