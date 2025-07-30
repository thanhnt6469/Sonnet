# Hệ thống Đa ngôn ngữ - Sonnet App

## Tổng quan
Ứng dụng Sonnet đã được tích hợp hệ thống đa ngôn ngữ hỗ trợ tiếng Việt và tiếng Anh.

## Cấu trúc thư mục
```
lib/
├── l10n/
│   └── app_localizations.dart      # File chính quản lý đa ngôn ngữ
├── providers/
│   └── language_provider.dart      # Provider quản lý thay đổi ngôn ngữ
├── widgets/
│   └── language_selector.dart      # Widget chọn ngôn ngữ
└── ...
```

## Cách sử dụng

### 1. Thêm text mới
Để thêm text mới, cập nhật file `lib/l10n/app_localizations.dart`:

```dart
static const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'new_text_key': 'English text here',
    // ... other texts
  },
  'vi': {
    'new_text_key': 'Text tiếng Việt ở đây',
    // ... other texts
  },
};
```

### 2. Sử dụng trong widget
```dart
import 'l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Text(l10n.get('text_key'));
  }
}
```

### 3. Thêm Language Selector
```dart
import 'widgets/language_selector.dart';

// Trong widget build
Align(
  alignment: Alignment.topRight,
  child: const LanguageSelector(),
),
```

## Các key đã có sẵn

### Home Screen
- `ai_curated_music`: Text mô tả ứng dụng
- `get_started_now`: Nút bắt đầu

### Prompt Screen
- `select_mood`: Chọn tâm trạng
- `select_genres`: Chọn thể loại nhạc
- `submit`: Nút xác nhận
- `please_select_mood_genre`: Thông báo lỗi
- `loading`: Đang tải
- `playlist_generated`: Danh sách nhạc đã tạo
- `no_songs_found`: Không tìm thấy bài hát
- `open_in_spotify`: Mở trong Spotify
- `open_in_audiomack`: Mở trong Audiomack
- `back_to_home`: Về trang chủ

### Moods
- `happy`: Vui vẻ
- `sad`: Buồn
- `energetic`: Năng động
- `relaxed`: Thư giãn
- `romantic`: Lãng mạn
- `anxious`: Lo lắng
- `grateful`: Biết ơn
- `heartbroken`: Đau khổ

### Genres
- `jazz`, `rock`, `amapiano`, `rnb`, `latin`, `hiphop`, `hiplife`, `reggae`, `gospel`, `afrobeat`, `blues`, `country`, `punk`, `pop`

## Lưu ý
- Ngôn ngữ được lưu tự động trong SharedPreferences
- Khi khởi động app, ngôn ngữ sẽ được khôi phục từ lần sử dụng trước
- Widget Language Selector hiển thị ở góc trên bên phải của mỗi màn hình 