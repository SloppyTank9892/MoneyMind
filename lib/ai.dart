import 'dart:async';
import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'services/firestore_service.dart';
import 'models/chat_message.dart';
import 'models/financial_features.dart';
import 'models/user_profile.dart';

class AIChat extends StatefulWidget {
  const AIChat({super.key});
  @override
  _AIChatState createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> {
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  FinancialFeatures? _features;
  UserProfile? _profile;
  bool _apiKeyConfigured = false;
  StreamSubscription<List<ChatMessage>>? _chatHistorySubscription;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _loadData();
    _loadChatHistory();
  }

  void _checkApiKey() {
    // Initialize the service to check if API key is configured
    try {
      // Reset and re-check
      _geminiService.initialize();
      if (mounted) {
        setState(() {
          _apiKeyConfigured = _geminiService.isConfigured;
        });
      }
      
      // Debug: Print API key status (first few chars only for security)
      if (!_apiKeyConfigured) {
        print('API Key Status: Not configured or invalid');
        print('Error: ${_geminiService.errorMessage}');
      } else {
        print('API Key Status: Configured');
      }
    } catch (e) {
      print('Error checking API key: $e');
      if (mounted) {
        setState(() {
          _apiKeyConfigured = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      _features = await _firestoreService.getFinancialFeatures();
      _profile = await _firestoreService.getProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading data: $e');
      // Continue anyway with empty features
      _features = FinancialFeatures.empty();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _loadChatHistory() {
    try {
      _chatHistorySubscription?.cancel();
      _chatHistorySubscription = _firestoreService.getChatHistory(limit: 50).listen(
        (history) {
          if (mounted) {
            setState(() {
              _messages = history;
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              _scrollToBottom();
            });
          }
        },
        onError: (error) {
          print('Error loading chat history: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading chat history: $error'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error setting up chat history stream: $e');
    }
  }

  @override
  void dispose() {
    _chatHistorySubscription?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    // Check if API key is configured before sending
    _checkApiKey(); // Always re-check
    if (!_apiKeyConfigured) {
      final apiKeyErrorMsg = ChatMessage(
        role: 'assistant',
        content: '⚠️ Gemini API Key Not Configured\n\nTo use AI chat, please:\n\n1️⃣ Get your free API key:\n   https://makersuite.google.com/app/apikey\n\n2️⃣ Open: lib/config/api_keys.dart\n\n3️⃣ Replace:\n   YOUR_GEMINI_API_KEY_HERE\n   with your actual key\n\n4️⃣ Hot restart the app (not just reload)',
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(apiKeyErrorMsg);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please configure your Gemini API key first'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Load features if not already loaded
    if (_features == null) {
      _features = await _firestoreService.getFinancialFeatures();
    }

    final userMsg = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      await _firestoreService.saveChatMessage(userMsg);

      // Use empty features if still null
      final features = _features ?? FinancialFeatures.empty();
      
      final response = await _geminiService.getChatResponse(
        userMessage: text,
        features: features,
        profile: _profile,
      );

      final assistantMsg = ChatMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
      });

      await _firestoreService.saveChatMessage(assistantMsg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Extract the actual error message
      String errorMessage;
      final errorString = e.toString();
      print('AI Chat Error: $errorString'); // Debug log
      
      // Check for API key errors first (most common)
      if (errorString.contains('Gemini API key not configured') || 
          errorString.contains('API key not configured') ||
          errorString.contains('API key not configured or invalid') ||
          errorString.contains('API_KEY') || 
          errorString.contains('apiKey') ||
          errorString.contains('YOUR_GEMINI_API_KEY_HERE') ||
          errorString.contains('401') ||
          errorString.contains('403') ||
          errorString.contains('INVALID_ARGUMENT') ||
          errorString.contains('invalid API key')) {
        errorMessage = '⚠️ Gemini API Key Not Configured\n\nTo use AI chat, please:\n\n1️⃣ Get your free API key:\n   https://makersuite.google.com/app/apikey\n\n2️⃣ Open: lib/config/api_keys.dart\n\n3️⃣ Replace:\n   YOUR_GEMINI_API_KEY_HERE\n   with your actual key\n\n4️⃣ Hot restart the app (not just reload)';
      } else if (errorString.contains('permission') || errorString.contains('Permission')) {
        errorMessage = 'Error: Permission denied. Please check your Firestore rules.';
      } else if (errorString.contains('Network error') || 
                 errorString.contains('network') || 
                 errorString.contains('connection') || 
                 errorString.contains('timeout') ||
                 errorString.contains('SocketException') ||
                 errorString.contains('HandshakeException')) {
        errorMessage = '🌐 Network Error\n\nPlease check your internet connection and try again.';
      } else if (errorString.contains('rate limit') || 
                 errorString.contains('429') ||
                 errorString.contains('RESOURCE_EXHAUSTED')) {
        errorMessage = '⏱️ Rate Limit Exceeded\n\nYou\'ve made too many requests. Please wait a few moments and try again.';
      } else if (errorString.contains('Model Configuration Error') || 
                 errorString.contains('model') ||
                 errorString.contains('Model')) {
        // Extract the detailed error message
        final match = RegExp(r'Exception:\s*(.+)$', dotAll: true).firstMatch(errorString);
        errorMessage = match != null ? match.group(1)!.trim() : errorString.replaceAll('Exception: ', '').trim();
      } else if (errorString.contains('Exception:')) {
        // Extract message after "Exception: "
        final match = RegExp(r'Exception:\s*(.+)$', dotAll: true).firstMatch(errorString);
        errorMessage = match != null ? match.group(1)!.trim() : errorString;
      } else {
        // Show the actual error for debugging
        errorMessage = errorString.replaceAll('Exception: ', '').replaceAll('Error: ', '').trim();
        if (errorMessage.isEmpty) {
          errorMessage = 'An unknown error occurred. Please try again.';
        }
      }
      
      // Log the full error for debugging
      print('📱 Full error in UI: $errorString');
      
      final errorMsg = ChatMessage(
        role: 'assistant',
        content: errorMessage,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(errorMsg);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.split('\n').first), // Show first line in snackbar
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _generateBudget() async {
    // Load data if not already loaded
    if (_features == null) {
      _features = await _firestoreService.getFinancialFeatures();
    }
    if (_profile == null) {
      _profile = await _firestoreService.getProfile();
    }

    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final features = _features ?? FinancialFeatures.empty();
      final response = await _geminiService.generateBudget(
        features: features,
        profile: _profile!,
      );

      final assistantMsg = ChatMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
      });

      await _firestoreService.saveChatMessage(assistantMsg);
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage = 'Error generating budget.';
      if (e.toString().contains('API_KEY') || e.toString().contains('apiKey')) {
        errorMessage = 'Error: Please configure your Gemini API key in lib/config/api_keys.dart';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MoneyMind AI")),
      body: Column(
        children: [
          // Quick Action Buttons
          if (_messages.isEmpty && _apiKeyConfigured)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _generateBudget,
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Generate Budget'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _sendMessage('Why do I overspend during exams?'),
                    icon: const Icon(Icons.school, size: 18),
                    label: const Text('Exam Spending'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _sendMessage('How can I reduce financial anxiety?'),
                    icon: const Icon(Icons.healing, size: 18),
                    label: const Text('Reduce Anxiety'),
                  ),
                ],
              ),
            ),
          
          // Chat Messages
          Expanded(
            child: !_apiKeyConfigured && _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.vpn_key_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'API Key Not Configured',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'To use the AI chat feature, you need to configure your Gemini API key.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How to set up:',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1. Get your API key from:',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    'https://makersuite.google.com/app/apikey',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '2. Open lib/config/api_keys.dart',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '3. Replace YOUR_GEMINI_API_KEY_HERE with your key',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '4. Restart the app',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ask me anything about your finances',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          
          // Input Field
          if (_apiKeyConfigured)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask a question...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _sendMessage,
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : () => _sendMessage(_inputController.text),
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF6366F1)
              : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          border: isUser ? null : Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.grey[200],
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
