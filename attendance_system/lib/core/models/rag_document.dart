import 'package:cloud_firestore/cloud_firestore.dart';

/// RAG Document Model
///
/// Represents a unit of knowledge stored in Firestore for retrieval by AI.
/// Strictly TEXTUAL and METADATA only. No biometric data.
class RagDocument {
  final String? id;
  final String source; // "attendance", "system", "manual"
  final String date; // YYYY-MM-DD
  final String className; // e.g., "CE-5"
  final String content; // The text summary
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  RagDocument({
    this.id,
    required this.source,
    required this.date,
    required this.className,
    required this.content,
    required this.metadata,
    required this.createdAt,
  });

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'date': date,
      'class': className, // Mapped to 'class' in Firestore as requested
      'content': content,
      'metadata': metadata,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore Document
  factory RagDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RagDocument(
      id: doc.id,
      source: data['source'] ?? 'unknown',
      date: data['date'] ?? '',
      className: data['class'] ?? '',
      content: data['content'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create formatted text for LLM Context
  String toContextString() {
    return '''
[Source: $source] [Date: $date] [Class: $className]
Content: $content
Metadata: $metadata
''';
  }
}
