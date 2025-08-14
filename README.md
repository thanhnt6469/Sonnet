# Sonnet - Music Genre Classification App

A Flutter app that classifies music genres using AI. Records audio, sends it to a Python API server for classification, and creates playlists on Spotify/Deezer.

## 🚀 Features

- 🎤 Record audio and classify music genres
- 🤖 AI-powered classification using TensorFlow Lite
- 🎵 Create playlists on Spotify and Deezer
- 🌐 Cross-platform (Android, iOS, Web)
- 🔧 Python API server for accurate classification

## 📱 Quick Start

### 1. Start API Server
```bash
cd Music_Genre_Classification
enable_firewall_new_ip.bat  # Run as Administrator
start_api_new_ip.bat
```

### 2. Run Flutter App
```bash
flutter pub get
flutter run
```

## 🔧 Setup

- **IP Configuration**: Update `lib/services/api_music_classification_service.dart` with your laptop's IP
- **Firewall**: Allow port 8000 for API server
- **Dependencies**: Install Python requirements in `Music_Genre_Classification/`

## 📁 Project Structure

```
sonnet/
├── lib/                    # Flutter app source
├── Music_Genre_Classification/  # Python API server
├── assets/                 # Images and models
└── android/ios/web/       # Platform-specific code
```

## 🎯 Usage

1. Record audio in the app
2. AI classifies the music genre
3. Choose Spotify or Deezer
4. Create playlist with similar songs

## 📋 Requirements

- Flutter 3.0+
- Python 3.8+
- TensorFlow Lite
- Spotify/Deezer API keys
