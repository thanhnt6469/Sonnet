import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioFileService {
  Future<void> clearCachedFiles() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}
  }
  Future<bool> _ensurePermissionsIfNeeded() async {
    // Tối ưu: FilePicker dùng SAF nên thường không cần quyền Storage.
    // Tuy nhiên trên Android 13+ có READ_MEDIA_AUDIO; ta yêu cầu mềm (không chặn luồng nếu từ chối).
    if (Platform.isAndroid) {
      try {
        final statuses = await [
          // READ_MEDIA_AUDIO (Android 13+)
          Permission.audio,
          // Fallback cho Android < 13 nếu OEM yêu cầu quyền lưu trữ cũ
          Permission.storage,
        ].request();

        final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
        final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
        return audioGranted || storageGranted;
      } catch (_) {
        // Không fail nếu không thể yêu cầu quyền; vẫn cho phép pick file qua SAF
        return false;
      }
    }
    return true;
  }

  Future<String?> pickAudioFile() async {
    try {
      // Không chặn chọn file nếu chưa cấp quyền; SAF thường hoạt động không cần quyền.
      await _ensurePermissionsIfNeeded();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final String? filePath = pickedFile.path;
        if (filePath != null && filePath.isNotEmpty) {
          print('Selected audio file: $filePath');
          return filePath;
        }
      }

      return null;
    } catch (e) {
      // Nếu lỗi liên quan quyền, thử yêu cầu rồi thử lại một lần
      try {
        final granted = await _ensurePermissionsIfNeeded();
        if (granted) {
          final retry = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowMultiple: false,
            allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
          );
          if (retry != null && retry.files.isNotEmpty) {
            final retryPath = retry.files.first.path;
            if (retryPath != null) return retryPath;
          }
        }
      } catch (_) {}

      print('Error picking audio file: $e');
      rethrow;
    }
  }

  Future<bool> isAudioFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) return false;

      String extension = filePath.split('.').last.toLowerCase();
      List<String> supportedExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg'];
      
      return supportedExtensions.contains(extension);
    } catch (e) {
      print('Error checking audio file: $e');
      return false;
    }
  }

  Future<String> getFileName(String filePath) async {
    try {
      File file = File(filePath);
      return file.path.split('/').last;
    } catch (e) {
      return 'Unknown file';
    }
  }

  Future<int> getFileSize(String filePath) async {
    try {
      File file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 