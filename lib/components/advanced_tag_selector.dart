import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class AdvancedTagSelector extends StatefulWidget {
  final Set<String> selectedTags;
  final Function(String) onTagTap;

  const AdvancedTagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagTap,
  });

  @override
  State<AdvancedTagSelector> createState() => _AdvancedTagSelectorState();
}

class _AdvancedTagSelectorState extends State<AdvancedTagSelector> {
  // Tag categories with display names
  final Map<String, Map<String, dynamic>> tagCategories = {
    'languages': {
      'title': 'select_languages',
      'tags': [
        'lang_vietnamese', 'lang_korean', 'lang_english', 'lang_japanese', 
        'lang_latin', 'lang_chinese', 'lang_thai', 'lang_indian', 'lang_arabic'
      ]
    },
    'tempos': {
      'title': 'select_tempos',
      'tags': [
        'tempo_slow', 'tempo_medium', 'tempo_fast', 'tempo_very_slow', 
        'tempo_very_fast', 'tempo_variable'
      ]
    },
    'instrumentation': {
      'title': 'select_instrumentation',
      'tags': [
        'instrument_acoustic', 'instrument_electric', 'instrument_orchestral', 
        'instrument_lofi', 'instrument_piano', 'instrument_guitar', 'instrument_drums',
        'instrument_synth', 'instrument_strings', 'instrument_brass', 'instrument_violin',
        'instrument_flute', 'instrument_clarinet', 'instrument_trumpet', 'instrument_saxophone'
      ]
    },
    'eras': {
      'title': 'select_eras',
      'tags': [
        'era_80s', 'era_90s', 'era_2000s', 'era_2010s', 'era_modern'
      ]
    },
    'activities': {
      'title': 'select_activities',
      'tags': [
        'activity_gym', 'activity_work', 'activity_driving', 'activity_relaxing',
        'activity_study', 'activity_party', 'activity_sleep', 'activity_cooking',
        'activity_cleaning', 'activity_romance', 'activity_social', 'activity_workout'
      ]
    },
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tagCategories.entries.map((entry) {
          final categoryKey = entry.key;
          final categoryData = entry.value;
          final title = categoryData['title'] as String;
          final tags = categoryData['tags'] as List<String>;
          
          return _buildCategorySection(categoryKey, title, tags, l10n);
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySection(String categoryKey, String titleKey, List<String> tags, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category title - giống như "select_genre"
          Text(
            l10n.get(titleKey),
            style: GoogleFonts.inter(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFFFFF).withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 6),

          // Tags - giống như genres selection
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 3.0),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Wrap(
                  children: tags.map((tag) {
                    final isSelected = widget.selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        widget.onTagTap(tag);
                        setState(() {});
                      },
                      // Container with border around each tag - giống y như genres
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        margin: const EdgeInsets.only(right: 3.0, top: 3.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(
                            width: 0.4,
                            color: const Color(0xFFFFFFFF).withOpacity(0.8),
                          ),
                        ),
                        // Container for each tag - giống y như genres
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            right: 12.0,
                            top: 6.0,
                            bottom: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0000FF)
                                : const Color(0xFFFFFFFF).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          // Text for each tag - giống y như genres
                          child: Text(
                            _getTagDisplayName(tag, l10n),
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
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
        ],
      ),
    );
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
        case 'instrument_acoustic': return 'Acoustic';
        case 'instrument_electric': return 'Electric';
        case 'instrument_orchestral': return 'Orchestral';
        case 'instrument_lofi': return 'Lofi';
        case 'instrument_piano': return 'Piano';
        case 'instrument_guitar': return 'Guitar';
        case 'instrument_drums': return 'Drums';
        case 'instrument_synth': return 'Synth';
        case 'instrument_strings': return 'Strings';
        case 'instrument_brass': return 'Brass';
        case 'instrument_violin': return 'Violin';
        case 'instrument_flute': return 'Flute';
        case 'instrument_clarinet': return 'Clarinet';
        case 'instrument_trumpet': return 'Trumpet';
        case 'instrument_saxophone': return 'Saxophone';
        case 'era_80s': return '80s';
        case 'era_90s': return '90s';
        case 'era_2000s': return '2000s';
        case 'era_2010s': return '2010s';
        case 'era_modern': return 'Hiện đại';
        case 'activity_gym': return 'Tập gym';
        case 'activity_work': return 'Làm việc';
        case 'activity_driving': return 'Lái xe';
        case 'activity_relaxing': return 'Thư giãn';
        case 'activity_study': return 'Học tập';
        case 'activity_party': return 'Đi chơi';
        case 'activity_sleep': return 'Ngủ';
        case 'activity_cooking': return 'Nấu ăn';
        case 'activity_cleaning': return 'Vệ sinh';
        case 'activity_romance': return 'Tình yêu';
        case 'activity_social': return 'Xã hội';
        case 'activity_workout': return 'Tập thể dục';
        default: return tag;
      }
    }
  }
}
