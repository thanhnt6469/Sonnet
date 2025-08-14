import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/language_selector.dart';
import '../services/deezer_service.dart';

class DeezerLibraryScreen extends StatefulWidget {
  const DeezerLibraryScreen({super.key});

  @override
  State<DeezerLibraryScreen> createState() => _DeezerLibraryScreenState();
}

class _DeezerLibraryScreenState extends State<DeezerLibraryScreen> {
  final DeezerService _deezerService = DeezerService.instance;
  bool _isLoading = false;
  bool _isConnected = false;
  String _arlToken = '';
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeDeezer();
  }

  Future<void> _initializeDeezer() async {
    await _deezerService.initialize();
    setState(() {
      _isConnected = _deezerService.isConnected;
    });
  }

  Future<void> _connectToDeezer() async {
    if (_arlToken.isEmpty) {
      _showSnackBar('Please enter your Deezer ARL token', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _deezerService.connect(_arlToken);
      setState(() {
        _isConnected = success;
        _isLoading = false;
      });
      
      if (success) {
        _showSnackBar('Connected to Deezer successfully!');
      } else {
        _showSnackBar('Failed to connect to Deezer', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to connect to Deezer: $e', isError: true);
    }
  }

  Future<void> _searchTracks(String query) async {
    if (query.trim().isEmpty) return;
    
    if (!_isConnected) {
      _showSnackBar('Please connect to Deezer first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _deezerService.searchTracks(query);
      print('Search results type: ${results.runtimeType}');
      if (results.isNotEmpty) {
        print('First result type: ${results.first.runtimeType}');
        print('First result: $results.first');
      }
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Search failed: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C7F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deezer Connection',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isConnected ? 'Connected' : 'Not connected',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_isConnected) ...[
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your Deezer ARL token',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF00C7F2)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _arlToken = value;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _connectToDeezer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Connect to Deezer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search for tracks, artists, albums...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: _searchTracks,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C7F2)),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for your favorite music',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        return _buildTrackCard(track);
      },
    );
  }

  Widget _buildTrackCard(dynamic track) {
    // Handle different track object types
    String title = 'Unknown Title';
    String artist = 'Unknown Artist';
    String album = 'Unknown Album';
    String cover = '';

    try {
      // Try to access as Map first (for backward compatibility)
      if (track is Map<String, dynamic>) {
        title = track['title'] ?? 'Unknown Title';
        artist = track['artist']?['name'] ?? 'Unknown Artist';
        album = track['album']?['title'] ?? 'Unknown Album';
        cover = track['album']?['cover'] ?? '';
      } else {
        // Handle AlbumTrack object
        title = track.title ?? 'Unknown Title';
        artist = track.artist?.name ?? 'Unknown Artist';
        album = track.album?.title ?? 'Unknown Album';
        cover = track.album?.cover ?? '';
      }
    } catch (e) {
      // Fallback to safe values
      title = 'Unknown Title';
      artist = 'Unknown Artist';
      album = 'Unknown Album';
      cover = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: cover.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(cover),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: cover.isEmpty
                ? const Icon(Icons.music_note, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color(0xFF00C7F2)),
            onPressed: () {
              // TODO: Implement play functionality
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF330000), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Deezer Library',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const LanguageSelector(),
                  ],
                ),
              ),
              
              // Connection Section
              _buildConnectionSection(),
              
              // Search Bar
              _buildSearchBar(),
              
              const SizedBox(height: 16),
              
              // Content
              Expanded(
                child: _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
