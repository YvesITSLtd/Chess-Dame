import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rwandafunfacts/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AIService _aiService = AIService();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _showSuggestions = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load conversation history in AIService
    await _aiService.loadConversationHistory();

    // Load UI messages
    await _loadMessages();

    setState(() {
      _isInitialized = true;
    });

    // Add welcome message if it's the first time
    if (_messages.isEmpty) {
      _addMessage(
        "👋 Hello! I'm your Rwanda guide. Ask me anything about Rwanda's culture, history, wildlife, or attractions!",
        false,
      );
    }
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('chat_messages') ?? [];

      setState(() {
        _messages = messagesJson
            .map((msg) => Message.fromJson(jsonDecode(msg)))
            .toList();
      });
    } catch (e) {
      // If there's an error loading messages, start fresh
      _messages = [];
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();

      await prefs.setStringList('chat_messages', messagesJson);
    } catch (e) {
      // Silent fail - just for persistence
    }
  }

  void _scrollToBottom() {
    // Add a small delay to ensure the list has updated
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

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));

      // Keep only the last 50 messages
      if (_messages.length > 50) {
        _messages.removeAt(0);
      }
    });

    _saveMessages();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    // Add user message
    _addMessage(text, true);
    _messageController.clear();

    try {
      // Log the attempt
      print('Attempting to get AI response for: $text');

      final response = await _aiService.generateRwandaFacts(prompt: text);

      // Check if response is empty
      if (response.isEmpty) {
        print('Received empty response from AI service');
        _addMessage("I received an empty response. Please try again with a different question.", false);
      } else {
        // Add AI response
        print('Successfully received AI response of length: ${response.length}');
        _addMessage(response, false);
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      // Display more specific error message
      _addMessage("Sorry, I couldn't generate a response: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}... Please try again or type 'retry api'.", false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearChat() async {
    setState(() {
      _messages = [];
      _showSuggestions = true;
    });

    _aiService.clearConversationHistory();
    _saveMessages();

    // Add welcome message back
    Future.delayed(const Duration(milliseconds: 300), () {
      _addMessage(
        "👋 Hello! I'm your Rwanda guide. Ask me anything about Rwanda's culture, history, wildlife, or attractions!",
        false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Rwanda Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isEmpty
                ? null
                : () => _showClearChatDialog(context),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages area
            Expanded(
              child: _messages.isEmpty && _showSuggestions
                  ? _buildWelcomeView()
                  : _buildChatView(),
            ),

            // Typing indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Text('Typing', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Message input
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Ask about Rwanda...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (value) => _sendMessage(value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    elevation: 2,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1580287917731-a0e92dd3bf9f',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hello! I\'m your Rwanda Guide',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about Rwanda\'s culture, history, wildlife, tourism spots, or interesting facts!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Try asking:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'What\'s the best time to visit Rwanda?',
      'Tell me about mountain gorillas',
      'What food should I try in Rwanda?',
      'What is the history of Rwanda?',
      'What languages are spoken in Rwanda?',
      'Tell me about Rwandan traditions',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          avatar: const Icon(Icons.chat_outlined, size: 16),
          onPressed: () {
            _sendMessage(suggestion);
          },
        );
      }).toList(),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: isUser
                ? Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.white : null,
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                    selectable: true,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showClearChatDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text('Are you sure you want to clear all chat messages? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                _clearChat();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
