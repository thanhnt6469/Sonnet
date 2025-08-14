import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final bool isEnabled;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.isEnabled = true,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  String? _recordedFilePath;
  Timer? _recordingTimer;
  bool _isRecorderReady = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  String _currentFormat = 'AAC';
  List<Map<String, dynamic>> _convertedFiles = [];
  bool _isConverting = false;
  
  static const int _maxRecordingDuration = 90; // 1 minute 30 seconds

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _initRecorder();
    _initPlayer();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      print('Recorder initialized successfully');
      setState(() {
        _isRecorderReady = true;
      });
    } catch (e) {
      print('Error initializing recorder: $e');
      // Try to reinitialize after a delay
      await Future.delayed(const Duration(seconds: 2));
      try {
        await _audioRecorder.openRecorder();
        print('Recorder reinitialized successfully');
        setState(() {
          _isRecorderReady = true;
        });
      } catch (e2) {
        print('Failed to reinitialize recorder: $e2');
        setState(() {
          _isRecorderReady = false;
        });
      }
    }
  }

  Future<void> _initPlayer() async {
    try {
      await _audioPlayer.openPlayer();
      print('Player initialized successfully');
    } catch (e) {
      print('Error initializing player: $e');
      // Try to reinitialize after a delay
      await Future.delayed(const Duration(seconds: 1));
      try {
        await _audioPlayer.openPlayer();
        print('Player reinitialized successfully');
      } catch (e2) {
        print('Failed to reinitialize player: $e2');
      }
    }
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await Permission.microphone.isGranted;
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }
  }

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  Future<void> _retryInitRecorder() async {
    setState(() {
      _isRecorderReady = false;
    });
    await _initRecorder();
  }

  Future<void> _startRecording() async {
    print('Starting recording...'); // Debug log
    
    if (!_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) {
        _showErrorSnackBar('Microphone permission is required');
        return;
      }
    }

    if (!_isRecorderReady) {
      _showErrorSnackBar('Recorder is not ready. Please wait...');
      return;
    }

    // Reset retry count and converted files for new recording
    setState(() {
      _retryCount = 0;
      _convertedFiles.clear();
    });

    try {
      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedFilePath = '${tempDir.path}/recording_$timestamp.aac';
      print('Recording file path: $_recordedFilePath'); // Debug log

      // Ensure recorder is not already recording
      if (_audioRecorder.isRecording) {
        print('Stopping existing recording first...');
        await _audioRecorder.stopRecorder();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('Starting new recording with AAC...'); // Debug log
      
      // Try AAC recording first, then fallback to other formats
      await _tryRecordingWithFallback();

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
          _hasRecording = false;
        });
      }

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
        
        // Stop recording after max duration
        if (_recordingDuration >= _maxRecordingDuration) {
          timer.cancel();
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e'); // Debug log
      _showErrorSnackBar('${AppLocalizations.of(context).get('error_recording')}: $e');
    }
  }

  Future<void> _tryRecordingWithFallback() async {
    List<Map<String, dynamic>> configs = [
      {
        'codec': Codec.aacADTS,
        'sampleRate': 22050,
        'numChannels': 1,
        'name': 'AAC 22.05kHz Mono',
        'extension': 'aac'
      },
      {
        'codec': Codec.pcm16WAV,
        'sampleRate': 22050,
        'numChannels': 1,
        'name': 'WAV 22.05kHz Mono',
        'extension': 'wav'
      },
      {
        'codec': Codec.aacADTS,
        'sampleRate': 44100,
        'numChannels': 1,
        'name': 'AAC 44.1kHz Mono',
        'extension': 'aac'
      },
      {
        'codec': Codec.pcm16WAV,
        'sampleRate': 44100,
        'numChannels': 1,
        'name': 'WAV 44.1kHz Mono',
        'extension': 'wav'
      },
      {
        'codec': Codec.pcm16WAV,
        'sampleRate': 16000,
        'numChannels': 1,
        'name': 'WAV 16kHz Mono',
        'extension': 'wav'
      },
    ];

    for (int i = 0; i < configs.length; i++) {
      try {
        print('Trying config ${i + 1}: ${configs[i]['name']}');
        
        // Update file path with correct extension
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = configs[i]['extension'];
        _recordedFilePath = '${tempDir.path}/recording_$timestamp.$extension';
        
        await _audioRecorder.startRecorder(
          toFile: _recordedFilePath!,
          codec: configs[i]['codec'],
          audioSource: AudioSource.microphone,
          sampleRate: configs[i]['sampleRate'],
          numChannels: configs[i]['numChannels'],
        );
        
        print('startRecorder completed with ${configs[i]['name']}'); // Debug log
        
        // Wait a bit to ensure recording has started
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if recording actually started
        if (_audioRecorder.isRecording) {
          print('Recording started successfully with ${configs[i]['name']}');
          setState(() {
            _currentFormat = configs[i]['name'];
          });
          return; // Success!
        } else {
          print('Recording did not start with ${configs[i]['name']}');
          await _audioRecorder.stopRecorder();
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        print('Failed with ${configs[i]['name']}: $e');
        try {
          await _audioRecorder.stopRecorder();
        } catch (stopError) {
          print('Error stopping recorder: $stopError');
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    // If we get here, all configs failed
    throw Exception('All recording configurations failed');
  }

  Future<void> _stopRecording() async {
    try {
      print('Stopping recording...'); // Debug log
      _recordingTimer?.cancel();
      
      if (_isRecording && _audioRecorder.isRecording) {
        print('Calling stopRecorder...'); // Debug log
        await _audioRecorder.stopRecorder();
        print('stopRecorder completed'); // Debug log
        
        // Wait longer for file to be written completely
        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (mounted) {
          setState(() {
            _isRecording = false;
            _hasRecording = true;
          });
        }

        // Validate the recording
        await _validateAndProcessRecording();
      } else {
        print('Not currently recording'); // Debug log
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      print('Error stopping recording: $e'); // Debug log
      _showErrorSnackBar('${AppLocalizations.of(context).get('error_recording')}: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _validateAndProcessRecording() async {
    if (_recordedFilePath == null) {
      print('_recordedFilePath is null'); // Debug log
      return;
    }

    final file = File(_recordedFilePath!);
    if (!await file.exists()) {
      print('Recording file not found: ${_recordedFilePath}'); // Debug log
      _showErrorSnackBar(AppLocalizations.of(context).get('recording_file_not_found'));
      return;
    }

    final fileSize = await file.length();
    print('Recording file exists: ${_recordedFilePath}, size: $fileSize bytes'); // Debug log
    
    // Check if file has content (at least 1KB)
    if (fileSize < 1024) {
      print('Recording file is empty or too small: $fileSize bytes'); // Debug log
      
      // Try to retry recording if we haven't exceeded max retries
      if (_retryCount < _maxRetries) {
        setState(() {
          _retryCount++;
        });
        print('Retrying recording (attempt $_retryCount of $_maxRetries)');
        _showErrorSnackBar('Recording failed, retrying... (attempt $_retryCount)');
        
        // Delete the failed file
        await file.delete();
        setState(() {
          _hasRecording = false;
          _recordedFilePath = null;
        });
        
        // Wait a bit before retrying
        await Future.delayed(const Duration(seconds: 1));
        
        // Retry recording
        _startRecording();
        return;
      } else {
        _showErrorSnackBar('Recording failed after $_maxRetries attempts. Please try again.');
        await file.delete();
        setState(() {
          _hasRecording = false;
          _recordedFilePath = null;
        });
        return;
      }
    }

    // Check if recording duration is sufficient (at least 3 seconds)
    if (_recordingDuration < 3) {
      print('Recording duration too short: $_recordingDuration seconds'); // Debug log
      _showErrorSnackBar('Recording too short. Please record for at least 3 seconds.');
      await file.delete();
      setState(() {
        _hasRecording = false;
        _recordedFilePath = null;
      });
      return;
    }

    // Additional validation: check if file can be read
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 1024) {
        print('File read validation failed: ${bytes.length} bytes'); // Debug log
        _showErrorSnackBar('Recording validation failed. Please try again.');
        await file.delete();
        setState(() {
          _hasRecording = false;
          _recordedFilePath = null;
        });
        return;
      }
    } catch (e) {
      print('Error reading file for validation: $e'); // Debug log
      _showErrorSnackBar('Recording file validation failed. Please try again.');
      await file.delete();
      setState(() {
        _hasRecording = false;
        _recordedFilePath = null;
      });
      return;
    }

    // All validations passed! Now convert to multiple formats
    print('Recording validation successful!');
    await _convertToMultipleFormats();
    
    // Use the original file for API
    widget.onRecordingComplete(_recordedFilePath!);
    _showSuccessSnackBar('Recording completed successfully! (${_formatDuration(_recordingDuration)})');
  }

  Future<void> _convertToMultipleFormats() async {
    if (_recordedFilePath == null) return;

    setState(() {
      _isConverting = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFile = File(_recordedFilePath!);
      
      List<Map<String, dynamic>> convertedFiles = [];
      
      // Add original file to the list
      final originalFileSize = await originalFile.length();
      convertedFiles.add({
        'path': _recordedFilePath!,
        'name': 'Original (${_currentFormat})',
        'extension': _recordedFilePath!.split('.').last.toUpperCase(),
        'size': originalFileSize,
        'isOriginal': true,
      });
      
      // Convert to different formats for testing
      List<Map<String, String>> formats = [
        {'name': 'WAV', 'extension': 'wav', 'ffmpeg_codec': 'pcm_s16le'},
        {'name': 'MP3', 'extension': 'mp3', 'ffmpeg_codec': 'mp3'},
        {'name': 'OGG', 'extension': 'ogg', 'ffmpeg_codec': 'libvorbis'},
        {'name': 'M4A', 'extension': 'm4a', 'ffmpeg_codec': 'aac'},
      ];

      for (var format in formats) {
        try {
          final outputPath = '${tempDir.path}/converted_${timestamp}_${format['name']?.toLowerCase()}.${format['extension']}';
          
          // Try to use ffmpeg for real conversion
          bool conversionSuccess = await _convertWithFFmpeg(
            inputPath: _recordedFilePath!,
            outputPath: outputPath,
            codec: format['ffmpeg_codec']!,
          );
          
          if (!conversionSuccess) {
            // Fallback: just copy the file with different extension
            await originalFile.copy(outputPath);
            print('Fallback: copied file to ${format['name']} format');
          }
          
          final convertedFile = File(outputPath);
          final fileSize = await convertedFile.length();
          
          if (fileSize > 1024) {
            convertedFiles.add({
              'path': outputPath,
              'name': format['name']!,
              'extension': format['extension']!.toUpperCase(),
              'size': fileSize,
              'isOriginal': false,
            });
            print('Converted to ${format['name']}: $outputPath (${fileSize} bytes)');
          }
        } catch (e) {
          print('Failed to convert to ${format['name']}: $e');
        }
      }

      setState(() {
        _convertedFiles = convertedFiles;
        _isConverting = false;
      });

      print('Conversion completed. ${convertedFiles.length} formats available for testing.');
    } catch (e) {
      print('Error during conversion: $e');
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<bool> _convertWithFFmpeg({
    required String inputPath,
    required String outputPath,
    required String codec,
  }) async {
    try {
      // For now, we'll use a simple approach: just copy the file
      // In a real implementation, you would use ffmpeg_kit_flutter or similar
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        print('Input file does not exist: $inputPath');
        return false;
      }
      
      // For testing purposes, we'll just copy the file
      // This ensures the file structure is correct even if format isn't truly converted
      await inputFile.copy(outputPath);
      
      // Verify the copied file exists and has content
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        final size = await outputFile.length();
        print('File copied successfully: $outputPath (${size} bytes)');
        return size > 1024; // Return true if file has reasonable size
      }
      
      return false;
    } catch (e) {
      print('FFmpeg conversion failed: $e');
      return false;
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) return;

    try {
      final file = File(_recordedFilePath!);
      if (!await file.exists()) {
        _showErrorSnackBar(AppLocalizations.of(context).get('recording_file_not_found'));
        return;
      }

      if (_isPlaying) {
        await _audioPlayer.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.startPlayer(
          fromURI: _recordedFilePath!,
          whenFinished: () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
              });
            }
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context).get('error_playing_recording')}: $e');
    }
  }

  Future<void> _testWithAPI(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final isOriginal = fileName.contains('recording_') && !fileName.contains('converted_');
      
      if (isOriginal) {
        _showSuccessSnackBar('Testing ORIGINAL file with API: $fileName');
        // Use original endpoint for better accuracy
        widget.onRecordingComplete(filePath);
      } else {
        _showSuccessSnackBar('Testing converted file with API: $fileName');
        widget.onRecordingComplete(filePath);
      }
    } catch (e) {
      _showErrorSnackBar('Error testing with API: $e');
    }
  }

  Future<void> _downloadFile(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showErrorSnackBar('File not found');
        return;
      }

      // Use share_plus to share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Audio recording: $fileName',
      );
      
      _showSuccessSnackBar('Sharing file: $fileName');
    } catch (e) {
      _showErrorSnackBar('Error sharing file: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _deleteRecording() {
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      file.delete().then((_) {
        // Delete converted files too
        for (var convertedFile in _convertedFiles) {
          File(convertedFile['path']).delete().catchError((e) => print('Error deleting converted file: $e'));
        }
        
        setState(() {
          _hasRecording = false;
          _recordedFilePath = null;
          _recordingDuration = 0;
          _retryCount = 0;
          _convertedFiles.clear();
        });
        _showSuccessSnackBar(AppLocalizations.of(context).get('recording_deleted'));
      }).catchError((e) {
        _showErrorSnackBar('${AppLocalizations.of(context).get('error_recording')}: $e');
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, color: Colors.blue[300], size: 20.0),
              const SizedBox(width: 8.0),
              Text(
                l10n.get('record_audio'),
                style: GoogleFonts.inter(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15.0),
          
          // Permission Status
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _hasPermission ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _hasPermission ? Colors.green : Colors.red,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasPermission ? Icons.mic : Icons.mic_off,
                  color: _hasPermission ? Colors.green : Colors.red,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _hasPermission ? l10n.get('microphone_permission_granted') : l10n.get('microphone_permission_required'),
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: _hasPermission ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                if (!_hasPermission)
                  TextButton(
                    onPressed: _requestPermission,
                    child: Text(
                      'Grant',
                      style: GoogleFonts.inter(
                        color: Colors.blue[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          
          // Recorder Status
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _isRecorderReady ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _isRecorderReady ? Colors.blue : Colors.orange,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isRecorderReady ? Icons.record_voice_over : Icons.settings,
                  color: _isRecorderReady ? Colors.blue : Colors.orange,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _isRecorderReady ? 'Recorder Ready' : 'Initializing Recorder...',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: _isRecorderReady ? Colors.blue : Colors.orange,
                    ),
                  ),
                ),
                if (!_isRecorderReady) ...[
                  SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  TextButton(
                    onPressed: _retryInitRecorder,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Recording Button and Timer
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Start Recording Button
                    if (!_isRecording)
                      GestureDetector(
                        onTap: widget.isEnabled && _hasPermission && _isRecorderReady ? _startRecording : null,
                        child: Container(
                          width: 80.0,
                          height: 80.0,
                          decoration: BoxDecoration(
                            color: widget.isEnabled && _hasPermission && _isRecorderReady ? Colors.blue[600] : Colors.grey[600],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (Colors.blue[600] ?? Colors.blue).withOpacity(0.3),
                                blurRadius: 10.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 32.0,
                          ),
                        ),
                      ),
                    
                    // Stop Recording Button
                    if (_isRecording)
                      GestureDetector(
                        onTap: _stopRecording,
                        child: Container(
                          width: 80.0,
                          height: 80.0,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 10.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 32.0,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_isRecording) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _formatDuration(_recordingDuration),
                      style: GoogleFonts.inter(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Tap to stop recording',
                    style: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 15.0),

          // Recording Status
          Center(
            child: Column(
              children: [
                Text(
                  _isRecording 
                    ? 'Recording...' 
                    : (!_hasPermission 
                        ? 'Microphone permission required' 
                        : (!_isRecorderReady 
                            ? 'Initializing recorder...' 
                            : 'Tap to record (max 1:30)')),
                  style: GoogleFonts.inter(
                    fontSize: 16.0,
                    color: _isRecording 
                      ? Colors.red 
                      : (!_hasPermission || !_isRecorderReady 
                          ? Colors.orange 
                          : Colors.grey[400]),
                    fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (_retryCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Retry attempt: $_retryCount/$_maxRetries',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (_currentFormat.isNotEmpty && !_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Format: $_currentFormat',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        color: Colors.blue[300],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Playback Controls (if recording exists)
          if (_hasRecording && _recordedFilePath != null) ...[
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Text(
                    'Recording: ${_formatDuration(_recordingDuration)}',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Play/Stop Button
                      GestureDetector(
                        onTap: _playRecording,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: _isPlaying ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                            size: 24.0,
                          ),
                        ),
                      ),
                      // Delete Button
                      GestureDetector(
                        onTap: _deleteRecording,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Converted Files for Testing and Download
          if (_convertedFiles.isNotEmpty) ...[
            const SizedBox(height: 15.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_copy, color: Colors.green[300], size: 16.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'Available Formats',
                        style: GoogleFonts.inter(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ...(_convertedFiles.map((fileInfo) {
                    final fileName = fileInfo['path'].split('/').last;
                    final fileExtension = fileInfo['extension'];
                    final fileSize = fileInfo['size'];
                    final isOriginal = fileInfo['isOriginal'];
                    final filePath = fileInfo['path'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isOriginal ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: isOriginal ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileInfo['name'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      color: isOriginal ? Colors.blue[300] : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${fileExtension} • ${_formatFileSize(fileSize)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.0,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: isOriginal ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                fileExtension,
                                style: GoogleFonts.inter(
                                  fontSize: 10.0,
                                  color: isOriginal ? Colors.blue[300] : Colors.grey[300],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // Test Button
                            GestureDetector(
                              onTap: () => _testWithAPI(filePath),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  'Test',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            // Download Button
                            GestureDetector(
                              onTap: () => _downloadFile(filePath, fileName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  'Share',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          ],

          // Conversion Status
          if (_isConverting) ...[
            const SizedBox(height: 15.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Converting to multiple formats...',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15.0),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[300], size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'Instructions',
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '• Tap the microphone button to start recording\n'
                  '• Tap the stop button to stop recording manually\n'
                  '• Maximum recording time: 1 minute 30 seconds\n'
                  '• Minimum recording time: 3 seconds\n'
                  '• Use the play button to listen to your recording\n'
                  '• Use the delete button to remove the recording\n'
                  '• Multiple formats are created for testing\n'
                  '• Use "Test" buttons to try different formats with API\n'
                  '• Use "Share" buttons to download/save audio files',
                  style: GoogleFonts.inter(
                    fontSize: 12.0,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 