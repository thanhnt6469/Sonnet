import '../models/music_tags.dart';

class PromptGeneratorService {
  static String generatePrompt({
    required Set<String> selectedTags,
    String? customPrompt,
  }) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = (currentTime % 1000).toString();
    
    // Phân loại tags
    final moods = _getTagsByCategory(selectedTags, 'moods');
    final internationalGenres = _getTagsByCategory(selectedTags, 'international_genres');
    final vietnameseGenres = _getTagsByCategory(selectedTags, 'vietnamese_genres');
    final tempos = _getTagsByCategory(selectedTags, 'tempos');
    final regions = _getTagsByCategory(selectedTags, 'regions');
    final eras = _getTagsByCategory(selectedTags, 'eras');
    final languages = _getTagsByCategory(selectedTags, 'languages');
    final instruments = _getTagsByCategory(selectedTags, 'instruments');
    final themes = _getTagsByCategory(selectedTags, 'themes');
    
    // Tạo prompt
    final promptText = '''Create a music playlist based on the following detailed criteria:

${_buildCriteriaSection('Mood', moods)}
${_buildCriteriaSection('International Genres', internationalGenres)}
${_buildCriteriaSection('Vietnamese Genres', vietnameseGenres)}
${_buildCriteriaSection('Tempo', tempos)}
${_buildCriteriaSection('Region', regions)}
${_buildCriteriaSection('Era', eras)}
${_buildCriteriaSection('Language', languages)}
${_buildCriteriaSection('Instruments', instruments)}
${_buildCriteriaSection('Themes', themes)}

${customPrompt ?? ''}

IMPORTANT: Provide exactly 10 songs in this exact format:
Artist Name - Song Title

Rules:
- One song per line
- No numbering (1., 2., etc.)
- Use "Artist Name - Song Title" format only
- Focus on popular and well-known songs
- Include diverse artists
- Avoid repeating the same songs
- Ensure both artist and title are clearly specified
- Be creative and diverse in song selection
- Consider different eras and styles within the genre
- If Vietnamese genres are selected, prioritize Vietnamese artists and songs
- Consider the mood and emotional context when selecting songs
- Include both classic and contemporary songs when appropriate
- Pay attention to regional and cultural context
- Consider the specified tempo and instruments
- Match the thematic elements when possible

Example format:
Alicia Keys - Fallin'
Usher - Burn
Toni Braxton - Un-Break My Heart

Random seed: $randomSeed
Current time: $currentTime

Please provide a fresh and diverse selection of songs that match the specified criteria.''';

    return promptText;
  }

  static String _buildCriteriaSection(String title, List<String> tags) {
    if (tags.isEmpty) return '';
    return '$title: ${tags.join(', ')}';
  }

  static List<String> _getTagsByCategory(Set<String> selectedTags, String category) {
    final categoryTags = MusicTags.getTagsByCategory(category);
    return selectedTags.where((tag) => categoryTags.contains(tag)).toList();
  }

  static String generateVietnamesePrompt({
    required Set<String> selectedTags,
    String? customPrompt,
  }) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = (currentTime % 1000).toString();
    
    // Phân loại tags
    final moods = _getTagsByCategory(selectedTags, 'moods');
    final vietnameseGenres = _getTagsByCategory(selectedTags, 'vietnamese_genres');
    final regions = _getTagsByCategory(selectedTags, 'regions');
    final instruments = _getTagsByCategory(selectedTags, 'instruments');
    final themes = _getTagsByCategory(selectedTags, 'themes');
    
    // Tạo prompt tiếng Việt
    final promptText = '''Tạo danh sách nhạc dựa trên các tiêu chí sau:

${_buildVietnameseCriteriaSection('Tâm Trạng', moods)}
${_buildVietnameseCriteriaSection('Thể Loại Việt Nam', vietnameseGenres)}
${_buildVietnameseCriteriaSection('Vùng Miền', regions)}
${_buildVietnameseCriteriaSection('Nhạc Cụ', instruments)}
${_buildVietnameseCriteriaSection('Chủ Đề', themes)}

${customPrompt ?? ''}

QUAN TRỌNG: Cung cấp chính xác 10 bài hát theo định dạng này:
Tên Nghệ Sĩ - Tên Bài Hát

Quy tắc:
- Một bài hát mỗi dòng
- Không đánh số (1., 2., etc.)
- Chỉ sử dụng định dạng "Tên Nghệ Sĩ - Tên Bài Hát"
- Tập trung vào các bài hát phổ biến và nổi tiếng
- Bao gồm nhiều nghệ sĩ đa dạng
- Tránh lặp lại các bài hát
- Đảm bảo cả nghệ sĩ và tên bài hát được chỉ định rõ ràng
- Sáng tạo và đa dạng trong việc lựa chọn bài hát
- Ưu tiên nghệ sĩ và bài hát Việt Nam
- Cân nhắc tâm trạng và bối cảnh cảm xúc khi chọn bài hát
- Bao gồm cả bài hát cổ điển và đương đại khi phù hợp
- Chú ý đến bối cảnh vùng miền và văn hóa
- Phù hợp với nhịp độ và nhạc cụ được chỉ định
- Phù hợp với các yếu tố chủ đề khi có thể

Ví dụ định dạng:
Sơn Tùng M-TP - Lạc Trôi
Đen Vâu - Đưa Nhau Đi Trốn
Min - Tìm
Hồ Ngọc Hà - Người Tình Mùa Đông

Random seed: $randomSeed
Current time: $currentTime

Vui lòng cung cấp một lựa chọn bài hát tươi mới và đa dạng phù hợp với các tiêu chí đã chỉ định.''';

    return promptText;
  }

  static String _buildVietnameseCriteriaSection(String title, List<String> tags) {
    if (tags.isEmpty) return '';
    return '$title: ${tags.join(', ')}';
  }

  static bool hasVietnameseContent(Set<String> selectedTags) {
    return selectedTags.any((tag) => MusicTags.isVietnameseTag(tag));
  }

  static String getPromptType(Set<String> selectedTags) {
    if (hasVietnameseContent(selectedTags)) {
      return 'vietnamese';
    }
    return 'international';
  }
}
