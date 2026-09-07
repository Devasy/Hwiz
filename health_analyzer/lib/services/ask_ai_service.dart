import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import 'gemini_api_client.dart';
import 'model_info_service.dart';
import 'sql_query_service.dart';

/// Service orchestrating Ask AI assistant queries using direct Gemini API and SqlQueryService
class AskAiService {
  final SqlQueryService _sqlQueryService = SqlQueryService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const Map<String, dynamic> runSqlQueryTool = {
    'functionDeclarations': [
      {
        'name': 'run_sql_query',
        'description':
            'Run a read-only SQL SELECT query against the health database to answer questions about blood tests, profiles, parameters, trends, and abnormal values.\n'
            'Database schema:\n'
            '- profiles(id INTEGER, name TEXT, date_of_birth TEXT, gender TEXT, created_at TEXT)\n'
            '- reports(id INTEGER, profile_id INTEGER, test_date TEXT, lab_name TEXT, ai_analysis TEXT, created_at TEXT)\n'
            '- blood_parameters(id INTEGER, report_id INTEGER, parameter_name TEXT, parameter_value REAL, unit TEXT, reference_range_min REAL, reference_range_max REAL, raw_parameter_name TEXT)\n'
            'Common queries:\n'
            'Join blood_parameters with reports: "SELECT bp.*, r.test_date FROM blood_parameters bp JOIN reports r ON bp.report_id = r.id WHERE r.profile_id = ? ORDER BY r.test_date DESC"\n'
            'Abnormal parameters: "SELECT bp.*, r.test_date FROM blood_parameters bp JOIN reports r ON bp.report_id = r.id WHERE bp.parameter_value < bp.reference_range_min OR bp.parameter_value > bp.reference_range_max"',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'The SQL SELECT statement to execute.',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of rows to return (default 100, max 200).',
            }
          },
          'required': ['query'],
        }
      }
    ]
  };

  String _buildSystemPrompt({String? activeProfileName, int? activeProfileId}) {
    final profileContext = activeProfileName != null
        ? 'Active patient profile: "$activeProfileName"${activeProfileId != null ? " (ID: $activeProfileId)" : ""}. Focus on this profile unless the user asks about others.'
        : 'There is no single active profile selected; search for profiles in the database as needed.';

    return '''
You are LabLens AI, an expert, empathetic medical laboratory assistant and personal health analyst.
$profileContext

Your goal is to answer user questions about blood test results, trends over time, abnormal parameters, and health insights by querying the local SQLite database.

GUIDELINES:
1. Ground your answers in actual database records using the `run_sql_query` tool whenever the user asks about specific test results, values, dates, or trends.
2. In SQL queries, ALWAYS use clean table aliases and join on:
   - `reports.profile_id = profiles.id`
   - `blood_parameters.report_id = reports.id`
3. Parameter names in `blood_parameters.parameter_name` are normalized (e.g. `fasting_blood_sugar`, `hemoglobin`, `rbc_count`, `serum_cholesterol`, `serum_creatinine`, `platelet_count`, `wbc_count`, `hba1c`, `tsh`, `sgpt`, etc.). Use `LIKE '%term%'` if unsure of the exact normalized name.
4. When abnormal parameters exist (value < ref_min or value > ref_max), clearly mention them with their measured value, unit, and the reference range.
5. Provide helpful, conversational explanations of what the values indicate in everyday terms.
6. Provide dietary and lifestyle recommendations where relevant, but always clarify that this information is educational and not a substitute for clinical medical advice.
''';
  }

  /// Streams reply from AI, invoking SQL tool as needed
  Stream<String> streamReply({
    required String userMessage,
    required List<Map<String, dynamic>> history,
    String? activeProfileName,
    int? activeProfileId,
    void Function(String query)? onToolExecuting,
  }) async* {
    final apiKey = await _secureStorage.read(key: AppConstants.geminiApiKeyStorage);
    if (apiKey == null || apiKey.isEmpty) {
      yield 'Please configure your Gemini API Key in Settings to use Ask AI.';
      return;
    }

    final storedModel = await _secureStorage.read(key: 'selected_gemini_model');
    final model = ModelInfoService().getSanitizedModel(storedModel);

    final systemPrompt = _buildSystemPrompt(
      activeProfileName: activeProfileName,
      activeProfileId: activeProfileId,
    );

    yield* GeminiApiClient.streamChatWithTools(
      apiKey: apiKey,
      initialModel: model,
      userMessage: userMessage,
      systemPrompt: systemPrompt,
      history: history,
      tools: [runSqlQueryTool],
      onToolCall: (name, args) async {
        if (name == 'run_sql_query') {
          final query = (args['query'] as String?) ?? '';
          final limit = (args['limit'] as num?)?.toInt();
          onToolExecuting?.call(query);
          return await _sqlQueryService.runQuery(query, limit: limit);
        }
        return {'error': 'Unknown tool function: $name'};
      },
    );
  }
}
