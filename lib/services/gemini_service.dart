import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/financial_features.dart';
import '../models/user_profile.dart';
import '../config/api_keys.dart';

class GeminiService {
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _currentModelName;

  bool get isConfigured => _isInitialized && _errorMessage == null && _model != null;
  String? get errorMessage => _errorMessage;
  
  // Get the current model name for debugging
  String? get currentModelName => _currentModelName;
  
  /// Test the API key with a simple request
  Future<bool> testApiKey() async {
    try {
      initialize();
      if (_model == null) {
        print('❌ Model is null, cannot test API key');
        return false;
      }
      
      // Make a very simple test request
      final testResponse = await _model!.generateContent([
        Content.text('Say "test" if you can read this.')
      ]);
      
      if (testResponse.text != null && testResponse.text!.isNotEmpty) {
        print('✅ API key test successful! Response: ${testResponse.text}');
        return true;
      } else {
        print('❌ API key test returned empty response');
        return false;
      }
    } catch (e) {
      print('❌ API key test failed: $e');
      return false;
    }
  }

  void initialize() {
    if (_isInitialized && _model != null) return;
    
    _isInitialized = true;
    _errorMessage = null; // Reset error message
    final apiKey = ApiKeys.geminiApiKey;
    
    // Check if API key is configured
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.trim().isEmpty) {
      _errorMessage = 'Gemini API key not configured. Please set it in lib/config/api_keys.dart';
      return;
    }
    
    // Validate API key format (should start with AIzaSy)
    if (!apiKey.startsWith('AIzaSy') || apiKey.length < 30) {
      _errorMessage = 'Invalid API key format. Gemini API keys should start with "AIzaSy" and be at least 30 characters.';
      return;
    }
    
    // Try multiple model names in order of preference
    // Updated for current API - using currently supported models
    // Note: GenerativeModel constructor doesn't throw, so we just create it
    // The actual error will occur when we try to use it
    final modelNames = [
      'gemini-2.5-flash',      // Current fast model (most likely to work)
      'gemini-2.5-pro',         // Current advanced model
      'gemini-2.5-flash-lite',  // Current lite model
      'gemini-1.5-flash-002',   // Versioned flash model
      'gemini-1.5-pro-002',     // Versioned pro model
      'gemini-1.5-flash',       // Standard flash (fallback)
      'gemini-1.5-pro',         // Standard pro (fallback)
    ];
    
