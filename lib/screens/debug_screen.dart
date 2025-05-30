import 'package:flutter/material.dart';
import 'package:rwandafunfacts/services/ai_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final AIService _aiService = AIService();
  final List<String> _log = [];
  bool _isTesting = false;

  void _addLog(String message) {
    setState(() {
      _log.add("[${DateTime.now().toString().split('.').first}] $message");
    });
  }

  Future<void> _testGeminiAPI() async {
    setState(() {
      _isTesting = true;
      _log.clear();
      _log.add("=== Starting Gemini API Test ===");
    });

    try {
      _addLog("Testing Gemini API...");
      try {
        final result = await _aiService.testGeminiAPI('Provide a brief fact about Rwanda.');
        _addLog("✅ SUCCESS with Gemini API");
        _addLog("Response: ${result.substring(0, result.length > 200 ? 200 : result.length)}...");
      } catch (e) {
        _addLog("❌ FAILED with Gemini API: $e");
      }

      _addLog("\n=== Test Complete ===");
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _testGeminiAPI,
              child: _isTesting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Testing API...'),
                    ],
                  )
                : const Text('Test Gemini API'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Log:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.join('\n'),
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
