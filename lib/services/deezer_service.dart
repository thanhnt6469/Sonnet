import 'package:deezer/deezer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_logger.dart';

class DeezerService {
  static DeezerService? _instance;
  static DeezerService get instance => _instance ??= DeezerService._internal();
  
  DeezerService._internal();

  Deezer? _deezer;
  bool _isConnected = false;
  String _arlToken = '';

  bool get isConnected => _isConnected;
  Deezer? get deezer => _deezer;

  Future<void> initialize() async {
    await _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _arlToken = prefs.getString('deezer_arl_token') ?? '';
      DebugLogger.logInfo('Loaded Deezer ARL token: ${_arlToken.isNotEmpty ? 'Present' : 'Not found'}');
    } catch (e) {
      DebugLogger.logError('Error loading Deezer ARL token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deezer_arl_token', token);
      DebugLogger.logInfo('Saved Deezer ARL token');
    } catch (e) {
      DebugLogger.logError('Error saving Deezer ARL token: $e');
    }
  }

  Future<bool> connect(String arlToken) async {
    try {
      DebugLogger.logInfo('Attempting to connect to Deezer...');
      _deezer = await Deezer.create(arl: arlToken);
      
      // Test the connection by trying to get user info
      await _deezer!.getUser('me');
      
      _arlToken = arlToken;
      _isConnected = true;
      
      await _saveToken(arlToken);
      DebugLogger.logSuccess('Successfully connected to Deezer');
      return true;
    } catch (e) {
      DebugLogger.logError('Failed to connect to Deezer: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    _deezer = null;
    _isConnected = false;
    _arlToken = '';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deezer_arl_token');
      DebugLogger.logInfo('Disconnected from Deezer and cleared token');
    } catch (e) {
      DebugLogger.logError('Error clearing Deezer token: $e');
    }
  }

  Future<List<dynamic>> searchTracks(String query) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Searching for tracks: $query');
      final results = await _deezer!.searchTracks(query);
      return results?.data ?? [];
    } catch (e) {
      DebugLogger.logError('Error searching tracks: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getFavoriteSongs() async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Loading favorite songs...');
      final favorites = await _deezer!.favSongs();
      // For now, return empty list as the API structure is unclear
      DebugLogger.logInfo('Favorites response type: ${favorites.runtimeType}');
      return [];
    } catch (e) {
      DebugLogger.logError('Error loading favorites: $e');
      rethrow;
    }
  }

  Future<dynamic> getTrack(String trackId) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Getting track info: $trackId');
      final track = await _deezer!.getTrack(trackId);
      return track;
    } catch (e) {
      DebugLogger.logError('Error getting track: $e');
      rethrow;
    }
  }

  Future<dynamic> downloadTrack(String trackId) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Downloading track: $trackId');
      final song = await _deezer!.getSong(trackId);
      return song;
    } catch (e) {
      DebugLogger.logError('Error downloading track: $e');
      rethrow;
    }
  }

  Future<Stream<List<int>>> streamTrack(String trackId) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Streaming track: $trackId');
      final stream = _deezer!.streamSong(trackId);
      return stream;
    } catch (e) {
      DebugLogger.logError('Error streaming track: $e');
      rethrow;
    }
  }

  Future<bool> addToFavorites(String trackId) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Adding track to favorites: $trackId');
      await _deezer!.addFavSongs([trackId]);
      return true;
    } catch (e) {
      DebugLogger.logError('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<bool> removeFromFavorites(String trackId) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Removing track from favorites: $trackId');
      await _deezer!.removeFavSongs([trackId]);
      return true;
    } catch (e) {
      DebugLogger.logError('Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> searchAlbums(String query) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Searching for albums: $query');
      final results = await _deezer!.searchAlbums(query);
      return results?.data ?? [];
    } catch (e) {
      DebugLogger.logError('Error searching albums: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> searchArtists(String query) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Searching for artists: $query');
      final results = await _deezer!.searchArtists(query);
      return results?.data ?? [];
    } catch (e) {
      DebugLogger.logError('Error searching artists: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> searchPlaylists(String query) async {
    if (!_isConnected || _deezer == null) {
      throw Exception('Not connected to Deezer');
    }

    try {
      DebugLogger.logInfo('Searching for playlists: $query');
      final results = await _deezer!.searchPlaylists(query);
      return results?.data ?? [];
    } catch (e) {
      DebugLogger.logError('Error searching playlists: $e');
      rethrow;
    }
  }
}
