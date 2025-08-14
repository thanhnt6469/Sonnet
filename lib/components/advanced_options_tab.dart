import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/music_tags.dart';

class AdvancedOptionsTab extends StatefulWidget {
  final Set<String> selectedTags;
  final Function(String) onTagTap;

  const AdvancedOptionsTab({
    super.key,
    required this.selectedTags,
    required this.onTagTap,
  });

  @override
  State<AdvancedOptionsTab> createState() => _AdvancedOptionsTabState();
}

class _AdvancedOptionsTabState extends State<AdvancedOptionsTab> {
  int _currentCategoryIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _categories = [
    'languages',
    'tempos',
    'energy',
    'eras',
    'activities',
    'instruments',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(int index) {
    setState(() {
      _currentCategoryIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and page indicator
        Row(
          children: [
            Text(
              l10n.get('advanced_options'),
              style: GoogleFonts.inter(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentCategoryIndex + 1}:${_categories.length}',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Category tabs
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _currentCategoryIndex == index;
              
              return GestureDetector(
                onTap: () => _onCategoryChanged(index),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MusicTags.getCategoryIcon(category),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        MusicTags.getCategoryName(category),
                        style: GoogleFonts.inter(
                          fontSize: 14.0,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Tags content
        Container(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCategoryIndex = index;
              });
            },
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final tags = MusicTags.getTagsByCategory(category);
              
              return SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final isSelected = widget.selectedTags.contains(tag);
                    final isVietnamese = MusicTags.isVietnameseTag(tag);
                    
                    return GestureDetector(
                      onTap: () => widget.onTagTap(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (isVietnamese ? Colors.red[400] : Colors.blue[400])
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? (isVietnamese ? Colors.red[300]! : Colors.blue[300]!)
                                : Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              MusicTags.getTagDisplayName(tag, l10n: l10n.get),
                              style: GoogleFonts.inter(
                                fontSize: 12.0,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
