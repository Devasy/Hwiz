import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SqlValidationException implements Exception {
  SqlValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Executes read-only SQL queries against the local health database.
/// Used by Ask AI to extract and analyze patient data, blood test results, and historical trends.
class SqlQueryService {
  static const _forbiddenKeywords = [
    'INSERT',
    'UPDATE',
    'DELETE',
    'DROP',
    'ALTER',
    'CREATE',
    'ATTACH',
    'DETACH',
    'PRAGMA',
    'VACUUM',
    'REPLACE',
    'TRIGGER',
  ];

  static const _forbiddenIdentifiers = [
    'SQLITE_MASTER',
    'SQLITE_TEMP_MASTER',
    'SQLITE_SCHEMA',
    'SQLITE_TEMP_SCHEMA',
    'SQLITE_DBPAGE',
    'SQLITE_STAT1',
    'SQLITE_STAT2',
    'SQLITE_STAT3',
    'SQLITE_STAT4',
  ];

  String _sanitize(String rawQuery) {
    var q = rawQuery.trim();
    if (q.endsWith(';')) {
      q = q.substring(0, q.length - 1).trim();
    }
    if (q.contains(';')) {
      throw SqlValidationException('Only a single SQL statement is allowed.');
    }
    final upper = q.toUpperCase();
    if (!(upper.startsWith('SELECT') || upper.startsWith('WITH'))) {
      throw SqlValidationException('Only read-only SELECT queries are allowed.');
    }
    for (final kw in _forbiddenKeywords) {
      if (RegExp('\\b$kw\\b').hasMatch(upper)) {
        throw SqlValidationException('Query contains forbidden keyword: $kw');
      }
    }
    for (final id in _forbiddenIdentifiers) {
      if (RegExp('\\b$id\\b').hasMatch(upper)) {
        throw SqlValidationException('Query references a restricted table: $id');
      }
    }
    if (upper.contains('PRAGMA_')) {
      throw SqlValidationException('Query references restricted PRAGMA functions.');
    }
    return q;
  }

  /// Runs [rawQuery] read-only and returns `{'row_count': int, 'rows': List}`
  /// or `{'error': String}`. Never throws.
  Future<Map<String, dynamic>> runQuery(String rawQuery, {int? limit}) async {
    final cappedLimit = (limit ?? 100).clamp(1, 200);

    final String safeQuery;
    try {
      safeQuery = _sanitize(rawQuery);
    } on SqlValidationException catch (e) {
      return {'error': e.message};
    } catch (e) {
      return {'error': 'Validation error: $e'};
    }

    try {
      final Database db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT * FROM (\n$safeQuery\n) LIMIT ?',
        [cappedLimit],
      );
      return {
        'row_count': rows.length,
        'rows': rows,
      };
    } catch (e) {
      return {'error': 'Query execution failed: $e'};
    }
  }
}
