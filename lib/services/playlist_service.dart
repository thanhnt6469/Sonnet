import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'spotify_service.dart';
import '../models/music_tags.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();
  
  final SpotifyService _spotifyService = SpotifyService();

  Future<List<Map<String, String>>> generatePlaylist(
    String selectedMood,
    Set<String> selectedGenres, {
    Set<String>? selectedTags,
  }) async {
    try {
      // Get API token from .env file using flutter_dotenv
      String apiToken = '';
      
      try {
        // Get token from dotenv
        apiToken = dotenv.env['token'] ?? '';
        
        if (apiToken.isNotEmpty && apiToken != 'your_actual_api_key_here') {
          print('✅ Found token from .env: ${apiToken.substring(0, 10)}...');
        } else {
          print('⚠️ Token not found or is placeholder');
        }
      } catch (e) {
        print('❌ Error reading .env file: $e');
      }
      
      // Debug: print token info
      print('API Token length: ${apiToken.length}');
      if (apiToken.isNotEmpty) {
        print('API Token starts with: ${apiToken.substring(0, 10)}...');
        print('API Token ends with: ...${apiToken.substring(apiToken.length - 10)}');
      }
      print('API Token contains quotes: ${apiToken.contains("'") || apiToken.contains('"')}');
      
      if (apiToken.isEmpty || apiToken == 'your_actual_api_key_here') {
        throw Exception('''OpenAI API token not configured. 

Please create a .env file in the project root with your OpenAI API token:

token=your_real_openai_api_key_here

Steps to fix:
1. Run create_env.bat (Windows) or create_env.sh (Mac/Linux) to create the .env file
2. Edit the .env file and replace 'your_actual_api_key_here' with your real OpenAI API token
3. Restart the Flutter app

You can get an OpenAI API key from: https://platform.openai.com/api-keys

Alternatively, you can manually create a .env file in the project root with:
token=your_real_openai_api_key_here''');
      }

      // Construct the prompt text using the selected mood and genres
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final randomSeed = (currentTime % 1000).toString();
      
      // Build advanced criteria from tags
      String advancedCriteria = '';
      if (selectedTags != null && selectedTags.isNotEmpty) {
        final languages = selectedTags.where((tag) => tag.startsWith('lang_')).toList();
        final tempos = selectedTags.where((tag) => tag.startsWith('tempo_')).toList();
        final energy = selectedTags.where((tag) => tag.startsWith('energy_')).toList();
        final eras = selectedTags.where((tag) => tag.startsWith('era_')).toList();
        final activities = selectedTags.where((tag) => tag.startsWith('activity_')).toList();
        final instruments = selectedTags.where((tag) => tag.startsWith('instrument_')).toList();

                 if (languages.isNotEmpty) {
           advancedCriteria += 'Languages: ${languages.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}\n';
         }
         if (tempos.isNotEmpty) {
           advancedCriteria += 'Tempo: ${tempos.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}\n';
         }
         if (energy.isNotEmpty) {
           advancedCriteria += 'Energy: ${energy.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}\n';
         }
         if (eras.isNotEmpty) {
           advancedCriteria += 'Era: ${eras.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}\n';
         }
         if (activities.isNotEmpty) {
           advancedCriteria += 'Activity: ${activities.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}\n';
         }
         if (instruments.isNotEmpty) {
           advancedCriteria += 'Instruments: ${instruments.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}\n';
         }
      }

      final promptText = '''Create a music playlist based on the following criteria:
Mood: $selectedMood
Genres: ${selectedGenres.join(', ')}
${advancedCriteria.isNotEmpty ? 'Advanced Criteria:\n$advancedCriteria' : ''}

CRITICAL REQUIREMENTS:
- Provide exactly 10 songs in "Artist Name - Song Title" format
- One song per line, no numbering
- Use ONLY real, existing songs and artists
- NEVER use placeholder values like "Unknown Artist", "Unknown Title", "Sample", "Example", etc.
- Each song must have a real artist name and real song title
- Focus on popular, well-known songs that actually exist
- Include diverse artists and different eras
- If Vietnamese genres are selected, prioritize real Vietnamese artists and songs
- Consider the advanced criteria when selecting songs

FORMAT REQUIREMENTS:
- Use exactly: "Artist Name - Song Title"
- No quotes, no extra formatting
- No parentheses unless part of the actual song title
- No special characters except what's in the actual song title

VALIDATION RULES:
- Every artist must be a real, existing artist
- Every song title must be a real, existing song
- No generic terms like "Artist", "Title", "Song", "Track"
- No placeholder or example values
- Minimum 2 characters for both artist and title

Example of CORRECT format:
Alicia Keys - Fallin'
Usher - Burn
Toni Braxton - Un-Break My Heart
Ed Sheeran - Shape of You
Drake - God's Plan

Example of INCORRECT format (DO NOT USE):
Unknown Artist - Unknown Title
Artist - Title
Sample Song - Example Artist
Placeholder - Generic

Random seed: $randomSeed
Current time: $currentTime

Please provide exactly 10 real songs in the correct format.''';

      // API call to get playlist recommendations
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: jsonEncode(
          {
            "model": "gpt-4o-mini",
            "messages": [
              {"role": "system", "content": promptText},
            ],
            'max_tokens': 250,
            'temperature': 0.8, // Tăng randomness
            "top_p": 0.9, // Giảm để tăng đa dạng
          },
        ),
      );

      // Print response for debugging
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final choices = data['choices'] as List;
        final playlistString =
            choices.isNotEmpty ? choices[0]['message']['content'] as String : '';

        // Parse the playlist string with multiple format support
        final songs = <Map<String, String>>[];
        
        for (final line in playlistString.split('\n')) {
          if (line.trim().isEmpty) continue;
          
          // Remove numbering (1., 2., etc.)
          String cleanSong = line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
          
          // Skip if empty after cleaning
          if (cleanSong.isEmpty) continue;
          
          // Debug: print the song being parsed
          print('Parsing song: "$cleanSong"');
          
          // Try different parsing patterns
          Map<String, String>? result = _parseSongLine(cleanSong);
          
          // Only add valid songs
          if (result != null) {
            songs.add(result);
            print('✅ Parsed: Artist="${result['artist']}", Title="${result['title']}"');
          } else {
            print('❌ Skipped invalid song: "$cleanSong"');
          }
        }
        
        // Ensure we have exactly 10 songs, remove duplicates
        final uniqueSongs = <String, Map<String, String>>{};
        for (final song in songs) {
          final key = '${song['artist']} - ${song['title']}';
          uniqueSongs[key] = song;
        }
        
        final finalSongs = uniqueSongs.values.take(10).toList();
        print('Final playlist has ${finalSongs.length} songs');
        
        // If we don't have enough songs, try again with a more specific prompt
        if (finalSongs.length < 5) {
          print('⚠️ Not enough valid songs generated (${finalSongs.length}/10). Retrying with stricter prompt...');
          
          // Retry with a more specific prompt
          final retryPromptText = '''Create a music playlist based on the following criteria:
Mood: $selectedMood
Genres: ${selectedGenres.join(', ')}

STRICT REQUIREMENTS - READ CAREFULLY:
- Provide exactly 10 songs in "Artist Name - Song Title" format
- Use ONLY real, existing, popular songs
- NO placeholder values, NO examples, NO generic terms
- Every artist and song must be real and well-known
- Format: "Artist Name - Song Title" (exactly like this)

VALID EXAMPLES:
Ed Sheeran - Shape of You
Drake - God's Plan
Ariana Grande - Thank U, Next
Post Malone - Rockstar
Billie Eilish - Bad Guy

INVALID EXAMPLES (NEVER USE):
Unknown Artist - Unknown Title
Artist - Title
Sample - Example
Placeholder - Generic

Random seed: ${DateTime.now().millisecondsSinceEpoch}
Current time: ${DateTime.now().millisecondsSinceEpoch}

Provide exactly 10 real songs:''';

          final retryResponse = await http.post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiToken',
            },
            body: jsonEncode({
              "model": "gpt-4o-mini",
              "messages": [
                {"role": "system", "content": retryPromptText},
              ],
              'max_tokens': 300,
              'temperature': 0.7,
              "top_p": 0.9,
            }),
          );

          if (retryResponse.statusCode == 200) {
            final retryData = json.decode(retryResponse.body);
            final retryChoices = retryData['choices'] as List;
            final retryPlaylistString = retryChoices.isNotEmpty ? retryChoices[0]['message']['content'] as String : '';
            final retrySongs = <Map<String, String>>[];
            for (final line in retryPlaylistString.split('\n')) {
              if (line.trim().isEmpty) continue;
              String cleanSong = line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
              if (cleanSong.isEmpty) continue;
              
              Map<String, String>? result = _parseSongLine(cleanSong);
              if (result != null) {
                retrySongs.add(result);
                print('🔄 Retry parsed: Artist="${result['artist']}", Title="${result['title']}"');
              }
            }

            final retryUniqueSongs = <String, Map<String, String>>{};
            for (final song in retrySongs) {
              final key = '${song['artist']} - ${song['title']}';
              retryUniqueSongs[key] = song;
            }

            final retryFinalSongs = retryUniqueSongs.values.take(10).toList();
            print('🔄 Retry final playlist has ${retryFinalSongs.length} songs');

            if (retryFinalSongs.length >= 5) {
              return retryFinalSongs;
            }
          }
          
          throw Exception('Unable to generate enough valid songs after retry. Please try again.');
        }
        
        return finalSongs;
      } else {
        // Handle API errors
        final errorData = json.decode(response.body);
        String errorMessage = 'No songs found';
        
        if (errorData['error'] != null) {
          final error = errorData['error'];
          final errorType = error['type'] as String?;
          final errorMsg = error['message'] as String?;
          
          if (errorType == 'insufficient_quota') {
            errorMessage = 'API quota exceeded';
          } else if (errorType == 'invalid_api_key') {
            errorMessage = 'Invalid API key';
          } else if (errorType == 'rate_limit_exceeded') {
            errorMessage = 'Rate limit exceeded';
          } else if (errorMsg != null) {
            errorMessage = 'API Error: $errorMsg';
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Create Spotify playlist from generated recommendations
  Future<Map<String, dynamic>?> createSpotifyPlaylist({
    required String mood,
    required Set<String> genres,
    required List<Map<String, String>> songs,
    Set<String>? tags,
  }) async {
    try {
      // Check if Spotify is authenticated
      if (!_spotifyService.isAuthenticated) {
        throw Exception('Spotify not authenticated. Please connect your account first.');
      }
      
      // Generate playlist name and description
      final playlistName = _generatePlaylistName(mood, genres, tags);
      final description = _generatePlaylistDescription(mood, genres, tags);
      
      print('🎵 Generated playlist name: "$playlistName"');
      print('📝 Playlist description: "$description"');
      
      // Extract track names and artist names
      final trackNames = songs.map((song) => song['title'] ?? '').toList();
      final artistNames = songs.map((song) => song['artist'] ?? '').toList();
      
      // Create playlist on Spotify
      final result = await _spotifyService.createPlaylistFromRecommendations(
        playlistName: playlistName,
        description: description,
        trackNames: trackNames,
        artistNames: artistNames,
        mood: mood,
        genre: genres.join(', '),
      );
      
      return result;
    } catch (e) {
      print('Error creating Spotify playlist: $e');
      rethrow;
    }
  }
  
  /// Generate consistent playlist name
  String _generatePlaylistName(String mood, Set<String> genres, Set<String>? tags) {
    // Normalize mood: capitalize first letter
    final normalizedMood = mood.isNotEmpty 
        ? '${mood[0].toUpperCase()}${mood.substring(1).toLowerCase()}'
        : mood;
    
    // Normalize genres: capitalize first letter of each genre
    final normalizedGenres = genres.map((genre) {
      return genre.isNotEmpty 
          ? '${genre[0].toUpperCase()}${genre.substring(1).toLowerCase()}'
          : genre;
    }).toList();
    
    // Base name without tags for better matching
    String baseName = 'Sonnet - $normalizedMood Mood (${normalizedGenres.join(', ')})';
    
    // Add tags info if available
    if (tags != null && tags.isNotEmpty) {
      final tagNames = tags.take(3).map((tag) => MusicTags.getTagDisplayName(tag)).join(', ');
      return '$baseName - $tagNames';
    }
    
    return baseName;
  }

  /// Generate playlist description
  String _generatePlaylistDescription(String mood, Set<String> genres, Set<String>? tags) {
    String description = 'AI-generated playlist for $mood mood with ${genres.join(', ')} genres.';
    
    if (tags != null && tags.isNotEmpty) {
      final tagDescriptions = <String>[];
      
      final languages = tags.where((tag) => tag.startsWith('lang_')).toList();
      final tempos = tags.where((tag) => tag.startsWith('tempo_')).toList();
      final energy = tags.where((tag) => tag.startsWith('energy_')).toList();
      final eras = tags.where((tag) => tag.startsWith('era_')).toList();
      final activities = tags.where((tag) => tag.startsWith('activity_')).toList();
      final instruments = tags.where((tag) => tag.startsWith('instrument_')).toList();

      if (languages.isNotEmpty) {
        tagDescriptions.add('Languages: ${languages.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}');
      }
      if (tempos.isNotEmpty) {
        tagDescriptions.add('Tempo: ${tempos.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}');
      }
      if (energy.isNotEmpty) {
        tagDescriptions.add('Energy: ${energy.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}');
      }
      if (eras.isNotEmpty) {
        tagDescriptions.add('Era: ${eras.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}');
      }
      if (activities.isNotEmpty) {
        tagDescriptions.add('Activity: ${activities.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}');
      }
      if (instruments.isNotEmpty) {
        tagDescriptions.add('Instruments: ${instruments.map((tag) => MusicTags.getTagDisplayName(tag)).join(', ')}');
      }
      
      if (tagDescriptions.isNotEmpty) {
        description += ' Features: ${tagDescriptions.join(', ')}.';
      }
    }
    
    description += ' Created by Sonnet app.';
    return description;
  }
  
  /// Check if Spotify is connected
  bool get isSpotifyConnected => _spotifyService.isAuthenticated;
  
  /// Get Spotify service instance
  SpotifyService get spotifyService => _spotifyService;
  
  /// Parse a single song line with comprehensive validation
  Map<String, String>? _parseSongLine(String cleanSong) {
    // List of invalid/placeholder values to reject
    final invalidValues = [
      'unknown artist', 'unknown title', 'unknown', 'n/a', 'na', 
      'tbd', 'to be determined', 'placeholder', 'sample', 'example',
      'artist', 'title', 'song', 'track', 'music', 'audio', 'test',
      'demo', 'example song', 'sample track', 'generic', 'placeholder'
    ];
    
    // Helper function to validate artist/title
    bool isValidValue(String value) {
      final normalized = value.toLowerCase().trim();
      if (normalized.isEmpty) return false;
      if (normalized.length < 2) return false; // Too short
      if (invalidValues.contains(normalized)) return false;
      if (normalized.contains('unknown')) return false;
      if (normalized.contains('placeholder')) return false;
      if (normalized.contains('example')) return false;
      if (normalized.contains('sample')) return false;
      return true;
    }
    
    // Pattern 1: "Artist - Title" (most common format)
    if (cleanSong.contains(' - ')) {
      List<String> parts = cleanSong.split(' - ');
      if (parts.length >= 2) {
        String artist = parts[0].trim();
        String title = parts[1].trim();
        
        // Remove any extra spaces or special characters
        artist = artist.replaceAll(RegExp(r'\s+'), ' ').trim();
        title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        // Validate both artist and title
        if (isValidValue(artist) && isValidValue(title)) {
          return {'artist': artist, 'title': title};
        }
      }
    }
    
    // Pattern 2: "Artist, "Title"" (quoted format)
    RegExp pattern1 = RegExp(r'^(.+?),\s*"([^"]+)"$');
    Match? match1 = pattern1.firstMatch(cleanSong);
    if (match1 != null) {
      String artist = match1.group(1)!.trim();
      String title = match1.group(2)!.trim();
      if (isValidValue(artist) && isValidValue(title)) {
        return {'artist': artist, 'title': title};
      }
    }
    
    // Pattern 3: "Artist: Title"
    if (cleanSong.contains(': ')) {
      List<String> parts = cleanSong.split(': ');
      if (parts.length >= 2) {
        String artist = parts[0].trim();
        String title = parts[1].trim();
        if (isValidValue(artist) && isValidValue(title)) {
          return {'artist': artist, 'title': title};
        }
      }
    }
    
    // Pattern 4: "Artist, Title" (comma separated)
    if (cleanSong.contains(',')) {
      List<String> parts = cleanSong.split(',');
      if (parts.length >= 2) {
        String artist = parts[0].trim();
        String title = parts[1].trim();
        if (isValidValue(artist) && isValidValue(title)) {
          return {'artist': artist, 'title': title};
        }
      }
    }
    
    // Pattern 5: "Artist - Title (feat. Someone)" or "Artist - Title [Remix]"
    RegExp pattern2 = RegExp(r'^(.+?)\s*[-:]\s*(.+?)(?:\s*\([^)]*\)|\s*\[[^\]]*\])*$');
    Match? match2 = pattern2.firstMatch(cleanSong);
    if (match2 != null) {
      String artist = match2.group(1)!.trim();
      String title = match2.group(2)!.trim();
      if (isValidValue(artist) && isValidValue(title)) {
        return {'artist': artist, 'title': title};
      }
    }
    
    // Pattern 6: "Artist ft. Someone - Title" or "Artist feat. Someone - Title"
    RegExp pattern3 = RegExp(r'^(.+?)\s+(?:ft\.|feat\.|featuring)\s+.+?\s*[-:]\s*(.+)$');
    Match? match3 = pattern3.firstMatch(cleanSong);
    if (match3 != null) {
      String artist = match3.group(1)!.trim();
      String title = match3.group(2)!.trim();
      if (isValidValue(artist) && isValidValue(title)) {
        return {'artist': artist, 'title': title};
      }
    }
    
    // If no pattern matches, return null
    return null;
  }
}