import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sonnet/random_circles.dart';
import 'dart:convert';
import 'l10n/app_localizations.dart';
import 'widgets/language_selector.dart';

import 'package:url_launcher/url_launcher.dart';

class PromptScreen extends StatefulWidget {
  final VoidCallback showHomeScreen;
  const PromptScreen({super.key, required this.showHomeScreen});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  // Genre list
  final List<String> genres = [
    'jazz',
    'rock',
    'amapiano',
    'rnb',
    'latin',
    'hiphop',
    'hiplife',
    'reggae',
    'gospel',
    'afrobeat',
    'blues',
    'country',
    'punk',
    'pop',
  ];

  // Selected genres list
  final Set<String> _selectedGenres = {};

  // Selected mood
  String? _selectedMood;

  // Selected mood image
  String? _selectedMoodImage;

  // Playlist
  List<Map<String, String>> _playlist = [];

  // Loading state
  bool _isLoading = false;

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

  // Function to submit mood and genres and fetch playlist
  Future<void> _submitSelections() async {
    if (_selectedMood == null || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).get('please_select_mood_genre')),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if API token is available
      final apiToken = dotenv.env['token'];
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception('OpenAI API token not configured. Please check your .env file.');
      }

          // Construct the prompt text using the selected mood and genres
    final promptText = 'Create a music playlist for Mood: $_selectedMood, Genres: ${_selectedGenres.join(', ')}. '
        'Please provide exactly 10 songs in this format: "Artist Name - Song Title" (one per line, no numbering). '
        'Focus on popular and well-known songs that match the mood and genres. '
        'Make sure to include diverse artists and avoid repeating the same songs. '
        'Current time: ${DateTime.now().millisecondsSinceEpoch}';

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
            'temperature': 0,
            "top_p": 1,
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

        setState(() {
          // Parse the playlist string with multiple format support
          _playlist = playlistString.split('\n').where((line) => line.trim().isNotEmpty).map((song) {
            // Remove numbering (1., 2., etc.)
            String cleanSong = song.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
            
            // Debug: print the song being parsed
            print('Parsing song: "$cleanSong"');
            
            // Try different parsing patterns
            Map<String, String> result = {'artist': 'Unknown Artist', 'title': 'Unknown Title'};
            
            // Pattern 1: "Artist - Title" (most common format)
            if (cleanSong.contains(' - ')) {
              List<String> parts = cleanSong.split(' - ');
              if (parts.length >= 2) {
                String artist = parts[0].trim();
                String title = parts[1].trim();
                // Remove any extra spaces or special characters
                artist = artist.replaceAll(RegExp(r'\s+'), ' ').trim();
                title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
                result = {'artist': artist, 'title': title};
                print('Parsed: Artist="$artist", Title="$title"');
              }
            }
            // Pattern 2: "Artist, "Title"" (quoted format)
            else {
              RegExp pattern1 = RegExp(r'^(.+?),\s*"([^"]+)"$');
              Match? match1 = pattern1.firstMatch(cleanSong);
              if (match1 != null) {
                result = {'artist': match1.group(1)!.trim(), 'title': match1.group(2)!.trim()};
              }
              // Pattern 3: "Artist: Title"
              else if (cleanSong.contains(': ')) {
                List<String> parts = cleanSong.split(': ');
                if (parts.length >= 2) {
                  result = {'artist': parts[0].trim(), 'title': parts[1].trim()};
                }
              }
              // Pattern 4: Just artist and title separated by comma
              else if (cleanSong.contains(',')) {
                List<String> parts = cleanSong.split(',');
                if (parts.length >= 2) {
                  result = {'artist': parts[0].trim(), 'title': parts[1].trim()};
                }
              }
            }
            
            return result;
          }).toList();
          _isLoading = false;
        });
      } else {
        // Handle API errors
        final errorData = json.decode(response.body);
        String errorMessage = AppLocalizations.of(context).get('no_songs_found');
        
        if (errorData['error'] != null) {
          final error = errorData['error'];
          final errorType = error['type'] as String?;
          final errorMsg = error['message'] as String?;
          
          if (errorType == 'insufficient_quota') {
            errorMessage = AppLocalizations.of(context).get('api_quota_exceeded');
          } else if (errorType == 'invalid_api_key') {
            errorMessage = AppLocalizations.of(context).get('invalid_api_key');
          } else if (errorType == 'rate_limit_exceeded') {
            errorMessage = AppLocalizations.of(context).get('rate_limit_exceeded');
          } else if (errorMsg != null) {
            errorMessage = 'API Error: $errorMsg';
          }
        }
        
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = AppLocalizations.of(context).get('unexpected_error');
      if (e.toString().contains('API token not configured')) {
        errorMessage = AppLocalizations.of(context).get('api_not_configured');
      } else if (e.toString().contains('SocketException')) {
        errorMessage = AppLocalizations.of(context).get('network_error');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _openSpotify() async {
    final playlistQuery = _playlist
        .map((song) => '${song['artist']} - ${song['title']}')
        .join(', ');
    final url = Uri.parse('https://open.spotify.com/search/$playlistQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _openAudiomack() async {
    final playlistQuery = _playlist
        .map((song) => '${song['artist']} - ${song['title']}')
        .join(', ');
    final url = Uri.parse('https://audiomack.com/search/$playlistQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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
              Color(0xFF330000),
              Color(0xFF000000),
            ],
          ),

          // Background image here
          image: DecorationImage(
            image: AssetImage(
              "assets/images/background.png",
            ),
            fit: BoxFit.cover,
          ),
        ),

        // Padding around contents
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
          child: _isLoading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    height: 50.0,
                    width: 50.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF000000),
                    ),
                  ),
                )
              : _playlist.isEmpty
                  ?
                  // First Columns starts here
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language selector at the top
                        Align(
                          alignment: Alignment.topRight,
                          child: const LanguageSelector(),
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

                        // Second expanded for various genres and submit button
                        Expanded(
                          // Padding at the top of various genres and submit button in a column
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),

                            // Column starts here
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Genre text here
                                Text(
                                  l10n.get('select_genres'),
                                  style: GoogleFonts.inter(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFFFFF)
                                        .withOpacity(0.8),
                                  ),
                                ),

                                // Padding around various genres in a wrap
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10.0,
                                    right: 10.0,
                                    top: 5.0,
                                  ),

                                  // Wrap starts here
                                  child: StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return Wrap(
                                        children: genres.map((genre) {
                                          final isSelected =
                                              _selectedGenres.contains(genre);
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (_selectedGenres
                                                    .contains(genre)) {
                                                  _selectedGenres.remove(genre);
                                                } else {
                                                  _selectedGenres.add(genre);
                                                }
                                              });
                                            },

                                            // Container with border around each genre
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              margin: const EdgeInsets.only(
                                                  right: 4.0, top: 4.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                                border: Border.all(
                                                  width: 0.4,
                                                  color: const Color(0xFFFFFFFF)
                                                      .withOpacity(0.8),
                                                ),
                                              ),

                                              // Container for each genre
                                              child: Container(
                                                padding: const EdgeInsets.only(
                                                  left: 16.0,
                                                  right: 16.0,
                                                  top: 8.0,
                                                  bottom: 8.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF0000FF)
                                                      : const Color(0xFFFFFFFF)
                                                          .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                ),

                                                // Text for each genre
                                                child: Text(
                                                  l10n.get(genre),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFFFFFFF)
                                                        : const Color(
                                                            0xFF000000),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                  // Wrap ends here
                                ),

                                // Padding around the submit button here
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 60.0,
                                    left: 10.0,
                                    right: 10.0,
                                  ),

                                  // Container for submit button in GestureDetector
                                  child: GestureDetector(
                                    onTap: _submitSelections,

                                    // Container for submit button
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        color: const Color(0xFFFFCCCC),
                                      ),

                                      // Submit text centered
                                      child: Center(
                                        // Submit text here
                                        child: Text(
                                          l10n.get('submit'),
                                          style: GoogleFonts.inter(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Column ends here
                          ),
                        ),
                      ],
                    )
                  // First Columns ends here

                  // Second Column starts here
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Language selector at the top
                        Align(
                          alignment: Alignment.topRight,
                          child: const LanguageSelector(),
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
                                            content: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // spotify container
                                                GestureDetector(
                                                  onTap: _openSpotify,
                                                  child: Container(
                                                    height: 50.0,
                                                    width: 50.0,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          "assets/images/spotify.png",
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 8.0,
                                                ),
                                                // Audiomack container
                                                GestureDetector(
                                                  onTap: _openAudiomack,
                                                  child: Container(
                                                    height: 50.0,
                                                    width: 50.0,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          "assets/images/audiomack.png",
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      height: 40.0,
                                      width: 40.0,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFFFFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.playlist_add_rounded,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 40.0),
                                // Selected Mood image
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: _selectedMoodImage != null
                                      ? BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                AssetImage(_selectedMoodImage!),
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    border: Border.all(
                                      width: 0.4,
                                      color: const Color(0xFFFFFFFF)
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      left: 16.0,
                                      right: 16.0,
                                      top: 8.0,
                                      bottom: 8.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF)
                                          .withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    // Selected mood text
                                    child: Text(
                                      _selectedMood != null ? l10n.get(_selectedMood!.toLowerCase()) : '',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF000000),
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
                            margin: const EdgeInsets.only(top: 20.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              border: const Border(
                                top: BorderSide(
                                  width: 0.4,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child:
                                // Playlist text here
                                Text(
                              l10n.get('playlist_generated'),
                              style: GoogleFonts.inter(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(0.0),
                            itemCount: _playlist.length,
                            itemBuilder: (context, index) {
                              final song = _playlist[index];

                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 20.0,
                                ),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCCCC)
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFCCCC)
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Container(
                                          height: 65.0,
                                          width: 65.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFFFF),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                "assets/images/sonnetlogo.png",
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: Text(
                                                song['artist']!,
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w300,
                                                  color: Color(0xFFFFFFFF),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: Text(
                                                song['title']!,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFFFFFF),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          // Second column ends here
        ),
      ),
      floatingActionButton: _playlist.isEmpty
          ? Container()
          : Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCCCC).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
                onPressed: _showFirstColumn,
                child: const Icon(
                  Icons.add_outlined,
                ),
              ),
            ),
    );
  }
}
