import 'dart:io';

import 'api_music_classification_service.dart';
import '../models/tflite_prediction.dart';

class AudioClassificationService {
  final ApiMusicClassificationService _apiService = ApiMusicClassificationService();
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      await _apiService.loadModel();
      _isModelLoaded = true;
      print('Audio classification API connected successfully');
    } catch (e) {
      _isModelLoaded = false;
      print('Error connecting to API: $e');
    }
  }

  // Returns label string on success, or error message prefixed with 'Error:' on failure
  Future<String> classifyAudio(String audioPath) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return 'Error: Audio file not found';
      }

      // API server handles all audio formats directly
      final apiResult = await _apiService.classifyAudio(audioPath);
      return apiResult.predictedGenre;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // Detailed prediction for UI (confidence + scores)
  Future<TflitePrediction> classifyAudioDetailed(String audioPath) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }
    // API server handles all audio formats directly
    final apiResult = await _apiService.classifyAudio(audioPath);
    final labelOrder = _apiService.getAvailableGenres();
    return TflitePrediction.fromApiResult(apiResult, labelOrder);
  }

  List<String> getAvailableGenres() {
    return _apiService.getAvailableGenres();
  }

  Map<String, dynamic> getModelInfo() {
    return {
      'isLoaded': _isModelLoaded,
      'supportedGenres': _apiService.getAvailableGenres().length,
      'modelPath': 'API Server', // Using API instead of local model
      'version': '1.0.0',
    };
  }

  String getGenreDescriptionKey(String genre) {
    return _apiService.getGenreDescription(genre);
  }

  double getConfidenceLevel(String genre) {
    // Use a simple static confidence for now; can be improved by exposing detailed scores
    return 0.85;
  }

  void dispose() {
    _apiService.dispose();
  }
}