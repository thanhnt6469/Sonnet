import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/tflite_prediction.dart';

// ApiPredictionResult moved to tflite_prediction.dart

/// Service for calling Python API instead of local TFLite
class ApiMusicClassificationService {
  static const String _baseUrl = 'http://192.168.207.224:8000'; // Laptop IP address
  static const Duration _timeout = Duration(seconds: 60);

  /// Predict music genre by calling Python API
  /// Giả lập behavior của TFLite local model
  Future<ApiPredictionResult> classifyAudio(String audioFilePath) async {
    try {
      print('DEBUG - Starting API classification for: $audioFilePath');
      
      // Simulate local model loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      print('DEBUG - Uploading file to API server...');
      
      // Determine if this is an original file or converted file
      final fileName = audioFilePath.split('/').last;
      final isOriginal = fileName.contains('recording_') && !fileName.contains('converted_');
      
      // Choose endpoint based on file type
      final endpoint = isOriginal ? '/predict-original' : '/predict';
      print('DEBUG - Using endpoint: $endpoint for file: $fileName');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
      
      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        audioFilePath,
        filename: audioFilePath.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request with timeout
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          print('DEBUG - API prediction successful');
          return ApiPredictionResult.fromJson(jsonData);
        } else {
          throw Exception('API returned error: ${jsonData['detail'] ?? 'Unknown error'}');
        }
      } else {
        String errorMessage;
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['detail'] ?? response.body;
        } catch (e) {
          errorMessage = response.body;
        }
        throw Exception('API request failed (${response.statusCode}): $errorMessage');
      }
      
    } catch (e) {
      print('ERROR - API classification failed: $e');
      rethrow;
    }
  }

  /// Check if API server is available
  Future<bool> isServerAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('DEBUG - Server not available: $e');
      return false;
    }
  }

  /// Get available genres (static list to match API)
  List<String> getAvailableGenres() {
    return [
      'blues', 'classical', 'country', 'disco', 'hiphop', 
      'jazz', 'metal', 'pop', 'reggae', 'rock'
    ];
  }

  /// Get genre description key for localization
  String getGenreDescription(String genre) {
    return 'genre_description_$genre';
  }

  /// Simulate model loading (for UI consistency)
  Future<void> loadModel() async {
    print('DEBUG - Checking API server connection...');
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate loading time
    
    final isAvailable = await isServerAvailable();
    if (!isAvailable) {
      throw Exception('API server is not available. Please start the Python server first.');
    }
    
    print('DEBUG - API connection established successfully');
  }

  /// Cleanup (for consistency with TFLite service)
  void dispose() {
    // Nothing to dispose for API service
    print('DEBUG - API service disposed');
  }
}
