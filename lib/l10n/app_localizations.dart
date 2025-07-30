import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Home Screen
      'ai_curated_music': 'AI curated music playlist just for your mood',
      'get_started_now': 'Get Started Now!',
      
      // Prompt Screen
      'select_mood': 'Select Your Mood',
      'select_genres': 'Select Your Genres',
      'submit': 'Submit',
      'please_select_mood_genre': 'Please select a mood and at least one genre',
      'loading': 'Loading...',
      'playlist_generated': 'Playlist Generated',
      'no_songs_found': 'No songs found',
      'open_in_spotify': 'Open in Spotify',
      'open_in_audiomack': 'Open in Audiomack',
      'back_to_home': 'Back to Home',
      
      // Error Messages
      'api_quota_exceeded': 'OpenAI API quota exceeded. Please check your billing and try again later.',
      'invalid_api_key': 'Invalid API key. Please check your OpenAI API configuration.',
      'rate_limit_exceeded': 'Rate limit exceeded. Please wait a moment and try again.',
      'api_not_configured': 'OpenAI API not configured. Please check your .env file.',
      'network_error': 'Network error. Please check your internet connection.',
      'unexpected_error': 'An unexpected error occurred. Please try again.',
      
      // Moods
      'happy': 'Happy',
      'sad': 'Sad',
      'energetic': 'Energetic',
      'relaxed': 'Relaxed',
      'romantic': 'Romantic',
      'anxious': 'Anxious',
      'grateful': 'Grateful',
      'heartbroken': 'Heartbroken',
      
      // Genres
      'jazz': 'Jazz',
      'rock': 'Rock',
      'amapiano': 'Amapiano',
      'rnb': 'R&B',
      'latin': 'Latin',
      'hiphop': 'Hip-Hop',
      'hiplife': 'Hip-Life',
      'reggae': 'Reggae',
      'gospel': 'Gospel',
      'afrobeat': 'Afrobeat',
      'blues': 'Blues',
      'country': 'Country',
      'punk': 'Punk',
      'pop': 'Pop',
    },
    'vi': {
      // Home Screen
      'ai_curated_music': 'AI hiểu bạn, chọn nhạc hợp tâm trạng',
      'get_started_now': 'Bắt Đầu Ngay!',
      
      // Prompt Screen
      'select_mood': 'Chọn Tâm Trạng Của Bạn',
      'select_genres': 'Chọn Thể Loại Nhạc',
      'submit': 'Xác Nhận',
      'please_select_mood_genre': 'Vui lòng chọn tâm trạng và ít nhất một thể loại nhạc',
      'loading': 'Đang tải...',
      'playlist_generated': 'Đã Tạo Danh Sách Nhạc',
      'no_songs_found': 'Không tìm thấy bài hát nào',
      'open_in_spotify': 'Mở trong Spotify',
      'open_in_audiomack': 'Mở trong Audiomack',
      'back_to_home': 'Về Trang Chủ',
      
      // Error Messages
      'api_quota_exceeded': 'Đã vượt quá hạn mức API OpenAI. Vui lòng kiểm tra hóa đơn và thử lại sau.',
      'invalid_api_key': 'Khóa API không hợp lệ. Vui lòng kiểm tra cấu hình OpenAI API.',
      'rate_limit_exceeded': 'Vượt quá giới hạn tốc độ. Vui lòng đợi một lúc và thử lại.',
      'api_not_configured': 'OpenAI API chưa được cấu hình. Vui lòng kiểm tra file .env.',
      'network_error': 'Lỗi mạng. Vui lòng kiểm tra kết nối internet.',
      'unexpected_error': 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
      
      // Moods
      'happy': 'Vui Vẻ',
      'sad': 'Buồn',
      'energetic': 'Năng Động',
      'relaxed': 'Thư Giãn',
      'romantic': 'Lãng Mạn',
      'anxious': 'Lo Lắng',
      'grateful': 'Biết Ơn',
      'heartbroken': 'Đau Khổ',
      
      // Genres
      'jazz': 'Jazz',
      'rock': 'Rock',
      'amapiano': 'Amapiano',
      'rnb': 'R&B',
      'latin': 'Latin',
      'hiphop': 'Hip-Hop',
      'hiplife': 'Hip-Life',
      'reggae': 'Reggae',
      'gospel': 'Gospel',
      'afrobeat': 'Afrobeat',
      'blues': 'Blues',
      'country': 'Country',
      'punk': 'Punk',
      'pop': 'Pop',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 