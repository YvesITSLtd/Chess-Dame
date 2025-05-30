import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

class AIService {
  // Get API key from environment variables
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash-exp';

  // Tracking response source
  String _responseSource = '';
  bool _apiCallFailed = false;
  List<Map<String, String>> _conversationHistory = [];

  // Common greetings patterns for simpler responses
  final List<String> _greetingPatterns = [
    'hi', 'hello', 'hey', 'greetings', 'howdy', 'good morning', 'good afternoon',
    'good evening', 'what\'s up', 'sup', 'yo'
  ];

  // Reset API failure flag to allow retry
  void resetAPIFailureFlag() {
    _apiCallFailed = false;
    developer.log('API failure flag reset - will try API calls again');
  }

  // Validate that API key is available
  bool get hasValidApiKey {
    final apiKey = geminiApiKey;
    return apiKey.isNotEmpty && apiKey != 'your_api_key_here';
  }

  // Initialize with previous conversation if available
  Future<void> loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('conversation_history') ?? [];

      _conversationHistory = history.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return <String, String>{
          'role': decoded['role']?.toString() ?? '',
          'content': decoded['content']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      // Start fresh if there's an error
      _conversationHistory = [];
      developer.log('Error loading conversation history: $e');
    }
  }

  // Save conversation for context
  Future<void> saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = _conversationHistory.map((item) => jsonEncode(item)).toList();

      // Keep only the last 20 messages for context
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }

      await prefs.setStringList('conversation_history', history);
    } catch (e) {
      // Silent fail - just for persistence
      developer.log('Error saving conversation history: $e');
    }
  }

  void clearConversationHistory() {
    _conversationHistory = [];
    saveConversationHistory();
  }

  Future<String> generateRwandaFacts({required String prompt}) async {
    _responseSource = ''; // Reset the source
    developer.log('Starting Gemini API call for prompt: $prompt');

    // Check if API key is available
    if (!hasValidApiKey) {
      developer.log('No valid API key found - using fallback responses');
      _apiCallFailed = true;
      _responseSource = 'FALLBACK';
      
      // Add user message to conversation history
      _conversationHistory.add(<String, String>{
        'role': 'user',
        'content': prompt,
      });
      
      final response = _getPreDefinedResponse(prompt);
      _conversationHistory.add(<String, String>{
        'role': 'assistant',
        'content': response,
      });
      saveConversationHistory();
      return response;
    }

    // Check if this is a simple greeting
    final isGreeting = _greetingPatterns.contains(prompt.toLowerCase().trim());

    // Add user message to conversation history
    _conversationHistory.add(<String, String>{
      'role': 'user',
      'content': prompt,
    });

    // For simple greetings, provide a friendly response
    if (isGreeting) {
      final response = _getGreetingResponse();
      _conversationHistory.add(<String, String>{
        'role': 'assistant',
        'content': response,
      });
      saveConversationHistory();
      return response;
    }

    // Temporarily reset API failure flag to force retry
    if (prompt.toLowerCase().contains('retry api') ||
        prompt.toLowerCase().contains('try again')) {
      resetAPIFailureFlag();
    }

    if (_apiCallFailed) {
      _responseSource = 'FALLBACK';
      developer.log('Using fallback response - previous API calls failed');
      final response = _getPreDefinedResponse(prompt);

      _conversationHistory.add(<String, String>{
        'role': 'assistant',
        'content': response,
      });
      saveConversationHistory();

      return response;
    }

    try {
      // Create a context-aware prompt based on conversation history
      String contextPrompt = _createContextPrompt(prompt);

      final response = await _callGeminiAPI(contextPrompt);
      _responseSource = 'GEMINI';

      developer.log('Gemini API call succeeded');
      // Save this successful API response to shared preferences
      _saveSuccessfulResponse(prompt, response, 'gemini');

      // Add AI response to conversation history
      _conversationHistory.add(<String, String>{
        'role': 'assistant',
        'content': response,
      });
      saveConversationHistory();

      return response;
    } catch (e) {
      // If Gemini API fails, use pre-defined responses
      developer.log('Gemini API failed with error: $e');
      _apiCallFailed = true;
      _responseSource = 'FALLBACK';

      final response = _getPreDefinedResponse(prompt);
      _conversationHistory.add(<String, String>{
        'role': 'assistant',
        'content': response,
      });
      saveConversationHistory();

      return response;
    }
  }

  String _getGreetingResponse() {
    final responses = [
      "Hello! 👋 I'm your Rwanda Guide. How can I help you learn about Rwanda today?",
      "Hi there! I'd be happy to share information about Rwanda with you. What would you like to know?",
      "Greetings! I'm here to answer your questions about Rwanda. Is there something specific you're curious about?",
      "Hello! I'm your Rwanda guide. Ask me anything about Rwanda's culture, wildlife, geography, or history!"
    ];

    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }

  // Create a context-aware prompt based on conversation history
  String _createContextPrompt(String currentPrompt) {
    // If we have enough context, use it to make responses more coherent
    if (_conversationHistory.length > 1) {
      // Get last few exchanges for context (max 4 exchanges = 8 messages)
      final contextSize = _conversationHistory.length > 8 ? 8 : _conversationHistory.length - 1;
      final recentMessages = _conversationHistory.sublist(_conversationHistory.length - 1 - contextSize);

      String contextString = "Previous conversation:\n";
      for (var message in recentMessages) {
        contextString += "${message['role'] == 'user' ? 'User' : 'Guide'}: ${message['content']}\n";
      }

      return '''
$contextString

Given the conversation above, respond to the user's latest message: "$currentPrompt"
Your response should:
- Be friendly and conversational, like a helpful guide
- Provide accurate information about Rwanda
- Stay on topic with the conversation
- Use markdown formatting for better readability
- Be direct and concise, yet informative and educational
''';
    } else {
      // Initial prompt with no context
      return 'Provide interesting and factual information about Rwanda related to the following: $currentPrompt. ' +
          'Format your response in a friendly, engaging tone. Include historical context where relevant. ' +
          'Focus on being accurate, educational and interesting. Use markdown formatting.';
    }
  }

  // Method to test the Gemini API directly
  Future<String> testGeminiAPI(String prompt) async {
    developer.log('Testing Gemini API with prompt: $prompt');
    return _callGeminiAPI(prompt);
  }

  // Call Gemini API
  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey'
    );

    final Map<String, dynamic> requestBody = {
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 800,
      }
    };

    developer.log('Sending request to Gemini API: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      developer.log('Response status code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        developer.log('Response body preview: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log('Successful response from Gemini');

        // Extract text from Gemini response structure
        if (responseData != null &&
            responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {

          final part = responseData['candidates'][0]['content']['parts'][0];
          return part['text'] ?? part['textAsHtml'] ?? 'No text found in response';
        }

        return 'Could not parse response: ${response.body}';
      } else {
        developer.log('API error response: ${response.body}');
        throw Exception('Failed to generate content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error during API call: $e');
      throw Exception('API connection error: $e');
    }
  }

  // Save successful responses to use as examples
  Future<void> _saveSuccessfulResponse(String prompt, String response, String source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final responses = prefs.getStringList('ai_responses') ?? [];

      final responseData = jsonEncode({
        'prompt': prompt,
        'response': response,
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only the last 10 successful responses
      responses.add(responseData);
      if (responses.length > 10) {
        responses.removeAt(0);
      }

      await prefs.setStringList('ai_responses', responses);
    } catch (e) {
      // Silently fail - this is just for debug purposes
      developer.log('Failed to save response: $e');
    }
  }

  // Check what provided the response
  String getResponseSource() {
    return _responseSource;
  }

  // Provide pre-defined responses for common questions about Rwanda
  String _getPreDefinedResponse(String prompt) {
    final normalizedPrompt = prompt.toLowerCase();

    if (normalizedPrompt.contains('language') || normalizedPrompt.contains('speak')) {
      return '''
## Languages in Rwanda

The official languages of Rwanda are:

1. **Kinyarwanda** - Spoken by virtually the entire population
2. **English** - Added as an official language in 2008
3. **French** - Historically used in education and administration
4. **Swahili** - Used in business and trade, particularly in urban areas

Kinyarwanda is the primary language of daily communication for most Rwandans. After the 1994 genocide, there was a shift from French to English in government and education, reflecting stronger ties with East African neighbors and the Commonwealth.

---
*Note: This is a pre-defined response (API calls unsuccessful)*
''';
    } else if (normalizedPrompt.contains('animal') || normalizedPrompt.contains('wildlife')) {
      return '''
## Wildlife in Rwanda

Rwanda is home to impressive wildlife, including:

1. **Mountain Gorillas** - About one-third of the world's remaining mountain gorilla population lives in Rwanda's Volcanoes National Park.

2. **Golden Monkeys** - These beautiful endangered primates can be found in the bamboo forests of Volcanoes National Park.

3. **Big Five Animals** - Akagera National Park hosts elephants, lions (reintroduced in 2015), leopards, buffalo, and rhinos (reintroduced in 2017).

4. **Chimpanzees and Other Primates** - Nyungwe Forest National Park is home to 13 primate species, including chimpanzees and colobus monkeys.

5. **Birds** - Rwanda boasts over 700 bird species, with Nyungwe Forest and Akagera being popular birdwatching destinations.

---
*Note: This is a pre-defined response (API calls unsuccessful)*
''';
    } else if (normalizedPrompt.contains('food') || normalizedPrompt.contains('cuisine')) {
      return '''
## Rwandan Cuisine

Traditional Rwandan cuisine includes:

1. **Ugali** - A stiff porridge made from maize flour, often served as a staple with stews.

2. **Matoke** - Cooked plantains mashed or served in a savory sauce.

3. **Isombe** - A dish made from cassava leaves, similar to spinach, often cooked with onions, aubergines, and served with meat.

4. **Brochettes** - Grilled meat skewers, usually beef or goat, popular street food.

5. **Urwagwa** - Traditional banana beer made from fermented bananas.

6. **Ikivuguto** - Fermented milk, similar to buttermilk or yogurt.

Rwandan cuisine emphasizes fresh ingredients and simple preparation methods, with influences from surrounding African nations.

---
*Note: This is a pre-defined response (API calls unsuccessful)*
''';
    } else if (normalizedPrompt.contains('history') || normalizedPrompt.contains('genocide')) {
      return '''
## Rwandan History

Rwanda has a rich and complex history:

1. **Pre-colonial Period** - Rwanda was a unified kingdom ruled by the mwami (king) with a complex social structure.

2. **Colonial Era** - First colonized by Germany (1897-1916), then Belgium (1916-1962), which implemented divisive policies that intensified existing social hierarchies.

3. **Independence** - Rwanda gained independence on July 1, 1962.

4. **1994 Genocide** - Between April and July 1994, an estimated 800,000 to 1 million Tutsis and moderate Hutus were killed in one of the most devastating genocides in modern history.

5. **Recovery and Reconciliation** - Under President Paul Kagame's leadership, Rwanda has focused on national unity, economic development, and reconciliation. The country has made remarkable progress in rebuilding its infrastructure, economy, and social fabric.

6. **Modern Rwanda** - Today, Rwanda is known for its stability, economic growth, environmental policies, gender equality in governance, and technological advancement.

---
*Note: This is a pre-defined response (API calls unsuccessful)*
''';
    } else if (normalizedPrompt.contains('tourist') || normalizedPrompt.contains('attraction') || normalizedPrompt.contains('visit')) {
      return '''
## Top Tourist Attractions in Rwanda

Rwanda offers many incredible destinations for visitors:

1. **Volcanoes National Park** - Home to the endangered mountain gorillas and golden monkeys. Gorilla trekking is the country's top tourist activity.

2. **Nyungwe Forest National Park** - One of Africa's oldest rainforests with 13 primate species, hundreds of bird species, and a spectacular canopy walkway.

3. **Akagera National Park** - Rwanda's only savanna park, home to the Big Five and over 500 bird species.

4. **Kigali Genocide Memorial** - An important educational site commemorating the victims of the 1994 genocide.

5. **Lake Kivu** - One of Africa's Great Lakes, offering beautiful beaches, islands, and water activities.

6. **Ethnographic Museum** - Located in Huye, it houses one of Africa's finest ethnographic collections.

7. **Nyanza Royal Palace** - The traditional seat of Rwanda's monarchy with reconstructed traditional king's houses.

Rwanda's tourism infrastructure has developed rapidly in recent years, with luxury lodges and excellent guides available throughout the country.

---
*Note: This is a pre-defined response (API calls unsuccessful)*
''';
    } else {
      return '''
## About Rwanda

Rwanda is known as "The Land of a Thousand Hills" due to its beautiful mountainous terrain. It's located in East-Central Africa and is one of the smallest countries on the continent.

Key facts:
- **Capital**: Kigali, one of the cleanest cities in Africa
- **Population**: Approximately 13 million people
- **Geography**: Features mountains, volcanoes, and numerous lakes
- **Famous for**: Mountain gorillas, clean cities, and remarkable post-conflict recovery
- **Economy**: Coffee and tea are major exports, with tourism growing rapidly

Rwanda has made remarkable progress since the 1994 genocide, becoming one of the most stable and progressive nations in Africa. The country emphasizes environmental protection, with plastic bags banned since 2008 and a nationwide community service program called "Umuganda" held monthly.

For more specific information about Rwanda, please try a more focused question.

---
*Note: This is a pre-defined response (API calls unsuccessful)*
''';
    }
  }
}
