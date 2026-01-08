import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rag_document.dart';

/// RAG Service
///
/// Handles storage and retrieval of RAG documents in Firestore.
///
/// Collection: rag_documents
class RagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rag_documents';

  /// Add a new RAG document to the knowledge base
  Future<void> addDocument({
    required String source,
    required String className,
    required String content,
    Map<String, dynamic>? metadata,
    DateTime? date,
  }) async {
    try {
      final now = DateTime.now();
      final docDate = date ?? now;
      final dateString = "${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}";

      final ragDoc = RagDocument(
        source: source,
        date: dateString,
        className: className,
        content: content,
        metadata: metadata ?? {},
        createdAt: now,
      );

      await _firestore.collection(_collection).add(ragDoc.toMap());
      debugPrint('RAG Document added: $source - $className - $dateString');
    } catch (e) {
      debugPrint('Error adding RAG document: $e');
      rethrow;
    }
  }

  /// Retrieve relevant documents for AI Context
  ///
  /// Returns a list of formatted text strings ready for LLM prompt.
  Future<List<String>> retrieveContext({
    required String className,
    int limit = 50,
  }) async {
    try {
      // Query specific class, ordered by latest first
      final query = await _firestore
          .collection(_collection)
          .where('class', isEqualTo: className)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      final docs = query.docs.map((doc) => RagDocument.fromFirestore(doc)).toList();

      // Convert to context strings
      return docs.map((doc) => doc.toContextString()).toList();
    } catch (e) {
      debugPrint('Error retrieving RAG context: $e');
      // Return empty list on error to not crash the AI flow
      return [];
    }
  }
}
