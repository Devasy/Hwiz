import 'package:flutter_test/flutter_test.dart';
import 'package:lablens/services/sql_query_service.dart';
import 'package:lablens/services/gemini_api_client.dart';

void main() {
  group('SqlQueryService Sanitization', () {
    final sqlService = SqlQueryService();

    test('rejects non-SELECT statements', () async {
      final res = await sqlService.runQuery('INSERT INTO profiles (name) VALUES ("Test")');
      expect(res.containsKey('error'), isTrue);
      expect(res['error'], contains('Only read-only SELECT queries are allowed'));
    });

    test('rejects forbidden keywords inside SELECT', () async {
      final res = await sqlService.runQuery('SELECT * FROM profiles WHERE id IN (DELETE FROM profiles)');
      expect(res.containsKey('error'), isTrue);
      expect(res['error'], contains('forbidden keyword: DELETE'));
    });

    test('rejects DROP statements', () async {
      final res = await sqlService.runQuery('DROP TABLE profiles');
      expect(res.containsKey('error'), isTrue);
    });

    test('rejects multi-statement queries', () async {
      final res = await sqlService.runQuery('SELECT * FROM profiles; DROP TABLE reports');
      expect(res.containsKey('error'), isTrue);
      expect(res['error'], contains('Only a single SQL statement is allowed'));
    });

    test('rejects restricted sqlite tables', () async {
      final res = await sqlService.runQuery('SELECT * FROM sqlite_master');
      expect(res.containsKey('error'), isTrue);
      expect(res['error'], contains('restricted table'));
    });
  });

  group('GeminiApiClient Model & Thinking Levels', () {
    test('default model is gemini-3.5-flash-lite', () {
      expect(kDefaultGeminiModel, equals('gemini-3.5-flash-lite'));
    });

    test('thinking levels logic', () {
      expect(supportedThinkingLevels('gemini-2.5-flash'), isEmpty);
      expect(supportedThinkingLevels('gemini-3.5-flash-lite'), contains('minimal'));
      expect(supportedThinkingLevels('gemini-3.7-flash'), isNot(contains('minimal')));
    });

    test('model fallback chain', () {
      expect(getFallbackModel('gemini-3.7-flash'), equals('gemini-3.6-flash'));
      expect(getFallbackModel('gemini-3.6-flash'), equals('gemini-3.5-flash'));
      expect(getFallbackModel('gemini-3.5-flash'), equals('gemini-3.5-flash-lite'));
      expect(getFallbackModel('gemini-3.5-flash-lite'), equals('gemini-2.5-flash'));
    });
  });
}
