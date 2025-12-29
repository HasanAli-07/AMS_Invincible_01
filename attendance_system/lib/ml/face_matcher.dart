/// Face Matcher using Cosine Similarity
/// 
/// This service handles:
/// - Computing cosine similarity between embeddings
/// - Matching faces against stored database
/// - Threshold-based decision making
/// 
/// Cosine Similarity Formula:
/// similarity = (A · B) / (||A|| * ||B||)
/// 
/// For normalized vectors: similarity = A · B (dot product)

import 'face_models.dart';

class FaceMatcher {
  /// Similarity threshold for face recognition
  /// 
  /// Typical values:
  /// - 0.6: Very lenient (more false positives)
  /// - 0.7: Balanced (recommended)
  /// - 0.8: Strict (fewer false positives, more false negatives)
  /// 
  /// This threshold should be tuned based on:
  /// - Model accuracy
  /// - Use case requirements
  /// - False positive vs false negative tolerance
  static const double _defaultThreshold = 0.70;

  final double threshold;

  FaceMatcher({double? threshold}) : threshold = threshold ?? _defaultThreshold;

  /// Compute cosine similarity between two embeddings
  /// 
  /// Both embeddings should be normalized (L2 normalized)
  /// Returns value between -1.0 and 1.0 (typically 0.0 to 1.0 for faces)
  double cosineSimilarity(FaceEmbedding embedding1, FaceEmbedding embedding2) {
    if (embedding1.dimension != embedding2.dimension) {
      throw Exception(
        'Embedding dimensions mismatch: ${embedding1.dimension} vs ${embedding2.dimension}',
      );
    }

    // Dot product of normalized vectors = cosine similarity
    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.dimension; i++) {
      dotProduct += embedding1.vector[i] * embedding2.vector[i];
    }

    return dotProduct;
  }

  /// Find best match for an embedding in a list of stored faces
  /// 
  /// Returns FaceMatch with highest similarity, or null if no match above threshold
  FaceMatch? findBestMatch(
    FaceEmbedding queryEmbedding,
    List<StoredFace> storedFaces,
  ) {
    if (storedFaces.isEmpty) return null;

    StoredFace? bestMatch;
    double bestSimilarity = -1.0;

    // Compare with all stored faces
    for (final storedFace in storedFaces) {
      final similarity = cosineSimilarity(
        queryEmbedding,
        storedFace.embedding,
      );

      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = storedFace;
      }
    }

    // Check if best match exceeds threshold
    if (bestMatch != null && bestSimilarity >= threshold) {
      return FaceMatch(
        matchedFace: bestMatch,
        similarity: bestSimilarity,
        isMatch: true,
      );
    }

    // Return match even if below threshold (for debugging/logging)
    // But mark as not a match
    if (bestMatch != null) {
      return FaceMatch(
        matchedFace: bestMatch,
        similarity: bestSimilarity,
        isMatch: false,
      );
    }

    return null;
  }

  /// Match multiple faces in a single image
  /// 
  /// Returns list of matches, one per detected face
  List<FaceMatch?> matchMultipleFaces(
    List<FaceEmbedding> queryEmbeddings,
    List<StoredFace> storedFaces,
  ) {
    return queryEmbeddings.map(
      (embedding) => findBestMatch(embedding, storedFaces),
    ).toList();
  }

  /// Check if two embeddings belong to the same person
  /// 
  /// Uses threshold to determine match
  bool isSamePerson(
    FaceEmbedding embedding1,
    FaceEmbedding embedding2,
  ) {
    final similarity = cosineSimilarity(embedding1, embedding2);
    return similarity >= threshold;
  }

  /// Get threshold value
  double getThreshold() => threshold;

  /// Set new threshold (creates new instance with new threshold)
  FaceMatcher withThreshold(double newThreshold) {
    return FaceMatcher(threshold: newThreshold);
  }
}

