import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bazi_app_v2.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            nickname TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE saved_charts (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            request_json TEXT NOT NULL,
            report_json TEXT NOT NULL,
            saved_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES local_users(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static String hashId(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString().substring(0, 16);
  }
}
