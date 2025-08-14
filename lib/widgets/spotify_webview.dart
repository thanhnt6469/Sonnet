import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyWebView extends StatefulWidget {
  final String initialUrl;
  final Function(String url) onUrlChanged;
  final Function(String code) onCodeReceived;

  const SpotifyWebView({
    super.key,
    required this.initialUrl,
    required this.onUrlChanged,
    required this.onCodeReceived,
  });

  @override
  State<SpotifyWebView> createState() => _SpotifyWebViewState();
}

class _SpotifyWebViewState extends State<SpotifyWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🌐 WebView: Page started loading: $url');
            widget.onUrlChanged(url);
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('✅ WebView: Page finished loading: $url');
            widget.onUrlChanged(url);
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 WebView: Navigation request to: ${request.url}');
            widget.onUrlChanged(request.url);
            
            // Check if this is the callback URL with authorization code
            if (request.url.startsWith('http://127.0.0.1:8888')) {
              print('🎯 WebView: Detected callback URL: ${request.url}');
              
              // Extract code from URL
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              
              if (code != null) {
                print('🎉 WebView: Authorization code found: $code');
                widget.onCodeReceived(code);
              }
            }
            
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView: Error loading page: ${error.description}');
            print('   Error code: ${error.errorCode}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Authorization'),
        backgroundColor: const Color(0xFF1DB954),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Spotify authorization...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1DB954),
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
