import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sonnet/widgets/random_circles.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selector.dart';
import '../utils/debug_logger.dart';
import '../components/genres_selection.dart';
import '../components/advanced_tag_selector.dart';
import '../components/submit_button.dart';
import '../components/playlist_item.dart';
import '../services/playlist_service.dart';

import 'package:url_launcher/url_launcher.dart';
import '../widgets/spotify_auth_handler.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  // Constants for better maintainability
  static const double _topPadding = 50.0;
  static const double _horizontalPadding = 16.0;
  static const double _bottomPadding = 20.0;
  static const double _loadingContainerSize = 50.0;
  static const double _loadingPadding = 12.0;
  static const double _floatingActionButtonPadding = 8.0;
  static const double _floatingActionButtonRadius = 100.0;
  static const double _dialogIconSize = 50.0;
  static const double _dialogIconSpacing = 8.0;
  static const double _playlistButtonSize = 40.0;
  static const double _moodContainerPadding = 3.0;
  static const double _moodTextPadding = 16.0;
  static const double _moodBorderRadius = 20.0;
  static const double _moodBorderWidth = 0.4;
  static const double _playlistHeaderMargin = 20.0;
  static const double _playlistHeaderPadding = 16.0;
  static const double _resetButtonPadding = 12.0;
  static const double _resetButtonBorderRadius = 20.0;
  static const double _resetButtonBorderWidth = 1.0;
  static const double _resetIconSize = 16.0;
  static const double _resetIconSpacing = 6.0;
  static const double _resetLoadingSize = 12.0;
  static const double _resetLoadingStrokeWidth = 2.0;
  static const double _playlistTopPadding = 40.0;
  static const double _playlistBorderRadius = 12.0;
  static const double _playlistBorderWidth = 0.4;
  
  static const Duration _snackBarDuration = Duration(seconds: 2);
  static const Duration _errorSnackBarDuration = Duration(seconds: 5);
  static const Duration _playlistErrorDuration = Duration(seconds: 3);
  
  static const Color _primaryGradientStart = Color(0xFF330000);
  static const Color _primaryGradientEnd = Color(0xFF000000);
  static const Color _whiteColor = Color(0xFFFFFFFF);
  static const Color _blackColor = Color(0xFF000000);
  static const Color _spotifyGreen = Color(0xFF1DB954);
  static const Color _successBackground = Colors.green;
  static const Color _errorBackground = Colors.red;
  static const Color _floatingActionButtonBackground = Color(0xFFFFCCCC);
  static const Color _moodTextColor = Color(0xFF000000);
  static const Color _playlistTextColor = Color(0xFFFFFFFF);
  static const Color _loadingColor = Color(0xFFFFFFFF);
  
  static const String _backgroundImagePath = "assets/images/background.png";
  static const String _spotifyImagePath = "assets/images/spotify.png";
  static const String _audiomackImagePath = "assets/images/audiomack.png";
  static const String _spotifyPlaylistsUrl = 'spotify://playlists';
  static const String _webPlaylistsUrl = 'https://open.spotify.com/collection/playlists';
  static const String _spotifyHomeUrl = 'spotify://';
  static const String _spotifyWebUrl = 'https://open.spotify.com';
  static const String _audiomackSearchUrl = 'https://audiomack.com/search';
  static const String _spotifyWebPrefix = 'https://open.spotify.com/';
  static const String _spotifyAppPrefix = 'spotify://';

  // Selected genres list
  final Set<String> _selectedGenres = {};

  // Selected advanced tags
  final Set<String> _selectedTags = {};

  // Selected mood
  String? _selectedMood;

  // Selected mood image
  String? _selectedMoodImage;

  // Playlist
  List<Map<String, String>> _playlist = [];

  // State variable to control which column is shown
  bool _showAdvancedOptions = false;

  // Loading state
  bool _isLoading = false;
  bool _isLoadingDialogShown = false;

  // Service instance
  final PlaylistService _playlistService = PlaylistService();

  // Function for selected genre(s)
  void _onGenreTap(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }



  // Helper method to show error snackbar
  void _showErrorSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorBackground,
        duration: duration ?? _errorSnackBarDuration,
      ),
    );
  }

  // Helper method to show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _successBackground,
        duration: _snackBarDuration,
      ),
    );
  }

  // Helper method to validate selections
  bool _validateSelections() {
    if (_selectedMood == null || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).get('please_select_mood_genre')),
        ),
      );
      return false;
    }
    return true;
  }

  // Helper method to handle API errors
  String _getErrorMessage(dynamic error) {
    final l10n = AppLocalizations.of(context);
    final errorString = error.toString();
    if (errorString.contains('API token not configured') || errorString.contains('OpenAI API token not configured')) {
              return l10n.get('api_token_not_configured');
    } else if (errorString.contains('SocketException')) {
      return AppLocalizations.of(context).get('network_error');
    }
    return AppLocalizations.of(context).get('unexpected_error');
  }

  // Helper method to generate playlist
  Future<void> _generatePlaylist({bool isReset = false}) async {
    if (!_validateSelections()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final playlist = await _playlistService.generatePlaylist(
        _selectedMood!,
        _selectedGenres,
        selectedTags: _selectedTags,
      );

      setState(() {
        _playlist = playlist;
        _isLoading = false;
      });
      
      if (isReset) {
        _showSuccessSnackBar('${AppLocalizations.of(context).get('playlist_generated')} - ${AppLocalizations.of(context).get('reset')}');
      } else {
        _showSuccessSnackBar(AppLocalizations.of(context).get('playlist_generated'));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar(_getErrorMessage(e));
    }
  }

  // Function to reset playlist with new songs
  Future<void> _resetPlaylist() async {
    await _generatePlaylist(isReset: true);
  }

  // Function to submit mood and genres and fetch playlist
  Future<void> _submitSelections() async {
    await _generatePlaylist();
  }

  // Function to handle tag selection
  void _onTagTap(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _openSpotify() async {
    final l10n = AppLocalizations.of(context);
    try {
      // Kiểm tra xem có playlist không
      if (_playlist.isEmpty) {
        // Nếu không có playlist, mở trực tiếp vào Spotify Playlists
        await _openSpotifyPlaylists();
        return;
      }
      
      // Kiểm tra xem Spotify đã được kết nối chưa
      if (!_playlistService.isSpotifyConnected) {
        // Hiển thị dialog xác thực Spotify
        final success = await _showSpotifyAuth();
        if (!success) return;
      }
      
      // Hiển thị loading với thông báo cập nhật
      setState(() {
        _isLoading = true;
      });
      
      // Hiển thị dialog loading với thông báo cập nhật playlist
      _showCreatingPlaylistDialog();
      
      try {
        // Tạo hoặc cập nhật playlist trên Spotify
        final result = await _playlistService.createSpotifyPlaylist(
          mood: _selectedMood!,
          genres: _selectedGenres,
          songs: _playlist,
          tags: _selectedTags,
        );
        
        // Đóng dialog loading một cách an toàn
        _closeLoadingDialog();
        
        if (result != null) {
          // Hiển thị dialog thành công với link playlist
          await _showPlaylistCreatedDialog(result);
          
          // Hiển thị thông báo phù hợp
          final isMerged = result['merged'] == true;
          if (isMerged) {
            _showSuccessSnackBar('✅ ${l10n.get('playlist_merged_success')}');
          } else {
            _showSuccessSnackBar('🎵 ${l10n.get('playlist_new_success')}');
          }
        } else {
          throw Exception(l10n.get('cannot_create_playlist'));
        }
      } catch (e) {
        // Đóng dialog loading nếu có lỗi
        _closeLoadingDialog();
        _showErrorSnackBar(l10n.get('playlist_creation_error_message').replaceAll('{error}', e.toString()));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tạo playlist Spotify: $e');
      _showErrorSnackBar(l10n.get('error_creating_playlist'));
    }
  }

  /// Open Spotify app to Playlists section
  Future<void> _openSpotifyPlaylists() async {
    final l10n = AppLocalizations.of(context);
    bool launched = false;
    
    // Try Spotify app URI scheme for playlists
    try {
      // Open Spotify app to Library > Playlists section
      final uri = Uri.parse(_spotifyPlaylistsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        launched = true;
        print(l10n.get('launched_spotify_playlists_success'));
      }
    } catch (e) {
              print(l10n.get('failed_launch_spotify_playlists').replaceAll('{error}', e.toString()));
    }
    
    // If Spotify app failed, try web URL to playlists
    if (!launched) {
      try {
        final url = Uri.parse(_webPlaylistsUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          print(l10n.get('launched_web_playlists_success'));
        }
      } catch (e) {
        print(l10n.get('failed_launch_web_playlists').replaceAll('{error}', e.toString()));
      }
    }
    
    // If both failed, try to open Spotify app homepage
    if (!launched) {
      try {
        final uri = Uri.parse(_spotifyHomeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('Launched Spotify app homepage successfully');
        }
      } catch (e) {
        print('Failed to launch Spotify app homepage: $e');
        // Final fallback: open Spotify web
        try {
          final url = Uri.parse(_spotifyWebUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            print('Launched Spotify web successfully');
          }
        } catch (e) {
          print(l10n.get('failed_launch_spotify_web').replaceAll('{error}', e.toString()));
          _showErrorSnackBar(l10n.get('spotify_connection_error'));
        }
      }
    }
  }

  Future<void> _openAudiomack() async {
    try {
      // Tạo query ngắn hơn với chỉ 3 bài hát đầu tiên
      final shortPlaylist = _playlist.take(3).toList();
      final playlistQuery = shortPlaylist
          .map((song) => '${song['artist']} - ${song['title']}')
          .join(', ');
      
      // Encode URL để tránh ký tự đặc biệt
      final encodedQuery = Uri.encodeComponent(playlistQuery);
      final url = Uri.parse('$_audiomackSearchUrl/$encodedQuery');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: mở Audiomack search page
        final fallbackUrl = Uri.parse(_audiomackSearchUrl);
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Lỗi khi mở Audiomack: $e');
      // Fallback: mở Audiomack search page
      try {
        final fallbackUrl = Uri.parse(_audiomackSearchUrl);
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Không thể mở Audiomack: $e');
      }
    }
  }
  

  
  /// Show Spotify authentication dialog
  Future<bool> _showSpotifyAuth() async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpotifyAuthHandler(
        spotifyService: _playlistService.spotifyService,
        onAuthComplete: (success) async {
          Navigator.of(context).pop(success);
          
          // If authentication successful, automatically create playlist
          if (success && _selectedMood != null && _selectedGenres.isNotEmpty) {
            // Show loading dialog immediately after successful authentication
            _showCreatingPlaylistDialog();
            
            // Create playlist automatically
            try {
              final result = await _playlistService.createSpotifyPlaylist(
                mood: _selectedMood!,
                genres: _selectedGenres,
                songs: _playlist,
                tags: _selectedTags,
              );
              
              // Close loading dialog safely
              _closeLoadingDialog();
              
              if (result != null && mounted) {
                // Show playlist created dialog
                await _showPlaylistCreatedDialog(result);
                
                // Hiển thị thông báo phù hợp
                final isMerged = result['merged'] == true;
                if (isMerged) {
                  _showSuccessSnackBar('✅ ${l10n.get('playlist_merged_success')}');
                } else {
                  _showSuccessSnackBar('🎵 ${l10n.get('playlist_new_success')}');
                }
              }
            } catch (e) {
              // Close loading dialog on error safely
              _closeLoadingDialog();
              
              print('Error creating playlist: $e');
              // Show error
              if (mounted) {
                _showErrorSnackBar(
                  '❌ ${l10n.get('failed_to_create_playlist').replaceAll('{error}', e.toString())}',
                  duration: _playlistErrorDuration,
                );
              }
            }
          }
        },
      ),
    ) ?? false;
  }
  
  /// Show creating playlist dialog
  void _showCreatingPlaylistDialog() {
    if (_isLoadingDialogShown) return; // Prevent multiple dialogs
    
    final l10n = AppLocalizations.of(context);
    _isLoadingDialogShown = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button from closing dialog
        child: AlertDialog(
          backgroundColor: _blackColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Center(
            child: Text(
              l10n.get('creating_playlist'),
              style: GoogleFonts.inter(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: _whiteColor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: _whiteColor,
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: _blackColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '🎵 ${l10n.get('creating_playlist_desc')}',
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: _whiteColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Close loading dialog safely
  void _closeLoadingDialog() {
    if (_isLoadingDialogShown && mounted) {
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('Error closing loading dialog: $e');
      } finally {
        _isLoadingDialogShown = false;
      }
    }
  }

  /// Show playlist created success dialog
  Future<void> _showPlaylistCreatedDialog(Map<String, dynamic> result) async {
    final l10n = AppLocalizations.of(context);
    
    // Show success dialog directly since loading is already shown
    if (mounted) {
      final isMerged = result['merged'] == true;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _blackColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Center(
            child: Text(
              isMerged ? l10n.get('playlist_updated') : l10n.get('playlist_created'),
              style: GoogleFonts.inter(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: _whiteColor,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (isMerged) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _whiteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: _spotifyGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.get('playlist_updated_success').replaceAll('{name}', result['playlist_name']),
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: _whiteColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _whiteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: _whiteColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.get('new_tracks_added').replaceAll('{count}', result['total_tracks'].toString()),
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: _whiteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _whiteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cleaning_services, color: _whiteColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.get('duplicate_tracks_removed'),
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: _whiteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _whiteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.get('playlist_created_desc').replaceAll('{name}', result['playlist_name']),
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: _whiteColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _whiteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: _whiteColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.get('tracks_added').replaceAll('{count}', result['total_tracks'].toString()),
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: _whiteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _spotifyGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _spotifyGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new, color: _spotifyGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.get('open_in_spotify_desc'),
                        style: GoogleFonts.inter(
                          fontSize: 14.0,
                          color: _whiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: _whiteColor.withOpacity(0.7),
              ),
              child: Text(
                l10n.get('close'),
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final playlistUrl = result['playlist_url'];
                print('Opening playlist URL: $playlistUrl');
                
                bool launched = false;
                
                // Method 1: Try spotify:// URI scheme (app) - direct to specific playlist
                try {
                  final spotifyAppUrl = playlistUrl.replaceFirst(_spotifyWebPrefix, _spotifyAppPrefix);
                  print('Trying Spotify app URL: $spotifyAppUrl');
                  
                  final uri = Uri.parse(spotifyAppUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    launched = true;
                    print('✅ Successfully launched Spotify app with playlist');
                  } else {
                    print('❌ Cannot launch Spotify app URL: $spotifyAppUrl');
                  }
                } catch (e) {
                  print('❌ Error launching Spotify app: $e');
                }
                
                // Method 2: If app failed, try web URL
                if (!launched) {
                  try {
                    print('Trying web URL: $playlistUrl');
                    await launchUrl(
                      Uri.parse(playlistUrl),
                      mode: LaunchMode.externalApplication,
                    );
                    print('✅ Successfully launched web URL');
                  } catch (e) {
                    print('❌ Error launching web URL: $e');
                    if (mounted) {
                      _showErrorSnackBar(l10n.get('could_not_open_playlist').replaceAll('{error}', e.toString()));
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _spotifyGreen,
                foregroundColor: _whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                l10n.get('open_in_spotify'),
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Function to show the first column
  void _showFirstColumn() {
    setState(() {
      _playlist = [];
      _selectedGenres.clear();
    });
      }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      // Container for contents
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryGradientStart,
              _primaryGradientEnd,
            ],
          ),

          // Background image here
          image: DecorationImage(
            image: AssetImage(_backgroundImagePath),
            fit: BoxFit.cover,
          ),
        ),

        // Padding around contents
        child: Padding(
          padding: const EdgeInsets.only(
            top: _topPadding, 
            left: _horizontalPadding, 
            right: _horizontalPadding
          ),
          child: _isLoading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(_loadingPadding),
                    height: _loadingContainerSize,
                    width: _loadingContainerSize,
                    decoration: const BoxDecoration(
                      color: _whiteColor,
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: _blackColor,
                    ),
                  ),
                )
              : _playlist.isEmpty
                  ? _buildFirstColumn(l10n)
                  : _buildSecondColumn(l10n),
        ),
      ),
      floatingActionButton: _playlist.isEmpty
          ? Container()
          : Container(
              padding: const EdgeInsets.all(_floatingActionButtonPadding),
              decoration: BoxDecoration(
                color: _floatingActionButtonBackground.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                backgroundColor: _whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_floatingActionButtonRadius),
                ),
                onPressed: _showFirstColumn,
                child: const Icon(Icons.add_outlined),
              ),
            ),
    );
  }

  Widget _buildFirstColumn(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language selector at the top
        const Align(
          alignment: Alignment.topRight,
          child: LanguageSelector(),
        ),
        
        // First expanded for random circles for moods
        Expanded(
          child: RandomCircles(
            onMoodSelected: (mood, image) {
              _selectedMood = mood;
              _selectedMoodImage = image;
            },
          ),
        ),

        // Genres and submit button at the bottom
        Container(
          padding: const EdgeInsets.only(bottom: _bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container with fixed height for genres and advanced options
              SizedBox(
                height: 200, // Fixed height for both genres and advanced options
                child: Column(
                  children: [
                    // Header with title and indicators
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          // Title
                          Expanded(
                            child: Text(
                              _showAdvancedOptions 
                                  ? l10n.get('advanced_options')
                                  : l10n.get('select_genres'),
                              style: GoogleFonts.inter(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                              ),
                            ),
                          ),
                          
                          // Page indicators (dots)
                          Row(
                            children: [
                              // First dot (Genres)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: !_showAdvancedOptions 
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFFFFFFF).withOpacity(0.3),
                                ),
                              ),
                              // Second dot (Advanced Options)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _showAdvancedOptions 
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFFFFFFF).withOpacity(0.3),
                                ),
                              ),
                                                        // Swipe icon or back button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAdvancedOptions = !_showAdvancedOptions;
                              });
                            },
                            child: Icon(
                              _showAdvancedOptions ? Icons.arrow_back : Icons.swap_horiz,
                              color: const Color(0xFFFFFFFF).withOpacity(0.6),
                              size: 20,
                            ),
                          ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Content area with gesture detection
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          // Detect swipe direction - both left and right go to advanced options
                          if (details.primaryVelocity != null) {
                            // Any horizontal swipe shows advanced options
                            setState(() {
                              _showAdvancedOptions = true;
                            });
                          }
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _showAdvancedOptions
                              ? AdvancedTagSelector(
                                  key: const ValueKey('advanced'),
                                  selectedTags: _selectedTags,
                                  onTagTap: _onTagTap,
                                )
                              : GenresSelection(
                                  key: const ValueKey('genres'),
                                  selectedGenres: _selectedGenres,
                                  onGenreTap: _onGenreTap,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SubmitButton(onPressed: _submitSelections),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondColumn(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Language selector at the top
        const Align(
          alignment: Alignment.topRight,
          child: LanguageSelector(),
        ),
        
        Expanded(
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Center(
                              child: Text(
                                l10n.get('playlist_generated'),
                                style: GoogleFonts.inter(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // spotify container - tạo playlist
                                    GestureDetector(
                                      onTap: _openSpotify,
                                      child: Container(
                                        height: _dialogIconSize,
                                        width: _dialogIconSize,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: AssetImage(_spotifyImagePath),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: _dialogIconSpacing),
                                    // Audiomack container
                                    GestureDetector(
                                      onTap: _openAudiomack,
                                      child: Container(
                                        height: _dialogIconSize,
                                        width: _dialogIconSize,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: AssetImage(_audiomackImagePath),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _playlistService.isSpotifyConnected 
                                      ? l10n.get('spotify_update_existing')
                                      : l10n.get('spotify_create_new'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      height: _playlistButtonSize,
                      width: _playlistButtonSize,
                      decoration: const BoxDecoration(
                        color: _whiteColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.playlist_add_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: _playlistTopPadding),
                // Selected Mood image
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: _selectedMoodImage != null
                      ? BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_selectedMoodImage!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : null,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(_moodContainerPadding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_moodBorderRadius),
                    border: Border.all(
                      width: _moodBorderWidth,
                      color: _whiteColor.withOpacity(0.8),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: _moodTextPadding,
                      right: _moodTextPadding,
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: _whiteColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(_moodBorderRadius),
                    ),
                    // Selected mood text
                    child: Text(
                      _selectedMood != null ? l10n.get(_selectedMood!.toLowerCase()) : '',
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: _moodTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Container(
            margin: const EdgeInsets.only(top: _playlistHeaderMargin),
            padding: const EdgeInsets.all(_playlistHeaderPadding),
            decoration: BoxDecoration(
              border: const Border(
                top: BorderSide(
                  width: _playlistBorderWidth,
                  color: _whiteColor,
                ),
              ),
              borderRadius: BorderRadius.circular(_playlistBorderRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.get('playlist_generated'),
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: _playlistTextColor.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // Reset button - chỉ hiện khi có playlist
                if (_playlist.isNotEmpty)
                  GestureDetector(
                    onTap: _isLoading ? null : _resetPlaylist,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _resetButtonPadding, 
                        vertical: 6.0
                      ),
                      decoration: BoxDecoration(
                        color: _isLoading 
                          ? _whiteColor.withOpacity(0.3)
                          : _whiteColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_resetButtonBorderRadius),
                        border: Border.all(
                          color: _whiteColor.withOpacity(0.5),
                          width: _resetButtonBorderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: _resetLoadingSize,
                              height: _resetLoadingSize,
                              child: CircularProgressIndicator(
                                strokeWidth: _resetLoadingStrokeWidth,
                                valueColor: AlwaysStoppedAnimation<Color>(_loadingColor),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh,
                              size: _resetIconSize,
                              color: _whiteColor,
                            ),
                          const SizedBox(width: _resetIconSpacing),
                          Text(
                            _isLoading ? l10n.get('loading') : l10n.get('reset'),
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: _whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(0.0),
            itemCount: _playlist.length,
            itemBuilder: (context, index) {
              final song = _playlist[index];
              return PlaylistItem(
                artist: song['artist']!,
                title: song['title']!,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Reset loading dialog state when widget is disposed
    _isLoadingDialogShown = false;
    super.dispose();
  }
}
