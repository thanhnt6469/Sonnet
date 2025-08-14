/// Data class for prediction results (compatible with both TFLite and API)
class TflitePrediction {
  final int index;
  final double confidence;
  final List<double> weightedScores;
  final List<int> counts;

  TflitePrediction({
    required this.index,
    required this.confidence,
    required this.weightedScores,
    required this.counts,
  });

  /// Create from API result
  factory TflitePrediction.fromApiResult(
    ApiPredictionResult apiResult,
    List<String> labelOrder,
  ) {
    // Find index of predicted genre
    final predictedIndex = labelOrder.indexOf(apiResult.predictedGenre);
    
    // Convert weighted scores to list in label order
    final weightedScoresList = labelOrder
        .map((label) => apiResult.weightedScores[label] ?? 0.0)
        .toList();
    
    // Convert count votes to list in label order
    final countsList = labelOrder
        .map((label) => apiResult.countVotes[label] ?? 0)
        .toList();
    
    return TflitePrediction(
      index: predictedIndex >= 0 ? predictedIndex : 0,
      confidence: apiResult.confidence,
      weightedScores: weightedScoresList,
      counts: countsList,
    );
  }
}

/// Import this for API result
class ApiPredictionResult {
  final String predictedGenre;
  final double confidence;
  final Map<String, double> weightedScores;
  final Map<String, int> countVotes;
  final int chunksProcessed;

  ApiPredictionResult({
    required this.predictedGenre,
    required this.confidence,
    required this.weightedScores,
    required this.countVotes,
    required this.chunksProcessed,
  });

  factory ApiPredictionResult.fromJson(Map<String, dynamic> json) {
    return ApiPredictionResult(
      predictedGenre: json['predicted_genre'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      weightedScores: Map<String, double>.from(
        (json['weighted_scores'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      countVotes: Map<String, int>.from(
        (json['count_votes'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        ),
      ),
      chunksProcessed: json['processing_info']['chunks_processed'] as int,
    );
  }
}
