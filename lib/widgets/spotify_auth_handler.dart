import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/spotify_service.dart';
import '../services/spotify_callback_server.dart';
import '../l10n/app_localizations.dart';
import 'spotify_webview.dart';

class SpotifyAuthHandler extends StatefulWidget {
  final SpotifyService spotifyService;
  final Function(bool success) onAuthComplete;

  const SpotifyAuthHandler({
    super.key,
    required this.spotifyService,
    required this.onAuthComplete,
  });

  @override
  State<SpotifyAuthHandler> createState() => _SpotifyAuthHandlerState();
}

class _SpotifyAuthHandlerState extends State<SpotifyAuthHandler> {
  bool _isAuthenticating = false;
  final SpotifyCallbackServer _callbackServer = SpotifyCallbackServer();

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1DB954)),
            SizedBox(width: 8),
            Text('Authorization Code Captured!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your authorization code has been automatically captured:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authorization Code:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The code has been automatically captured from the callback URL.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAuthComplete(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exchangeCode(code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Authorization'),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithSpotify() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      // Launch Spotify authorization
      final authUrl = widget.spotifyService.getAuthorizationUrl();
      print('🎵 Spotify Auth URL: $authUrl');
      print('🔗 Full authorization URL: $authUrl');
      
      // Show custom webview for better URL tracking
      print('📱 Opening custom webview for Spotify authorization...');
      await _showCustomWebView(authUrl);
      
    } catch (e) {
      print('💥 Error during authentication: $e');
      _showErrorDialog('Authentication error: $e');
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _showCustomWebView(String authUrl) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpotifyWebView(
          initialUrl: authUrl,
          onUrlChanged: (String url) {
            print('🔄 WebView URL changed: $url');
          },
          onCodeReceived: (String code) async {
            print('🎉 Authorization code received from webview: $code');
            Navigator.of(context).pop(); // Close webview
            await _exchangeCode(code);
          },
        ),
      ),
    );
  }

  void _showWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Waiting for Authorization'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please complete the Spotify authorization in your browser.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'After you click "Agree", you will be redirected back to the app automatically.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualCodeInputDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1DB954),
                Color(0xFF1ed760),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Authorization Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Follow these steps:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Complete Spotify authorization in your browser',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      '2. You\'ll be redirected to a URL like:',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'http://127.0.0.1:8888/?code=YOUR_CODE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3. Copy the code (after "code=") and paste below',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Code Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    hintText: 'Paste your authorization code here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.security,
                      color: Color(0xFF1DB954),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isAuthenticating = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final code = codeController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.of(context).pop();
                          await _exchangeCode(code);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text('Please enter the authorization code'),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1DB954),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exchangeCode(String code) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final success = await widget.spotifyService.exchangeCodeForToken(code);
      
      if (success) {
        // Close any open dialogs first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Show success message briefly then continue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('connected_to_spotify')),
            backgroundColor: const Color(0xFF1DB954),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Notify parent that auth is complete
        widget.onAuthComplete(true);
      } else {
        _showErrorDialog('Failed to authenticate with Spotify');
        widget.onAuthComplete(false);
      }
    } catch (e) {
      print('Error exchanging code: $e');
      _showErrorDialog('Authentication failed: ${e.toString()}');
      widget.onAuthComplete(false);
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Text(l10n.get('connected_to_spotify')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualAuthInstructions(String authUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Manual Authorization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to open Spotify automatically. Please follow these steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('1. Copy this URL:'),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                authUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('2. Open your browser and paste the URL'),
            const Text('3. Complete Spotify authorization'),
            const Text('4. You will be redirected to http://127.0.0.1:8888'),
            const Text('5. Copy the authorization code from the URL parameters'),
            const Text('6. Return here and paste the code'),
          ],
        ),
        actions: [
                     TextButton(
             onPressed: () {
               Navigator.of(context).pop();
               widget.onAuthComplete(false);
             },
             child: const Text('Cancel'),
           ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAuthComplete(false);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Spotify'),
        backgroundColor: const Color(0xFF1DB954),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onAuthComplete(false);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note,
              size: 80,
              color: Color(0xFF1DB954),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect to Spotify',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To create playlists, you need to authorize this app to access your Spotify account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAuthenticating ? null : _authenticateWithSpotify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isAuthenticating
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Connect to Spotify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
                         const SizedBox(height: 16),
             const Expanded(
               child: Text(
                 'After authorization, you will need to manually enter the authorization code.',
                 style: TextStyle(
                   color: Colors.grey,
                   fontSize: 14,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
          ],
        ),
      ),
    );
  }
}
