import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import 'genres_selection.dart';

class TabbedSelection extends StatefulWidget {
  final Set<String> selectedGenres;
  final Set<String> selectedTags;
  final Function(String) onGenreTap;
  final Function(String) onTagTap;

  const TabbedSelection({
    super.key,
    required this.selectedGenres,
    required this.selectedTags,
    required this.onGenreTap,
    required this.onTagTap,
  });

  @override
  State<TabbedSelection> createState() => _TabbedSelectionState();
}

class _TabbedSelectionState extends State<TabbedSelection> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: [
        // Tab Header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Select Genre Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTabIndex = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentTabIndex == 0 
                          ? Colors.blue[600] 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          color: _currentTabIndex == 0 
                              ? Colors.white 
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get('select_genre'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _currentTabIndex == 0 
                                ? Colors.white 
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Advanced Options Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTabIndex = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentTabIndex == 1 
                          ? Colors.blue[600] 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          color: _currentTabIndex == 1 
                              ? Colors.white 
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get('advanced_options'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _currentTabIndex == 1 
                                ? Colors.white 
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentTabIndex == 0 
                    ? Colors.blue[600] 
                    : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentTabIndex == 1 
                    ? Colors.blue[600] 
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Content based on selected tab
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentTabIndex == 0
              ? GenresSelection(
                  key: const ValueKey('genres'),
                  selectedGenres: widget.selectedGenres,
                  onGenreTap: widget.onGenreTap,
                )
              : _buildAdvancedOptions(l10n),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions(AppLocalizations l10n) {
    return Container(
      key: const ValueKey('advanced'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language / Region
            _buildCategorySection(
              'languages',
              Icons.language,
              l10n.get('languages'),
            ),
            
            const SizedBox(height: 16),
            
            // Tempo
            _buildCategorySection(
              'tempos',
              Icons.speed,
              l10n.get('tempos'),
            ),
            
            const SizedBox(height: 16),
            
            // Energy
            _buildCategorySection(
              'energy',
              Icons.flash_on,
              l10n.get('energy'),
            ),
            
            const SizedBox(height: 16),
            
            // Era
            _buildCategorySection(
              'eras',
              Icons.history,
              l10n.get('eras'),
            ),
            
            const SizedBox(height: 16),
            
            // Activity
            _buildCategorySection(
              'activities',
              Icons.directions_run,
              l10n.get('activities'),
            ),
            
            const SizedBox(height: 16),
            
            // Instruments
            _buildCategorySection(
              'instruments',
              Icons.music_note,
              l10n.get('instruments'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, IconData icon, String title) {
    final l10n = AppLocalizations.of(context);
    final tags = _getTagsByCategory(category);
    final selectedTags = widget.selectedTags.where((tag) => tag.startsWith('${category}_')).toSet();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Tags Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => widget.onTagTap(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  _getTagDisplayName(tag, l10n),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _getTagsByCategory(String category) {
    switch (category) {
      case 'languages':
        return [
          'lang_vietnamese', 'lang_korean', 'lang_english', 'lang_japanese', 
          'lang_latin', 'lang_chinese', 'lang_thai', 'lang_indian', 'lang_arabic'
        ];
      case 'tempos':
        return ['tempo_slow', 'tempo_medium', 'tempo_fast', 'tempo_very_slow', 'tempo_very_fast', 'tempo_variable'];
      case 'energy':
        return ['energy_low', 'energy_medium', 'energy_high', 'energy_very_low', 'energy_very_high'];
      case 'eras':
        return ['era_80s', 'era_90s', 'era_2000s', 'era_2010s', 'era_modern'];
      case 'activities':
        return ['activity_gym', 'activity_work', 'activity_driving', 'activity_relaxing'];
      case 'instruments':
        return ['instrument_acoustic', 'instrument_electric', 'instrument_orchestral', 'instrument_lofi'];
      default:
        return [];
    }
  }

  String _getTagDisplayName(String tag, AppLocalizations l10n) {
    try {
      return l10n.get(tag);
    } catch (e) {
      // Fallback to hardcoded names if localization fails
      switch (tag) {
        case 'lang_vietnamese': return 'Nhạc Việt';
        case 'lang_korean': return 'Kpop';
        case 'lang_english': return 'US-UK';
        case 'lang_japanese': return 'Jpop';
        case 'lang_latin': return 'Latin';
        case 'lang_chinese': return 'C-pop';
        case 'lang_thai': return 'Thái';
        case 'lang_indian': return 'Ấn Độ';
        case 'lang_arabic': return 'Ả Rập';
        case 'tempo_slow': return 'Chậm';
        case 'tempo_medium': return 'Vừa phải';
        case 'tempo_fast': return 'Nhanh';
        case 'tempo_very_slow': return 'Rất chậm';
        case 'tempo_very_fast': return 'Rất nhanh';
        case 'tempo_variable': return 'Thay đổi';
        case 'energy_low': return 'Thấp';
        case 'energy_medium': return 'Trung bình';
        case 'energy_high': return 'Cao';
        case 'energy_very_low': return 'Rất thấp';
        case 'energy_very_high': return 'Rất cao';
        case 'era_80s': return '80s';
        case 'era_90s': return '90s';
        case 'era_2000s': return '2000s';
        case 'era_2010s': return '2010s';
        case 'era_modern': return 'Hiện đại';
        case 'activity_gym': return 'Tập gym';
        case 'activity_work': return 'Làm việc';
        case 'activity_driving': return 'Lái xe';
        case 'activity_relaxing': return 'Thư giãn';
        case 'instrument_acoustic': return 'Acoustic';
        case 'instrument_electric': return 'Electric';
        case 'instrument_orchestral': return 'Orchestral';
        case 'instrument_lofi': return 'Lo-fi';
        default: return tag;
      }
    }
  }
}
