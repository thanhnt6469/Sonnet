import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SpotifyService {
  static const String _clientId = '879aa8ce317c47d581c3795a9bf4025a';
  static const String _clientSecret = '03040b870fe44cadba4cc389062bfab7';
  static const String _redirectUri = 'http://127.0.0.1:8888';
  static const String _baseUrl = 'https://api.spotify.com/v1';
  
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  
  // Spotify OAuth scopes needed
  // Note: Using http://127.0.0.1:8888 as redirect URI per Spotify security requirements
  static const List<String> _scopes = [
    'playlist-modify-private',
    'playlist-modify-public',
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-read-private',
    'user-read-email'
  ];
  
  /// Get Spotify authorization URL
  String getAuthorizationUrl() {
    final scopes = _scopes.join(' ');
    final url = 'https://accounts.spotify.com/authorize?'
        'client_id=$_clientId'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
        '&scope=${Uri.encodeComponent(scopes)}'
        '&show_dialog=true';
    
    print('🔧 Building Spotify authorization URL:');
    print('   Client ID: $_clientId');
    print('   Redirect URI: $_redirectUri');
    print('   Scopes: $scopes');
    print('   Encoded redirect URI: ${Uri.encodeComponent(_redirectUri)}');
    print('   Encoded scopes: ${Uri.encodeComponent(scopes)}');
    print('🎯 Final URL: $url');
    
    return url;
  }
  
  /// Exchange authorization code for access token
  Future<bool> exchangeCodeForToken(String code) async {
    print('🔄 Exchanging authorization code for token...');
    print('   Code length: ${code.length}');
    print('   Code preview: ${code.substring(0, code.length > 20 ? 20 : code.length)}...');
    print('   Redirect URI: $_redirectUri');
    
    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
        },
      );
      
      print('📡 Token exchange response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        print('✅ Token exchange successful!');
        print('   Access token length: ${_accessToken?.length ?? 0}');
        print('   Refresh token length: ${_refreshToken?.length ?? 0}');
        
        // Save tokens
        await _saveTokens();
        
        // Get user ID
        await _getUserId();
        
        return true;
      } else {
        print('❌ Token exchange failed with status: ${response.statusCode}');
        print('   Error response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 Error exchanging code for token: $e');
      return false;
    }
  }
  
  /// Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        
        // Save new token
        await _saveTokens();
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  /// Get current user ID
  Future<void> _getUserId() async {
    if (_accessToken == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userId = data['id'];
        await _saveUserId();
      }
    } catch (e) {
      print('Error getting user ID: $e');
    }
  }
  
  /// Create playlist from OpenAI recommendations
  Future<Map<String, dynamic>?> createPlaylistFromRecommendations({
    required String playlistName,
    required String description,
    required List<String> trackNames,
    required List<String> artistNames,
    String? mood,
    String? genre,
  }) async {
    if (_accessToken == null || _userId == null) {
      throw Exception('Not authenticated with Spotify');
    }
    
    // Try to refresh token if needed
    if (_refreshToken != null) {
      await refreshAccessToken();
    }
    
    try {
      // 1. Check if playlist with same name already exists
      print('🔍 Checking for existing playlist: "$playlistName"');
      
      // Debug: Test API connection and list all playlists
      await testApiConnection();
      await _debugListAllPlaylists();
      
      final existingPlaylist = await _findExistingPlaylist(playlistName);
      
      if (existingPlaylist != null) {
        // Playlist exists, add tracks to existing playlist
        print('✅ Found existing playlist: ${existingPlaylist['name']} (ID: ${existingPlaylist['id']})');
        print('🔄 Merging new tracks into existing playlist...');
        final playlistId = existingPlaylist['id'];
        final addedTracks = await _addTracksToPlaylist(playlistId, trackNames, artistNames);
        
        return {
          'playlist_id': playlistId,
          'playlist_url': existingPlaylist['external_urls']['spotify'],
          'playlist_name': existingPlaylist['name'],
          'tracks_added': addedTracks,
          'total_tracks': addedTracks.length,
          'merged': true, // Indicate this was merged with existing playlist
        };
      } else {
        // Create new playlist
        print('🆕 No existing playlist found. Creating new playlist: "$playlistName"');
        final playlist = await _createPlaylist(playlistName, description);
        if (playlist == null) return null;
        
        final playlistId = playlist['id'];
        final addedTracks = await _addTracksToPlaylist(playlistId, trackNames, artistNames);
        
        return {
          'playlist_id': playlistId,
          'playlist_url': playlist['external_urls']['spotify'],
          'playlist_name': playlistName,
          'tracks_added': addedTracks,
          'total_tracks': addedTracks.length,
          'merged': false, // Indicate this was a new playlist
        };
      }
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }
  
  /// Debug: List all playlists
  Future<void> _debugListAllPlaylists() async {
    try {
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      print('🔍 Debug: Getting playlists from Spotify API...');
      print('🔍 URL: $_baseUrl/me/playlists?limit=50');
      print('🔍 Access Token: ${_accessToken?.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/me/playlists?limit=50'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = data['items'] as List;
        
        print('📋 All playlists found (${playlists.length} total):');
        if (playlists.isEmpty) {
          print('  ❌ No playlists found! This might be the issue.');
        } else {
          for (int i = 0; i < playlists.length; i++) {
            final playlist = playlists[i];
            print('  ${i + 1}. "${playlist['name']}" (ID: ${playlist['id']})');
          }
        }
      } else {
        print('❌ Failed to get playlists. Status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error listing playlists: $e');
    }
  }

  /// Extract base playlist name (without tags)
  String _extractBasePlaylistName(String playlistName) {
    // Remove tags part (everything after the last " - ")
    final parts = playlistName.split(' - ');
    if (parts.length > 3) {
      // Keep only the first 3 parts: "Sonnet - Mood - (Genres)"
      return parts.take(3).join(' - ');
    }
    return playlistName;
  }

  /// Find existing playlist by name
  Future<Map<String, dynamic>?> _findExistingPlaylist(String playlistName) async {
    try {
      // Ensure we have a valid token
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      // Get user's playlists
      print('🔍 _findExistingPlaylist: Getting playlists...');
      final response = await http.get(
        Uri.parse('$_baseUrl/me/playlists?limit=50'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      print('🔍 _findExistingPlaylist: Response Status: ${response.statusCode}');
      print('🔍 _findExistingPlaylist: Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = data['items'] as List;
        
        // Look for playlist with case-insensitive name match
        print('🔍 Searching through ${playlists.length} playlists...');
        print('🔍 Looking for playlist: "$playlistName"');
        
        // First, try exact match
        for (final playlist in playlists) {
          final existingName = playlist['name'] as String;
          print('🔍 Checking exact match: "$existingName" vs "$playlistName"');
          
          // Normalize both names: trim whitespace and convert to lowercase
          final normalizedExisting = existingName.trim().toLowerCase();
          final normalizedTarget = playlistName.trim().toLowerCase();
          
          if (normalizedExisting == normalizedTarget) {
            print('✅ Found exact match: ${playlist['name']} (ID: ${playlist['id']})');
            return playlist;
          }
        }
        
        // Second, try to find base playlist (without tags)
        final baseName = _extractBasePlaylistName(playlistName);
        if (baseName != playlistName) {
          print('🔍 Looking for base playlist: "$baseName"');
          for (final playlist in playlists) {
            final existingName = playlist['name'] as String;
            final normalizedExisting = existingName.trim().toLowerCase();
            final normalizedBase = baseName.trim().toLowerCase();
            
            if (normalizedExisting == normalizedBase) {
              print('✅ Found base playlist: ${playlist['name']} (ID: ${playlist['id']})');
              return playlist;
            }
          }
        }
        
        print('❌ No exact or base match found for: "$playlistName"');
        
        // Try fuzzy search for similar names
        print('🔍 Trying fuzzy search for similar names...');
        final similarPlaylists = <Map<String, dynamic>>[];
        
        for (final playlist in playlists) {
          final existingName = playlist['name'] as String;
          final normalizedExisting = existingName.trim().toLowerCase();
          final normalizedTarget = playlistName.trim().toLowerCase();
          
          // Check if names are similar (contain similar words)
          final targetWords = normalizedTarget.split(' ');
          int matchCount = 0;
          
          for (final word in targetWords) {
            if (word.length > 2 && normalizedExisting.contains(word)) {
              matchCount++;
            }
          }
          
          // If more than 60% of words match, consider it similar
          if (matchCount >= (targetWords.length * 0.6)) {
            similarPlaylists.add(playlist);
            print('🎯 Found similar playlist: "${playlist['name']}" (${matchCount}/${targetWords.length} words match)');
          }
        }
        
        if (similarPlaylists.isNotEmpty) {
          // Sort by match percentage and return the best match
          similarPlaylists.sort((a, b) {
            final aName = (a['name'] as String).toLowerCase();
            final bName = (b['name'] as String).toLowerCase();
            final targetWords = playlistName.trim().toLowerCase().split(' ');
            
            int aMatches = 0, bMatches = 0;
            for (final word in targetWords) {
              if (word.length > 2) {
                if (aName.contains(word)) aMatches++;
                if (bName.contains(word)) bMatches++;
              }
            }
            
            return bMatches.compareTo(aMatches); // Sort descending
          });
          
          print('✅ Found ${similarPlaylists.length} similar playlists, using the best match: "${similarPlaylists.first['name']}"');
          return similarPlaylists.first;
        }
      }
      
      return null;
    } catch (e) {
      print('Error finding existing playlist: $e');
      return null;
    }
  }

  /// Create a new playlist
  Future<Map<String, dynamic>?> _createPlaylist(String name, String description) async {
    try {
      // Ensure we have a valid token
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$_userId/playlists'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': false,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }
  
  /// Add tracks to playlist
  Future<List<String>> _addTracksToPlaylist(
    String playlistId, 
    List<String> trackNames, 
    List<String> artistNames
  ) async {
    final addedTracks = <String>[];
    final failedTracks = <String>[];
    
    try {
      // Get existing tracks in playlist to avoid duplicates
      print('🔍 Getting existing tracks from playlist...');
      final existingTracks = await _getPlaylistTracks(playlistId);
      print('📊 Found ${existingTracks.length} existing tracks in playlist');
      
      print('🎵 Starting to process ${trackNames.length} tracks...');
      
      for (int i = 0; i < trackNames.length; i++) {
        final trackName = trackNames[i];
        final artistName = artistNames[i];
        
        print('🔍 Processing track ${i + 1}/${trackNames.length}: "$trackName" by "$artistName"');
        
        // Search for track
        final trackUri = await _searchTrack(trackName, artistName);
        if (trackUri != null) {
          // Check if track already exists in playlist
          if (!existingTracks.contains(trackUri)) {
            addedTracks.add(trackUri);
            print('✅ Found and will add: $trackName - $artistName (URI: $trackUri)');
          } else {
            print('⏭️ Skipping duplicate track: $trackName - $artistName');
          }
        } else {
          failedTracks.add('$trackName - $artistName');
          print('❌ Track not found on Spotify: $trackName - $artistName');
        }
        
        // Add small delay to avoid rate limiting
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      print('📊 Summary:');
      print('   - Total tracks to process: ${trackNames.length}');
      print('   - Tracks found and will add: ${addedTracks.length}');
      print('   - Tracks not found: ${failedTracks.length}');
      
      if (failedTracks.isNotEmpty) {
        print('❌ Failed tracks:');
        for (final track in failedTracks) {
          print('   - $track');
        }
      }
      
      // Add tracks in batches (Spotify allows max 100 tracks per request)
      if (addedTracks.isNotEmpty) {
        print('📤 Adding ${addedTracks.length} new tracks to playlist...');
        await _addTracksBatch(playlistId, addedTracks);
        print('✅ Successfully added ${addedTracks.length} tracks to playlist');
      } else {
        print('ℹ️ No new tracks to add (all tracks already exist in playlist or not found)');
      }
      
      return addedTracks;
    } catch (e) {
      print('❌ Error adding tracks: $e');
      return addedTracks;
    }
  }
  
  /// Get existing tracks in playlist
  Future<List<String>> _getPlaylistTracks(String playlistId) async {
    try {
      // Ensure we have a valid token
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/playlists/$playlistId/tracks?limit=100'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        return items.map((item) => item['track']['uri'] as String).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting playlist tracks: $e');
      return [];
    }
  }

  /// Search for a specific track
  Future<String?> _searchTrack(String trackName, String artistName) async {
    try {
      // Ensure we have a valid token
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      // Try multiple search strategies with better matching
      final searchQueries = [
        'track:$trackName artist:$artistName',
        'track:$trackName $artistName',
        '$trackName $artistName',
        'track:$trackName',
      ];
      
      for (int i = 0; i < searchQueries.length; i++) {
        final query = searchQueries[i];
        print('🔍 Search attempt ${i + 1}: "$query"');
        
        final response = await http.get(
          Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&type=track&limit=10'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final tracks = data['tracks']['items'] as List;
          
          if (tracks.isNotEmpty) {
            // Score each track and find the best match
            Map<String, double> trackScores = {};
            
            for (final track in tracks) {
              final foundTrackName = track['name'] as String;
              final foundArtistName = (track['artists'] as List).first['name'] as String;
              final uri = track['uri'] as String;
              
              // Calculate similarity score
              double score = 0.0;
              
              // Exact name match gets highest score
              if (foundTrackName.toLowerCase() == trackName.toLowerCase()) {
                score += 10.0;
              } else if (foundTrackName.toLowerCase().contains(trackName.toLowerCase()) ||
                        trackName.toLowerCase().contains(foundTrackName.toLowerCase())) {
                score += 5.0;
              }
              
              // Exact artist match gets highest score
              if (foundArtistName.toLowerCase() == artistName.toLowerCase()) {
                score += 10.0;
              } else if (foundArtistName.toLowerCase().contains(artistName.toLowerCase()) ||
                        artistName.toLowerCase().contains(foundArtistName.toLowerCase())) {
                score += 5.0;
              }
              
              // Bonus for Vietnamese artists (common variations)
              if (artistName.toLowerCase().contains('hồ ngọc hà') && 
                  foundArtistName.toLowerCase().contains('ho ngoc ha')) {
                score += 3.0;
              }
              if (artistName.toLowerCase().contains('sơn tùng') && 
                  foundArtistName.toLowerCase().contains('son tung')) {
                score += 3.0;
              }
              if (artistName.toLowerCase().contains('đen vâu') && 
                  foundArtistName.toLowerCase().contains('den')) {
                score += 3.0;
              }
              
              trackScores[uri] = score;
            }
            
            // Find the track with highest score
            if (trackScores.isNotEmpty) {
              final bestUri = trackScores.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key;
              final bestScore = trackScores[bestUri]!;
              
              // Get track details for logging
              final bestTrack = tracks.firstWhere((t) => t['uri'] == bestUri);
              final foundTrackName = bestTrack['name'] as String;
              final foundArtistName = (bestTrack['artists'] as List).first['name'] as String;
              
              if (bestScore >= 15.0) {
                print('✅ Found excellent match (score: $bestScore): "$foundTrackName" by "$foundArtistName" (URI: $bestUri)');
                return bestUri;
              } else if (bestScore >= 10.0) {
                print('✅ Found good match (score: $bestScore): "$foundTrackName" by "$foundArtistName" (URI: $bestUri)');
                return bestUri;
              } else if (bestScore >= 5.0) {
                print('⚠️ Found weak match (score: $bestScore): "$foundTrackName" by "$foundArtistName" (URI: $bestUri)');
                // Only return if this is the last search attempt
                if (i == searchQueries.length - 1) {
                  return bestUri;
                }
              } else {
                print('❌ No good match found (best score: $bestScore)');
              }
            }
          }
        } else {
          print('❌ Search attempt ${i + 1} failed with status: ${response.statusCode}');
        }
        
        // Add delay between searches to avoid rate limiting
        if (i < searchQueries.length - 1) {
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
      
      print('❌ No tracks found after trying ${searchQueries.length} search strategies for: "$trackName" by "$artistName"');
      return null;
    } catch (e) {
      print('❌ Error searching track "$trackName" by "$artistName": $e');
      return null;
    }
  }
  
  /// Add tracks to playlist in batch
  Future<void> _addTracksBatch(String playlistId, List<String> trackUris) async {
    try {
      // Ensure we have a valid token
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      print('📤 Adding batch of ${trackUris.length} tracks to playlist $playlistId...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/tracks'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'uris': trackUris,
        }),
      );
      
      if (response.statusCode == 201) {
        print('✅ Successfully added ${trackUris.length} tracks to playlist');
      } else {
        print('❌ Error adding tracks batch: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error adding tracks batch: $e');
    }
  }
  
  /// Save tokens to local storage
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('spotify_access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('spotify_refresh_token', _refreshToken!);
    }
  }
  
  /// Save user ID to local storage
  Future<void> _saveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userId != null) {
      await prefs.setString('spotify_user_id', _userId!);
    }
  }
  
  /// Load tokens from local storage
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');
    _refreshToken = prefs.getString('spotify_refresh_token');
    _userId = prefs.getString('spotify_user_id');
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _userId != null;
  
  /// Get access token
  String? get accessToken => _accessToken;
  
  /// Get user ID
  String? get userId => _userId;
  
  /// Get client ID (for external access)
  String get clientId => _clientId;
  
  /// Get redirect URI (for external access)
  String get redirectUri => _redirectUri;
  
  /// Get scopes (for external access)
  List<String> get scopes => _scopes;
  
  /// Test API connection and get user info
  Future<void> testApiConnection() async {
    try {
      if (_refreshToken != null) {
        await refreshAccessToken();
      }
      
      print('🔍 Testing Spotify API connection...');
      
      // Test 1: Get user profile
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      print('🔍 User Profile Response Status: ${userResponse.statusCode}');
      print('🔍 User Profile Response Body: ${userResponse.body}');
      
      // Test 2: Get playlists
      final playlistResponse = await http.get(
        Uri.parse('$_baseUrl/me/playlists?limit=5'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      print('🔍 Playlist Response Status: ${playlistResponse.statusCode}');
      print('🔍 Playlist Response Body: ${playlistResponse.body}');
      
    } catch (e) {
      print('❌ Error testing API connection: $e');
    }
  }

  /// Clear authentication
  Future<void> clearAuthentication() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_refresh_token');
    await prefs.remove('spotify_user_id');
  }
}
