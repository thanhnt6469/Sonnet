import 'package:flutter/material.dart';

class MusicTags {

  // Language / Region
  static const List<String> languages = [
    'lang_vietnamese',
    'lang_korean',
    'lang_english',
    'lang_japanese',
    'lang_latin',
    'lang_chinese',
    'lang_thai',
    'lang_indian',
    'lang_arabic',
  ];

  // Tempo / Energy
  static const List<String> tempos = [
    'tempo_slow',
    'tempo_medium',
    'tempo_fast',
    'tempo_very_slow',
    'tempo_very_fast',
    'tempo_variable',
  ];

  static const List<String> energy = [
    'energy_high',
    'energy_medium',
    'energy_low',
    'energy_upbeat',
    'energy_chill',
    'energy_mellow',
    'energy_intense',
    'energy_relaxed',
  ];

  // Era / Thập niên
  static const List<String> eras = [
    'era_80s',
    'era_90s',
    'era_2000s',
    'era_2010s',
    'era_2020s',
    'era_modern',
    'era_classic',
    'era_vintage',
    'era_contemporary',
  ];

  // Activity / Context
  static const List<String> activities = [
    'activity_workout',
    'activity_study',
    'activity_driving',
    'activity_relaxation',
    'activity_party',
    'activity_sleep',
    'activity_cooking',
    'activity_cleaning',
    'activity_romance',
    'activity_social',
  ];

  // Instrumentation / Style
  static const List<String> instruments = [
    'instrument_acoustic',
    'instrument_electric',
    'instrument_orchestral',
    'instrument_lofi',
    'instrument_piano',
    'instrument_guitar',
    'instrument_drums',
    'instrument_synth',
    'instrument_strings',
    'instrument_brass',
  ];

  // Get all tags
  static List<String> getAllTags() {
    return [
      ...languages,
      ...tempos,
      ...energy,
      ...eras,
      ...activities,
      ...instruments,
    ];
  }

  // Get tags by category
  static List<String> getTagsByCategory(String category) {
    switch (category) {
      case 'languages':
        return languages;
      case 'tempos':
        return tempos;
      case 'energy':
        return energy;
      case 'eras':
        return eras;
      case 'activities':
        return activities;
      case 'instruments':
        return instruments;
      default:
        return [];
    }
  }

  // Get category name
  static String getCategoryName(String category) {
    switch (category) {
      case 'languages':
        return 'Ngôn Ngữ / Khu Vực';
      case 'tempos':
        return 'Nhịp Độ';
      case 'energy':
        return 'Năng Lượng';
      case 'eras':
        return 'Thời Kỳ';
      case 'activities':
        return 'Hoạt Động';
      case 'instruments':
        return 'Nhạc Cụ / Phong Cách';
      default:
        return category;
    }
  }

  // Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'languages':
        return Icons.language;
      case 'tempos':
        return Icons.speed;
      case 'energy':
        return Icons.flash_on;
      case 'eras':
        return Icons.history;
      case 'activities':
        return Icons.directions_run;
      case 'instruments':
        return Icons.music_note;
      default:
        return Icons.tag;
    }
  }

    // Get tag display name
  static String getTagDisplayName(String tag, {String Function(String)? l10n}) {
    // If l10n function is provided, use it for localization
    if (l10n != null) {
      return l10n(tag);
    }
    
    switch (tag) {
                     // Languages
         case 'lang_vietnamese':
           return 'Nhạc Việt';
         case 'lang_korean':
           return 'Kpop';
         case 'lang_english':
           return 'US-UK';
         case 'lang_japanese':
           return 'Jpop';
         case 'lang_latin':
           return 'Latin';
         case 'lang_chinese':
           return 'C-pop';
         case 'lang_thai':
           return 'Thái';
         case 'lang_indian':
           return 'Ấn Độ';
         case 'lang_arabic':
           return 'Ả Rập';
      
      // Tempos
      case 'tempo_slow':
        return 'Chậm';
      case 'tempo_medium':
        return 'Vừa phải';
      case 'tempo_fast':
        return 'Nhanh';
      case 'tempo_very_slow':
        return 'Rất chậm';
      case 'tempo_very_fast':
        return 'Rất nhanh';
      case 'tempo_variable':
        return 'Thay đổi';
      
      // Energy
      case 'energy_high':
        return 'Năng lượng cao';
      case 'energy_medium':
        return 'Năng lượng vừa';
      case 'energy_low':
        return 'Năng lượng thấp';
      case 'energy_upbeat':
        return 'Sôi động';
      case 'energy_chill':
        return 'Thư giãn';
      case 'energy_mellow':
        return 'Dịu dàng';
      case 'energy_intense':
        return 'Mạnh mẽ';
      case 'energy_relaxed':
        return 'Nhẹ nhàng';
      
      // Eras
      case 'era_80s':
        return 'Nhạc 80s';
      case 'era_90s':
        return 'Nhạc 90s';
      case 'era_2000s':
        return 'Nhạc 2000s';
      case 'era_2010s':
        return 'Nhạc 2010s';
      case 'era_2020s':
        return 'Nhạc 2020s';
      case 'era_modern':
        return 'Hiện đại';
      case 'era_classic':
        return 'Cổ điển';
      case 'era_vintage':
        return 'Vintage';
      case 'era_contemporary':
        return 'Đương đại';
      
      // Activities
      case 'activity_workout':
        return 'Tập gym';
      case 'activity_study':
        return 'Học tập';
      case 'activity_driving':
        return 'Lái xe';
      case 'activity_relaxation':
        return 'Thư giãn';
      case 'activity_party':
        return 'Tiệc tùng';
      case 'activity_sleep':
        return 'Ngủ';
      case 'activity_cooking':
        return 'Nấu ăn';
      case 'activity_cleaning':
        return 'Dọn dẹp';
      case 'activity_romance':
        return 'Lãng mạn';
      case 'activity_social':
        return 'Giao lưu';
      
      // Instruments
      case 'instrument_acoustic':
        return 'Acoustic';
      case 'instrument_electric':
        return 'Electric';
      case 'instrument_orchestral':
        return 'Orchestral';
      case 'instrument_lofi':
        return 'Lo-fi';
      case 'instrument_piano':
        return 'Piano';
      case 'instrument_guitar':
        return 'Guitar';
      case 'instrument_drums':
        return 'Drums';
      case 'instrument_synth':
        return 'Synth';
      case 'instrument_strings':
        return 'Strings';
      case 'instrument_brass':
        return 'Brass';
      
      default:
        return tag;
    }
  }

  // Check if tag is Vietnamese specific
  static bool isVietnameseTag(String tag) {
    return tag.startsWith('lang_vietnamese') ||
           tag.startsWith('region_') ||
           tag.startsWith('instrument_');
  }

  // Get Vietnamese specific tags
  static List<String> getVietnameseTags() {
    return [
      'lang_vietnamese',
    ];
  }
}
