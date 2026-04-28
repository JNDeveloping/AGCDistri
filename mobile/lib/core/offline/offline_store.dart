import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum OfflineQueueStatus { pending, syncing, synced, error, needsReview }

class OfflineQueueItem {
  const OfflineQueueItem({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    required this.status,
    required this.attempts,
    this.errorMessage,
  });

  final int id;
  final String actionType;
  final Map<String, dynamic> payload;
  final String createdAt;
  final OfflineQueueStatus status;
  final int attempts;
  final String? errorMessage;

  factory OfflineQueueItem.fromMap(Map<String, Object?> map) => OfflineQueueItem(
        id: map['id'] as int,
        actionType: map['action_type'] as String,
        payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        createdAt: map['created_at'] as String,
        status: OfflineQueueStatus.values.byName(map['status'] as String),
        attempts: map['attempts'] as int? ?? 0,
        errorMessage: map['error_message'] as String?,
      );
}

class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'agc_offline.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE cache_store (
            cache_key TEXT PRIMARY KEY,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            attempts INTEGER NOT NULL DEFAULT 0,
            error_message TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> saveCache(String key, Map<String, dynamic> payload) async {
    final database = await db;
    await database.insert(
      'cache_store',
      {
        'cache_key': key,
        'json_data': jsonEncode(payload),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> readCache(String key) async {
    final database = await db;
    final rows = await database.query('cache_store', where: 'cache_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['json_data'] as String) as Map<String, dynamic>;
  }

  Future<int> enqueue({required String actionType, required Map<String, dynamic> payload}) async {
    final database = await db;
    return database.insert('offline_queue', {
      'action_type': actionType,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'status': OfflineQueueStatus.pending.name,
      'attempts': 0,
    });
  }

  Future<List<OfflineQueueItem>> listQueue({OfflineQueueStatus? status}) async {
    final database = await db;
    final rows = await database.query(
      'offline_queue',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status.name],
      orderBy: 'id ASC',
    );
    return rows.map(OfflineQueueItem.fromMap).toList();
  }

  Future<Map<OfflineQueueStatus, int>> queueCounts() async {
    final database = await db;
    final rows = await database.rawQuery('SELECT status, COUNT(*) as total FROM offline_queue GROUP BY status');
    final map = {for (final status in OfflineQueueStatus.values) status: 0};
    for (final row in rows) {
      final key = OfflineQueueStatus.values.byName(row['status'] as String);
      map[key] = row['total'] as int? ?? 0;
    }
    return map;
  }

  Future<void> setQueueStatus(int id, OfflineQueueStatus status, {String? errorMessage, bool incrementAttempts = false}) async {
    final database = await db;
    await database.rawUpdate(
      '''
      UPDATE offline_queue
      SET status = ?,
          error_message = ?,
          attempts = attempts + ? 
      WHERE id = ?
      ''',
      [status.name, errorMessage, incrementAttempts ? 1 : 0, id],
    );
  }
}
