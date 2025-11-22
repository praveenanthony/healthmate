import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../features/health_records/health_entry.dart';

class HealthDatabase {
  static final HealthDatabase instance = HealthDatabase._init();
  static Database? _database;
  HealthDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('healthmate.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE health_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          steps INTEGER NOT NULL,
          calories INTEGER NOT NULL,
          water INTEGER NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
      ''');
    } catch (e) {
      throw Exception('Error creating database: $e');
    }
  }

  Future<HealthEntry> create(HealthEntry entry) async {
    try {
      final db = await instance.database;
      final id = await db.insert('health_records', entry.toMap());
      return entry.copyWith(id: id);
    } catch (e) {
      throw Exception('Error creating entry: $e');
    }
  }

  Future<HealthEntry?> read(int id) async {
    try {
      final db = await instance.database;
      final maps = await db.query('health_records', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) return HealthEntry.fromMap(maps.first);
      return null;
    } catch (e) {
      throw Exception('Error reading entry: $e');
    }
  }

  Future<List<HealthEntry>> readAll() async {
    try {
      final db = await instance.database;
      final result = await db.query('health_records', orderBy: 'date DESC, id DESC');
      return result.map((e) => HealthEntry.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error reading all entries: $e');
    }
  }

  Future<List<HealthEntry>> readByDate(String date) async {
    try {
      final db = await instance.database;
      final result = await db.query('health_records', where: 'date = ?', whereArgs: [date], orderBy: 'id DESC');
      return result.map((e) => HealthEntry.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error reading entries by date: $e');
    }
  }

  Future<List<HealthEntry>> readByDateRange(String startDate, String endDate) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'health_records',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date DESC, id DESC',
      );
      return result.map((e) => HealthEntry.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error reading entries by date range: $e');
    }
  }

  Future<int> update(HealthEntry entry) async {
    try {
      final db = await instance.database;
      return await db.update('health_records', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
    } catch (e) {
      throw Exception('Error updating entry: $e');
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await instance.database;
      return await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Error deleting entry: $e');
    }
  }

  Future<void> deleteByDate(String date) async {
    try {
      final db = await instance.database;
      await db.delete('health_records', where: 'date = ?', whereArgs: [date]);
    } catch (e) {
      throw Exception('Error deleting records by date: $e');
    }
  }

  Future<Map<String, int>> getStepsSummary(String startDate, String endDate) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT SUM(steps) as total_steps, AVG(steps) as avg_steps FROM health_records WHERE date BETWEEN ? AND ?',
        [startDate, endDate],
      );
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'total': (row['total_steps'] as int?) ?? 0,
          'average': ((row['avg_steps'] as double?) ?? 0).toInt(),
        };
      }
      return {'total': 0, 'average': 0};
    } catch (e) {
      throw Exception('Error getting steps summary: $e');
    }
  }

  Future<int> getRecordCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM health_records');
      return (result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0);
    } catch (e) {
      throw Exception('Error getting record count: $e');
    }
  }

  Future<void> close() async {
    try {
      final db = await instance.database;
      await db.close();
    } catch (e) {
      throw Exception('Error closing database: $e');
    }
  }

  /// Get calories summary for a date range
  Future<Map<String, int>> getCaloriesSummary(String startDate, String endDate) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT SUM(calories) as total_cal, AVG(calories) as avg_cal FROM health_records WHERE date BETWEEN ? AND ?',
        [startDate, endDate],
      );
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'total': (row['total_cal'] as int?) ?? 0,
          'average': ((row['avg_cal'] as double?) ?? 0).toInt(),
        };
      }
      return {'total': 0, 'average': 0};
    } catch (e) {
      throw Exception('Error getting calories summary: $e');
    }
  }

  /// Get water intake summary for a date range
  Future<Map<String, int>> getWaterSummary(String startDate, String endDate) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT SUM(water) as total_water, AVG(water) as avg_water FROM health_records WHERE date BETWEEN ? AND ?',
        [startDate, endDate],
      );
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'total': (row['total_water'] as int?) ?? 0,
          'average': ((row['avg_water'] as double?) ?? 0).toInt(),
        };
      }
      return {'total': 0, 'average': 0};
    } catch (e) {
      throw Exception('Error getting water summary: $e');
    }
  }

  /// Get all statistics (steps, calories, water) for a date range
  Future<Map<String, Map<String, int>>> getAllStats(String startDate, String endDate) async {
    try {
      final steps = await getStepsSummary(startDate, endDate);
      final calories = await getCaloriesSummary(startDate, endDate);
      final water = await getWaterSummary(startDate, endDate);

      return {
        'steps': steps,
        'calories': calories,
        'water': water,
      };
    } catch (e) {
      throw Exception('Error getting all stats: $e');
    }
  }

  /// Get max values for all metrics in a date range
  Future<Map<String, int>> getMaxValues(String startDate, String endDate) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT MAX(steps) as max_steps, MAX(calories) as max_cal, MAX(water) as max_water FROM health_records WHERE date BETWEEN ? AND ?',
        [startDate, endDate],
      );
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'steps': (row['max_steps'] as int?) ?? 0,
          'calories': (row['max_cal'] as int?) ?? 0,
          'water': (row['max_water'] as int?) ?? 0,
        };
      }
      return {'steps': 0, 'calories': 0, 'water': 0};
    } catch (e) {
      throw Exception('Error getting max values: $e');
    }
  }

  /// Get daily stats for a specific date
  Future<Map<String, dynamic>> getDailyStats(String date) async {
    try {
      final entries = await readByDate(date);
      int totalSteps = 0;
      int totalCalories = 0;
      int totalWater = 0;

      for (final entry in entries) {
        totalSteps += entry.steps;
        totalCalories += entry.calories;
        totalWater += entry.water;
      }

      return {
        'date': date,
        'steps': totalSteps,
        'calories': totalCalories,
        'water': totalWater,
        'entries': entries.length,
      };
    } catch (e) {
      throw Exception('Error getting daily stats: $e');
    }
  }

  /// Get weekly stats (last 7 days)
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 6));

      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);

      final stats = await getAllStats(startStr, endStr);
      final entries = await readByDateRange(startStr, endStr);

      return {
        'period': 'weekly',
        'startDate': startStr,
        'endDate': endStr,
        'totalEntries': entries.length,
        'stats': stats,
      };
    } catch (e) {
      throw Exception('Error getting weekly stats: $e');
    }
  }

  /// Get monthly stats (last 30 days)
  Future<Map<String, dynamic>> getMonthlyStats() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 29));

      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);

      final stats = await getAllStats(startStr, endStr);
      final entries = await readByDateRange(startStr, endStr);

      return {
        'period': 'monthly',
        'startDate': startStr,
        'endDate': endStr,
        'totalEntries': entries.length,
        'stats': stats,
      };
    } catch (e) {
      throw Exception('Error getting monthly stats: $e');
    }
  }

  /// Bulk insert multiple entries
  Future<List<int>> bulkInsert(List<HealthEntry> entries) async {
    try {
      final db = await instance.database;
      final ids = <int>[];

      for (final entry in entries) {
        final id = await db.insert('health_records', entry.toMap());
        ids.add(id);
      }

      return ids;
    } catch (e) {
      throw Exception('Error bulk inserting entries: $e');
    }
  }

  /// Bulk update multiple entries
  Future<int> bulkUpdate(List<HealthEntry> entries) async {
    try {
      final db = await instance.database;
      int updated = 0;

      for (final entry in entries) {
        updated += await db.update(
          'health_records',
          entry.toMap(),
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }

      return updated;
    } catch (e) {
      throw Exception('Error bulk updating entries: $e');
    }
  }

  /// Bulk delete by list of IDs
  Future<int> bulkDelete(List<int> ids) async {
    try {
      final db = await instance.database;
      final placeholders = List.filled(ids.length, '?').join(',');

      return await db.rawDelete(
        'DELETE FROM health_records WHERE id IN ($placeholders)',
        ids,
      );
    } catch (e) {
      throw Exception('Error bulk deleting entries: $e');
    }
  }

  /// Check if database is empty
  Future<bool> isEmpty() async {
    try {
      final count = await getRecordCount();
      return count == 0;
    } catch (e) {
      throw Exception('Error checking if database is empty: $e');
    }
  }

  /// Delete all records (clear database)
  Future<void> clearAll() async {
    try {
      final db = await instance.database;
      await db.delete('health_records');
    } catch (e) {
      throw Exception('Error clearing database: $e');
    }
  }

  /// Format DateTime to yyyy-MM-dd string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
