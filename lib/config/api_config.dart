import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get groqApiKey {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GROQ_API_KEY not found in .env file');
    }
    return key;
  }
  
  static String get apiUrl => 'https://api.groq.com/openai/v1/chat/completions';
  
  static int get maxTokens => int.tryParse(dotenv.env['MAX_TOKENS'] ?? '400') ?? 400;
  
  static double get temperature => double.tryParse(dotenv.env['TEMPERATURE'] ?? '0.8') ?? 0.8;
  
  static int get timeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;
}