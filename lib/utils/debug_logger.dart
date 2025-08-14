import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DebugLogger {
  static void logPlaylistSearch(BuildContext context, String playlistName) {
    final l10n = AppLocalizations.of(context);
    print('🔍 ${l10n.get('debug_playlist_search')}: "$playlistName"');
  }

  static void logPlaylistFound(BuildContext context, String playlistName, String playlistId) {
    final l10n = AppLocalizations.of(context);
    print('✅ ${l10n.get('debug_playlist_found')}: "$playlistName" (ID: $playlistId)');
  }

  static void logPlaylistNotFound(BuildContext context, String playlistName) {
    final l10n = AppLocalizations.of(context);
    print('❌ ${l10n.get('debug_playlist_not_found')}: "$playlistName"');
  }

  static void logCreatingNewPlaylist(BuildContext context, String playlistName) {
    final l10n = AppLocalizations.of(context);
    print('🆕 ${l10n.get('debug_creating_new_playlist')}: "$playlistName"');
  }

  static void logMergingPlaylist(BuildContext context, String playlistName) {
    final l10n = AppLocalizations.of(context);
    print('🔄 ${l10n.get('debug_merging_playlist')}: "$playlistName"');
  }

  static void logAddingTrack(BuildContext context, String trackName, String artistName) {
    final l10n = AppLocalizations.of(context);
    print('➕ ${l10n.get('debug_adding_track')}: $trackName - $artistName');
  }

  static void logSkippingDuplicate(BuildContext context, String trackName, String artistName) {
    final l10n = AppLocalizations.of(context);
    print('⏭️ ${l10n.get('debug_skipping_duplicate')}: $trackName - $artistName');
  }

  static void logTracksAdded(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context);
    print('📤 ${l10n.get('debug_tracks_added')}: $count tracks');
  }

  static void logNoNewTracks(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    print('ℹ️ ${l10n.get('debug_no_new_tracks')}');
  }

  static void logPlaylistCreationSuccess(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    print('✅ ${l10n.get('debug_playlist_creation_success')}');
  }

  static void logPlaylistMergeSuccess(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    print('✅ ${l10n.get('debug_playlist_merge_success')}');
  }

  // Generic logging methods
  static void logInfo(String message) {
    print('ℹ️ $message');
  }

  static void logSuccess(String message) {
    print('✅ $message');
  }

  static void logWarning(String message) {
    print('⚠️ $message');
  }

  static void logError(String message) {
    print('❌ $message');
  }

  static void logDebug(String message) {
    print('�� $message');
  }
}