    // Just use the first model for now - we'll test it on first use
    final modelName = modelNames[0];
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );
    _currentModelName = modelName;
    print('✅ Initialized Gemini with model: $modelName (will test on first API call)');
    _errorMessage = null;
  }


  Future<String> getChatResponse({
    required String userMessage,
    required FinancialFeatures features,
    UserProfile? profile,
  }) async {
    // Ensure service is initialized
    if (!_isInitialized || _model == null) {
      initialize();
    }
    
    if (_errorMessage != null) {
      throw Exception(_errorMessage!);
    }
    
    if (_model == null) {
      final apiKey = ApiKeys.geminiApiKey;
      if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.trim().isEmpty) {
        throw Exception('Gemini API key not configured. Please set it in lib/config/api_keys.dart');
      }
      throw Exception('Gemini service not initialized. Please check your API key.');
    }

    final context = _buildContext(features, profile);
    final fullPrompt = '''$context

User Question: $userMessage

Provide a compassionate, actionable response that addresses the student's financial mental health. Focus on reducing anxiety and building healthy money habits.''';

    try {
      final response = await _model!.generateContent([Content.text(fullPrompt)]);
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from AI service. Please try again.');
      }
      return response.text!;
    } catch (e, stackTrace) {
      final errorStr = e.toString();
      print('🔴 Gemini API Error Details: $errorStr');
      print('🔴 Stack Trace: $stackTrace');
      
      // Check for API key errors first
      if (errorStr.contains('API_KEY') || 
          errorStr.contains('apiKey') || 
          errorStr.contains('API key') ||
          errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('UNAUTHENTICATED') ||
          errorStr.contains('PERMISSION_DENIED') ||
          errorStr.contains('INVALID_ARGUMENT') ||
          errorStr.contains('invalid API key') ||
          errorStr.contains('API key not valid')) {
        // Try reinitializing with different model
        _isInitialized = false;
        _model = null;
        initialize();
        if (_model != null) {
          // Retry once with new model
          try {
            final retryResponse = await _model!.generateContent([Content.text(fullPrompt)]);
            if (retryResponse.text != null && retryResponse.text!.isNotEmpty) {
              return retryResponse.text!;
            }
          } catch (retryError) {
            print('Retry also failed: $retryError');
          }
        }
        throw Exception('⚠️ Gemini API Key Invalid\n\nYour API key may be incorrect or expired.\n\nPlease:\n1. Check your API key at: https://aistudio.google.com/apikey\n2. Verify it\'s active and has quota\n3. Update lib/config/api_keys.dart\n4. Restart the app');
      }
      
      // Check for rate limits
      if (errorStr.contains('429') || 
          errorStr.contains('RESOURCE_EXHAUSTED') ||
          errorStr.contains('quota') ||
          errorStr.contains('rate limit') ||
          errorStr.contains('QUOTA_EXCEEDED')) {
        throw Exception('⏱️ Rate Limit Exceeded\n\nYou\'ve reached your API quota limit.\n\nPlease:\n1. Wait a few minutes\n2. Check your quota at: https://aistudio.google.com/apikey\n3. Try again later');
      }
      
      // Check for network errors
      if (errorStr.contains('network') || 
          errorStr.contains('connection') || 
          errorStr.contains('timeout') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('HandshakeException') ||
          errorStr.contains('Connection closed') ||
          errorStr.contains('Connection refused') ||
          errorStr.contains('DEADLINE_EXCEEDED')) {
        throw Exception('🌐 Network Error\n\nUnable to connect to AI service.\n\nPlease:\n1. Check your internet connection\n2. Try again in a moment\n3. Check if you can access: https://generativelanguage.googleapis.com');
      }
      
      // Check for model errors - try different models
      if (errorStr.contains('model') || 
          errorStr.contains('Model') ||
          errorStr.contains('NOT_FOUND') ||
          errorStr.contains('not found') ||
          errorStr.contains('is not found for API version') ||
          errorStr.contains('is not supported') ||
          errorStr.contains('INVALID_ARGUMENT') ||
          errorStr.contains('400')) {
        // Try different models - trying currently supported models
        final alternativeModels = [
          'gemini-2.5-flash',      // Current fast model
          'gemini-2.5-pro',         // Current advanced model
          'gemini-2.5-flash-lite',  // Current lite model
          'gemini-1.5-flash-002',   // Versioned flash
          'gemini-1.5-pro-002',     // Versioned pro
          'gemini-1.5-flash',       // Standard flash
          'gemini-1.5-pro',         // Standard pro
        ];
        
        for (final altModel in alternativeModels) {
          if (altModel == _currentModelName) continue; // Skip current model
          
          try {
            print('🔄 Trying alternative model: $altModel');
            _model = GenerativeModel(model: altModel, apiKey: ApiKeys.geminiApiKey);
            _currentModelName = altModel;
            
            final retryResponse = await _model!.generateContent([Content.text(fullPrompt)]);
            if (retryResponse.text != null && retryResponse.text!.isNotEmpty) {
              print('✅ Success with model: $altModel');
              return retryResponse.text!;
            }
          } catch (retryError) {
            print('❌ Model $altModel also failed: $retryError');
            continue;
          }
        }
        
        // If all models failed, show detailed error
        throw Exception('⚠️ Model Configuration Error\n\nError: ${errorStr.length > 200 ? errorStr.substring(0, 200) + "..." : errorStr}\n\nPossible causes:\n1. API key doesn\'t have access to Gemini models\n2. Model name is incorrect for your API version\n3. API key is restricted or expired\n\nPlease:\n1. Check your API key at: https://aistudio.google.com/apikey\n2. Verify the Generative Language API is enabled\n3. Try creating a new API key');
      }
      
      // Show the actual error for debugging
      final cleanError = errorStr
          .replaceAll('Exception: ', '')
          .replaceAll('Error: ', '')
          .replaceAll('PlatformException(', '')
          .replaceAll(')', '')
          .trim();
      
      // Extract more specific error if available
      String userMessage = 'Unable to connect to AI service.';
      if (cleanError.isNotEmpty) {
        userMessage = 'Error: ${cleanError.length > 100 ? cleanError.substring(0, 100) + "..." : cleanError}';
      }
      
      throw Exception('$userMessage\n\nPlease check:\n1. Your API key is valid and active\n2. Your internet connection\n3. Try again in a few moments\n\nIf the problem persists, check the console logs for details.');
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
