import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/financial_features.dart';
import '../models/user_profile.dart';
import '../config/api_keys.dart';

class GeminiService {
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _errorMessage;

  bool get isConfigured => _isInitialized && _errorMessage == null;
  String? get errorMessage => _errorMessage;

  void initialize() {
    if (_isInitialized) return;
    
    _isInitialized = true;
    final apiKey = ApiKeys.geminiApiKey;
    
    // Check if API key is configured
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.trim().isEmpty) {
      _errorMessage = 'Gemini API key not configured. Please set it in lib/config/api_keys.dart';
      return;
    }
    
    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );
    } catch (e) {
      _errorMessage = 'Error initializing Gemini service: $e';
    }
  }


  Future<String> getChatResponse({
    required String userMessage,
    required FinancialFeatures features,
    UserProfile? profile,
  }) async {
    initialize();
    
    if (_errorMessage != null) {
      throw Exception(_errorMessage!);
    }
    
    if (_model == null) {
      throw Exception('Gemini service not initialized');
    }

    final context = _buildContext(features, profile);
    final fullPrompt = '''$context

User Question: $userMessage

Provide a compassionate, actionable response that addresses the student's financial mental health. Focus on reducing anxiety and building healthy money habits.''';

    try {
      final response = await _model!.generateContent([Content.text(fullPrompt)]);
      return response.text ?? 'I apologize, but I couldn\'t generate a response. Please try again.';
    } catch (e) {
      final errorStr = e.toString();
      
      if (errorStr.contains('API_KEY') || 
          errorStr.contains('apiKey') || 
          errorStr.contains('API key') ||
          errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('UNAUTHENTICATED') ||
          errorStr.contains('PERMISSION_DENIED')) {
        throw Exception('Gemini API key not configured or invalid. Please set it in lib/config/api_keys.dart');
      }
      if (errorStr.contains('429') || errorStr.contains('RESOURCE_EXHAUSTED')) {
        throw Exception('API rate limit exceeded. Please try again later.');
      }
      if (errorStr.contains('network') || 
          errorStr.contains('connection') || 
          errorStr.contains('timeout') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup')) {
        throw Exception('Network error: Please check your internet connection and try again.');
      }
      // Show the actual error for debugging
      throw Exception('AI Service Error: ${errorStr.replaceAll('Exception: ', '').replaceAll('Error: ', '')}');
    }
  }

  Future<String> generateBudget({
    required FinancialFeatures features,
    required UserProfile profile,
  }) async {
    initialize();
    
    if (_errorMessage != null) {
      throw Exception(_errorMessage!);
    }
    
    if (_model == null) {
      throw Exception('Gemini service not initialized');
    }

    final context = _buildContext(features, profile);
    final prompt = '''$context

You are a financial mental-health AI for college students. Create a budget and advice that reduces anxiety, prevents impulse spending, and fits the student's psychology.

Output the response in the following format:
- Weekly Budget
- High-risk Warning (based on their triggers)
- 3 Personalized Rules
- 1 Emotional Coping Strategy''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate budget at this time.';
    } catch (e) {
      if (e.toString().contains('API_KEY') || e.toString().contains('apiKey')) {
        throw Exception('Gemini API key not configured. Please set it in lib/config/api_keys.dart');
      }
      throw Exception('Error generating budget: ${e.toString()}');
    }
  }

  Future<String> explainSpendingPattern({
    required FinancialFeatures features,
    required String question,
  }) async {
    initialize();
    
    if (_errorMessage != null) {
      throw Exception(_errorMessage!);
    }
    
    if (_model == null) {
      throw Exception('Gemini service not initialized');
    }

    final context = _buildContext(features, null);
    final prompt = '''$context

The student asks: "$question"

Explain their spending patterns from a financial psychology perspective. Help them understand the emotional drivers behind their behavior and provide strategies to improve.''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to analyze spending pattern.';
    } catch (e) {
      if (e.toString().contains('API_KEY') || e.toString().contains('apiKey')) {
        throw Exception('Gemini API key not configured. Please set it in lib/config/api_keys.dart');
      }
      throw Exception('Error analyzing spending: ${e.toString()}');
    }
  }

  String _buildContext(FinancialFeatures features, UserProfile? profile) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are a financial mental-health AI assistant for college students.');
    buffer.writeln('You help students understand their emotional relationship with money.');
    buffer.writeln('');
    buffer.writeln('Current Student Context:');
    buffer.writeln('- Financial Stress Index: ${features.financialStressIndex.toStringAsFixed(1)}/100');
    buffer.writeln('- Risk Level: ${features.riskLevel}');
    buffer.writeln('- Money Personality: ${features.moneyPersonality}');
    
    if (features.triggerTypes.isNotEmpty) {
      buffer.writeln('- Identified Triggers: ${features.triggerTypes.join(", ")}');
    }
    
    if (features.predictedRiskWindow != null) {
      buffer.writeln('- Predicted High-Risk Period: ${features.predictedRiskWindow}');
    }

    if (profile != null) {
      buffer.writeln('');
      buffer.writeln('Student Profile:');
      buffer.writeln('- Income Source: ${profile.incomeSource}');
      buffer.writeln('- Living Situation: ${profile.livingSituation}');
      buffer.writeln('- Monthly Spend Range: ${profile.monthlySpendRange}');
      
      if (profile.stressTriggers.isNotEmpty) {
        buffer.writeln('- Known Stress Triggers: ${profile.stressTriggers.join(", ")}');
      }
      
      if (profile.moneyEmotions.isNotEmpty) {
        buffer.writeln('- Money Emotions: ${profile.moneyEmotions.join(", ")}');
      }
    }

    return buffer.toString();
  }
}
