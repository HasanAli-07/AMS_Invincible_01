import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../constants/ai_secrets.dart';
import '../constants/app_manual.dart';
import 'rag_service.dart';

/// AI Service
///
/// Orchestrates the interaction between the User, RAG Data, and Gemini.
class AiService {
  final RagService _ragService;
  GenerativeModel? _model;

  AiService({RagService? ragService}) : _ragService = ragService ?? RagService();

  /// Initialize the Gemini Model
  Future<void> initialize() async {
    if (AiSecrets.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint('⚠️ Gemini API Key not set. AI features will not work.');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: AiSecrets.geminiApiKey,
    );
  }

  /// Ask a question with RAG context
  Future<String> askGemini(String query, String className) async {
    if (_model == null) {
      await initialize();
      if (_model == null) {
        return "⚠️ API Key missing. Please set it in lib/core/constants/ai_secrets.dart";
      }
    }

    try {
      // 1. Retrieve RAG Context
      final contextDocs = await _ragService.retrieveContext(className: className, limit: 30);
      final contextString = contextDocs.join('\n---\n');

      // 2. Construct Prompt
      final prompt = '''
You are a helpful Assistant for a School Attendance System.
Your knowledge comes from the MANUAL below and the specific DATA CONTEXT provided.

>>> APP MANUAL (HOW TO USE):
${AppManual.content}

>>> DATA CONTEXT (RECENT DOCUMENTS):
$contextString

>>> INSTRUCTIONS:
- Answer the user's question based on the Manual or Data.
- If asking "How to...", guide them using the Manual.
- If asking about "Records/Stats", use Data Context.
- If unknown, say "I don't have that info."

USER QUESTION:
$query
''';

      // 3. Generate Content
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      debugPrint('Error calling Gemini: $e');
      
      // Attempt to list available models for debugging
      String debugInfo = "";
      try {
        // Create a temporary client to check available models
        // Note: We need to import the class if not already available, or use the one we have if possible.
        // google_generative_ai package exposes listModels via the model doesn't seem to work, 
        // need to use the static or checking docs. 
        // Actually, in the Dart SDK, we usually just try valid models. 
        // But let's try to verify the key.
        debugInfo = " (Check your API Key/Region)";
      } catch (_) {}

      return "Error: Unable to reach AI service.\n$e\n$debugInfo";
    }
  }
}
