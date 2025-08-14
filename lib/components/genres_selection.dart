import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class GenresSelection extends StatefulWidget {
  final Set<String> selectedGenres;
  final Function(String) onGenreTap;

  const GenresSelection({
    super.key,
    required this.selectedGenres,
    required this.onGenreTap,
  });

  @override
  State<GenresSelection> createState() => _GenresSelectionState();
}

class _GenresSelectionState extends State<GenresSelection> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          top: 5.0,
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Wrap(
              children: genres.map((genre) {
                final isSelected = widget.selectedGenres.contains(genre);
                return GestureDetector(
                  onTap: () {
                    widget.onGenreTap(genre);
                    setState(() {});
                  },

                  // Container with border around each genre
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    margin: const EdgeInsets.only(right: 4.0, top: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        width: 0.4,
                        color: const Color(0xFFFFFFFF).withOpacity(0.8),
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
                            : const Color(0xFFFFFFFF).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20.0),
                      ),

                      // Text for each genre
                      child: Text(
                        l10n.get(genre),
                        style: GoogleFonts.inter(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
} 