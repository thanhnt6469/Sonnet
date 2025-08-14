import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/audio_classification_service.dart';
import '../services/audio_file_service.dart';
import '../widgets/audio_recorder_widget.dart';

import '../widgets/language_selector.dart';

class MusicGenreScreen extends StatefulWidget {
  const MusicGenreScreen({super.key});

  @override
  State<MusicGenreScreen> createState() => _MusicGenreScreenState();
}

class _MusicGenreScreenState extends State<MusicGenreScreen> {
  final AudioClassificationService _classificationService = AudioClassificationService();
  final AudioFileService _fileService = AudioFileService();
  
  String? _selectedFilePath;
  String? _fileName;
  String? _fileSize;
  String? _predictedGenre;
  double? _predictedConfidence;
  Map<String, double>? _otherScores;
  bool _isAnalyzing = false;
  bool _isModelLoaded = false;
  double _analysisProgress = 0.0;

  Color _bgColorForGenre(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return const Color(0xFF2C0A0A); // deep red
      case 'jazz':
        return const Color(0xFF1A0F2E); // deep purple
      case 'pop':
        return const Color(0xFF2A0F1E); // magenta tint
      case 'hiphop':
        return const Color(0xFF2E1A0F); // amber/brown tint
      case 'reggae':
        return const Color(0xFF0F2E1A); // deep green
      case 'blues':
        return const Color(0xFF0F1F3A); // deep blue
      case 'country':
        return const Color(0xFF2E2517); // earthy brown
      case 'classical':
        return const Color(0xFF181A1D); // neutral dark
      case 'metal':
        return const Color(0xFF121212); // near black
      case 'disco':
        return const Color(0xFF1D1030); // vibrant purple
      default:
        return const Color(0xFF1A1A1A); // fallback
    }
  }

  Color _accentColorForGenre(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return const Color(0xFFFF3B30); // red
      case 'jazz':
        return const Color(0xFF9B59B6); // purple
      case 'pop':
        return const Color(0xFFFF2D55); // pink/magenta
      case 'hiphop':
        return const Color(0xFFFFC107); // amber
      case 'reggae':
        return const Color(0xFF2ECC71); // green
      case 'blues':
        return const Color(0xFF3498DB); // blue
      case 'country':
        return const Color(0xFFD35400); // orange
      case 'classical':
        return const Color(0xFFBDC3C7); // silver
      case 'metal':
        return const Color(0xFF95A5A6); // grey
      case 'disco':
        return const Color(0xFF8E44AD); // vibrant purple
      default:
        return const Color(0xFF42A5F5); // blue fallback
    }
  }

  List<String> _getFeatureTagsForGenre(String genre, String Function(String) l10nText) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return [
          l10nText('feature_electric_guitar'),
          l10nText('feature_strong_drums'),
          l10nText('feature_energetic_vocal'),
          l10nText('feature_power_chords'),
        ];
      case 'metal':
        return [
          l10nText('feature_heavy_guitar'),
          l10nText('feature_aggressive_drums'),
          l10nText('feature_screaming_vocal'),
          l10nText('feature_distortion'),
        ];
      case 'jazz':
        return [
          l10nText('feature_saxophone'),
          l10nText('feature_piano'),
          l10nText('feature_swing_rhythm'),
          l10nText('feature_improvisation'),
        ];
      case 'blues':
        return [
          l10nText('feature_blues_guitar'),
          l10nText('feature_harmonica'),
          l10nText('feature_soulful_vocal'),
          l10nText('feature_12_bar_progression'),
        ];
      case 'country':
        return [
          l10nText('feature_acoustic_guitar'),
          l10nText('feature_fiddle'),
          l10nText('feature_storytelling'),
          l10nText('feature_twang'),
        ];
      case 'pop':
        return [
          l10nText('feature_catchy_melody'),
          l10nText('feature_electronic_beats'),
          l10nText('feature_polished_vocal'),
          l10nText('feature_synth'),
        ];
      case 'hiphop':
        return [
          l10nText('feature_rap_vocal'),
          l10nText('feature_strong_beats'),
          l10nText('feature_samples'),
          l10nText('feature_bass'),
        ];
      case 'reggae':
        return [
          l10nText('feature_offbeat_rhythm'),
          l10nText('feature_deep_bass'),
          l10nText('feature_laid_back_vocal'),
          l10nText('feature_organ'),
        ];
      case 'disco':
        return [
          l10nText('feature_dance_beats'),
          l10nText('feature_groovy_bass'),
          l10nText('feature_bright_synths'),
          l10nText('feature_funky_rhythm'),
        ];
      case 'classical':
        return [
          l10nText('feature_orchestra'),
          l10nText('feature_complex_composition'),
          l10nText('feature_dynamic_range'),
          l10nText('feature_acoustic_instruments'),
        ];
      default:
        return [
          l10nText('feature_high_energy'),
          l10nText('feature_strong_drums'),
          l10nText('feature_electric_guitar'),
        ];
    }
  }

  String _getFeatureDescription(String featureKey, String Function(String) l10nText) {
    // Map feature names to their description keys based on the original feature keys
    if (featureKey == l10nText('feature_electric_guitar')) {
      return l10nText('feature_electric_guitar_desc');
    } else if (featureKey == l10nText('feature_strong_drums')) {
      return l10nText('feature_strong_drums_desc');
    } else if (featureKey == l10nText('feature_energetic_vocal')) {
      return l10nText('feature_energetic_vocal_desc');
    } else if (featureKey == l10nText('feature_power_chords')) {
      return l10nText('feature_power_chords_desc');
    } else if (featureKey == l10nText('feature_heavy_guitar')) {
      return l10nText('feature_heavy_guitar_desc');
    } else if (featureKey == l10nText('feature_aggressive_drums')) {
      return l10nText('feature_aggressive_drums_desc');
    } else if (featureKey == l10nText('feature_screaming_vocal')) {
      return l10nText('feature_screaming_vocal_desc');
    } else if (featureKey == l10nText('feature_distortion')) {
      return l10nText('feature_distortion_desc');
    } else if (featureKey == l10nText('feature_saxophone')) {
      return l10nText('feature_saxophone_desc');
    } else if (featureKey == l10nText('feature_piano')) {
      return l10nText('feature_piano_desc');
    } else if (featureKey == l10nText('feature_swing_rhythm')) {
      return l10nText('feature_swing_rhythm_desc');
    } else if (featureKey == l10nText('feature_improvisation')) {
      return l10nText('feature_improvisation_desc');
    } else if (featureKey == l10nText('feature_blues_guitar')) {
      return l10nText('feature_blues_guitar_desc');
    } else if (featureKey == l10nText('feature_harmonica')) {
      return l10nText('feature_harmonica_desc');
    } else if (featureKey == l10nText('feature_soulful_vocal')) {
      return l10nText('feature_soulful_vocal_desc');
    } else if (featureKey == l10nText('feature_12_bar_progression')) {
      return l10nText('feature_12_bar_progression_desc');
    } else if (featureKey == l10nText('feature_acoustic_guitar')) {
      return l10nText('feature_acoustic_guitar_desc');
    } else if (featureKey == l10nText('feature_fiddle')) {
      return l10nText('feature_fiddle_desc');
    } else if (featureKey == l10nText('feature_storytelling')) {
      return l10nText('feature_storytelling_desc');
    } else if (featureKey == l10nText('feature_twang')) {
      return l10nText('feature_twang_desc');
    } else if (featureKey == l10nText('feature_catchy_melody')) {
      return l10nText('feature_catchy_melody_desc');
    } else if (featureKey == l10nText('feature_electronic_beats')) {
      return l10nText('feature_electronic_beats_desc');
    } else if (featureKey == l10nText('feature_polished_vocal')) {
      return l10nText('feature_polished_vocal_desc');
    } else if (featureKey == l10nText('feature_synth')) {
      return l10nText('feature_synth_desc');
    } else if (featureKey == l10nText('feature_rap_vocal')) {
      return l10nText('feature_rap_vocal_desc');
    } else if (featureKey == l10nText('feature_strong_beats')) {
      return l10nText('feature_strong_beats_desc');
    } else if (featureKey == l10nText('feature_samples')) {
      return l10nText('feature_samples_desc');
    } else if (featureKey == l10nText('feature_bass')) {
      return l10nText('feature_bass_desc');
    } else if (featureKey == l10nText('feature_offbeat_rhythm')) {
      return l10nText('feature_offbeat_rhythm_desc');
    } else if (featureKey == l10nText('feature_deep_bass')) {
      return l10nText('feature_deep_bass_desc');
    } else if (featureKey == l10nText('feature_laid_back_vocal')) {
      return l10nText('feature_laid_back_vocal_desc');
    } else if (featureKey == l10nText('feature_organ')) {
      return l10nText('feature_organ_desc');
    } else if (featureKey == l10nText('feature_dance_beats')) {
      return l10nText('feature_dance_beats_desc');
    } else if (featureKey == l10nText('feature_groovy_bass')) {
      return l10nText('feature_groovy_bass_desc');
    } else if (featureKey == l10nText('feature_bright_synths')) {
      return l10nText('feature_bright_synths_desc');
    } else if (featureKey == l10nText('feature_funky_rhythm')) {
      return l10nText('feature_funky_rhythm_desc');
    } else if (featureKey == l10nText('feature_orchestra')) {
      return l10nText('feature_orchestra_desc');
    } else if (featureKey == l10nText('feature_complex_composition')) {
      return l10nText('feature_complex_composition_desc');
    } else if (featureKey == l10nText('feature_dynamic_range')) {
      return l10nText('feature_dynamic_range_desc');
    } else if (featureKey == l10nText('feature_acoustic_instruments')) {
      return l10nText('feature_acoustic_instruments_desc');
    } else if (featureKey == l10nText('feature_high_energy')) {
      return 'Mô tả về năng lượng cao trong âm nhạc';
    } else {
      return 'Mô tả chi tiết về đặc trưng âm nhạc này';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Widget _buildResultCard(BuildContext context) {
    final genreTitle = _predictedGenre ?? '';
    final primaryColor = _bgColorForGenre(genreTitle);
    final accentColor = _accentColorForGenre(genreTitle);
    final Color gradientEnd = Color.lerp(primaryColor, accentColor, 0.35) ?? primaryColor;
    final confidencePct = _predictedConfidence != null ? (_predictedConfidence! * 100).toStringAsFixed(1) : '—';
    final description = AppLocalizations.of(context).get(
      'desc_${_predictedGenre!.toLowerCase()}',
    );
    final l10nText = (String key) => AppLocalizations.of(context).get(key);

    // Other genres sorted by confidence, excluding the main predicted genre
    final otherEntries = (_otherScores ?? {}).entries
        .where((e) => e.key != _predictedGenre)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // Sort by confidence descending
    
    final topOther = otherEntries.take(3).toList();
    final totalScore = (_otherScores == null || _otherScores!.isEmpty)
        ? 1.0
        : _otherScores!.values.reduce((a, b) => a + b);

    // Get feature tags based on predicted genre
    final featureTags = _getFeatureTagsForGenre(_predictedGenre ?? '', l10nText);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: accentColor.withOpacity(0.28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.18),
            blurRadius: 24.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genreTitle,
                      style: GoogleFonts.inter(
                        fontSize: 26.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          '${l10nText('confidence')}: $confidencePct%',
                          style: GoogleFonts.inter(
                            fontSize: 13.0,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Transform.translate(
                          offset: const Offset(0, -25),
                           child: Icon(Icons.info_outline, color: Colors.white.withOpacity(0.9), size: 20.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16.0,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            l10nText('features'),
            style: GoogleFonts.inter(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: featureTags.map((tag) {
              return Tooltip(
                message: _getFeatureDescription(tag, l10nText),
                preferBelow: true,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), // Semi-transparent white background
                    borderRadius: BorderRadius.circular(22.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2), // Subtle white border
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18.0),
          Text(
            l10nText('other_genres'),
            style: GoogleFonts.inter(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12.0),
          ...topOther.map((e) {
            final percent = totalScore > 0 ? (e.value / totalScore) : 0.0;
            final pctText = '${(percent * 100).toStringAsFixed(1)}%';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        pctText,
                        style: GoogleFonts.inter(
                          fontSize: 13.0,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0.0, 1.0),
                      minHeight: 14.0,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.95)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _loadModel() async {
    try {
      await _classificationService.loadModel();
      if (mounted) {
        setState(() {
          _isModelLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      // Clear previous cached files from FilePicker to avoid resource pressure
      await _fileService.clearCachedFiles();
      String? filePath = await _fileService.pickAudioFile();
      if (filePath != null) {
        bool isValidAudio = await _fileService.isAudioFile(filePath);
        if (isValidAudio) {
          String fileName = await _fileService.getFileName(filePath);
          int fileSize = await _fileService.getFileSize(filePath);
          String formattedSize = _fileService.formatFileSize(fileSize);

          if (mounted) {
            setState(() {
              _selectedFilePath = filePath;
              _fileName = fileName;
              _fileSize = formattedSize;
              _predictedGenre = null;
              _analysisProgress = 0.0;
            });
          }
        } else {
          _showErrorSnackBar(AppLocalizations.of(context).get('invalid_audio_file'));
        }
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context).get('error_picking_file')}: $e');
    }
  }

  Future<void> _onRecordingComplete(String filePath) async {
    try {
      // Get file information
      String fileName = await _fileService.getFileName(filePath);
      int fileSize = await _fileService.getFileSize(filePath);
      String formattedSize = _fileService.formatFileSize(fileSize);

      if (mounted) {
        setState(() {
          _selectedFilePath = filePath;
          _fileName = fileName;
          _fileSize = formattedSize;
          _predictedGenre = null;
          _analysisProgress = 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('recording_completed')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeAudio() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar(AppLocalizations.of(context).get('please_select_audio'));
      return;
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = true;
        _predictedGenre = null;
        _analysisProgress = 0.0;
      });
    }

    try {
      // Small delay to allow UI settle and GC between runs
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Start progress animation
      _startProgressAnimation();
      
      final detailed = await _classificationService.classifyAudioDetailed(_selectedFilePath!);
      
      // Build scores map for all genres
      final scores = <String, double>{};
      for (int i = 0; i < _classificationService.getAvailableGenres().length; i++) {
        scores[_classificationService.getAvailableGenres()[i]] = detailed.weightedScores[i];
      }
      
      // Sort by confidence descending - highest confidence should be the main result
      final sortedEntries = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Main genre is the one with highest confidence, not detailed.index
      final predictedGenre = sortedEntries.first.key;
      final maxScore = sortedEntries.first.value;
      final totalScore = detailed.weightedScores.reduce((a, b) => a + b);
      final confidence = totalScore > 0 ? (maxScore / totalScore).clamp(0.0, 1.0) : 0.0;

      if (mounted) {
        setState(() {
          _predictedGenre = predictedGenre;
          _predictedConfidence = confidence;
          _otherScores = Map.fromEntries(sortedEntries);
          _isAnalyzing = false;
          _analysisProgress = 1.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisProgress = 0.0;
        });
      }
      _showErrorSnackBar('${AppLocalizations.of(context).get('error_analyzing_audio')}: $e');
    }
  }

  void _startProgressAnimation() {
    const updateInterval = Duration(milliseconds: 100);
    const steps = 14; // 1400ms / 100ms = 14 steps
    
    int currentStep = 0;
    
    Timer.periodic(updateInterval, (timer) {
      if (!_isAnalyzing || !mounted) {
        timer.cancel();
        return;
      }
      
      currentStep++;
      final progress = currentStep / steps;
      
      if (mounted) {
        setState(() {
          _analysisProgress = progress.clamp(0.0, 0.9); // Keep at 90% until complete
        });
      }
      
      if (currentStep >= steps) {
        timer.cancel();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final l10nTitle = l10n.get('music_genre_analysis');
    final l10nSubtitle = l10n.get('upload_or_record_desc');
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with language selector
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10nTitle,
                      style: GoogleFonts.inter(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const LanguageSelector(),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                l10nSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 16.0,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 25.0),

              // Model Status
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _isModelLoaded ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _isModelLoaded ? Colors.green : Colors.orange,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isModelLoaded ? Icons.check_circle : Icons.warning,
                      color: _isModelLoaded ? Colors.green : Colors.orange,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _isModelLoaded ? l10n.get('model_loaded_successfully') : l10n.get('loading_model'),
                        style: GoogleFonts.inter(
                          fontSize: 14.0,
                          color: _isModelLoaded ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25.0),

              // Audio Input Section - Single Column Layout
              Column(
                children: [
                  // Record Audio Section
                  AudioRecorderWidget(
                    onRecordingComplete: _onRecordingComplete,
                    isEnabled: !_isAnalyzing,
                  ),
                  const SizedBox(height: 20.0),

                  // Upload Audio File Section
                  Container(
                    width: double.infinity,
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
                            Icon(Icons.upload_file, color: Colors.green[300], size: 20.0),
                            const SizedBox(width: 8.0),
                            Text(
                              l10n.get('upload_audio_file'),
                              style: GoogleFonts.inter(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15.0),
                        
                        if (_selectedFilePath != null) ...[
                          // File Info
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
                                    Icon(Icons.audio_file, color: Colors.blue[300]),
                                    const SizedBox(width: 8.0),
              Expanded(
                                      child: Text(
                                         _fileName ?? l10n.get('unknown_file'),
                                        style: GoogleFonts.inter(
                                          fontSize: 14.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  '${l10n.get('size')}: ${_fileSize ?? l10n.get('unknown_file')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.0,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15.0),
                        ],

                        // Action Buttons
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isAnalyzing ? null : _pickAudioFile,
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _selectedFilePath == null ? l10n.get('select_audio_file') : l10n.get('change_file'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedFilePath != null) ...[
                              const SizedBox(height: 12.0),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isAnalyzing ? null : _analyzeAudio,
                                  icon: _isAnalyzing 
                                    ? const SizedBox(
                                        width: 16.0,
                                        height: 16.0,
                                        child: CircularProgressIndicator(strokeWidth: 2.0),
                                      )
                                    : const Icon(Icons.analytics),
                                  label: Text(
                                     _isAnalyzing ? l10n.get('analyzing') : l10n.get('analyze'),
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25.0),

              // Progress Bar (when analyzing)
              if (_isAnalyzing) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue[300], size: 20.0),
                          const SizedBox(width: 8.0),
                          Text(
                             l10n.get('analyzing_audio'),
                            style: GoogleFonts.inter(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      LinearProgressIndicator(
                        value: _analysisProgress,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '${(_analysisProgress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
              ],

              // Results Section
              if (_predictedGenre != null) ...[
                _buildResultCard(context),
                const SizedBox(height: 20.0),
              ],

              // Available Genres
              Text(
                l10n.get('supported_genres'),
                style: GoogleFonts.inter(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _classificationService.getAvailableGenres().map((genre) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Text(
                      genre,
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        color: Colors.grey[300],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20.0), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classificationService.dispose();
    super.dispose();
  }
} 