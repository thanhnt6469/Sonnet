import 'package:flutter/material.dart';
import 'package:sonnet/screens/prompt_screen.dart';
import 'package:sonnet/screens/deezer_library_screen.dart';
import 'package:sonnet/screens/music_genre_screen.dart';

class TogglePage extends StatefulWidget {
  const TogglePage({super.key});

  @override
  State<TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<TogglePage> {
  int _currentIndex = 0; // Bắt đầu với PromptScreen

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const PromptScreen(),
          const DeezerLibraryScreen(),
          const MusicGenreScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add),
            label: 'Playlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Music Genre',
          ),
        ],
      ),
    );
  }
}
