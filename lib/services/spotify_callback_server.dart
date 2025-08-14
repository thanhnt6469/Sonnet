import 'dart:io';
import 'dart:convert';
import 'dart:async';

class SpotifyCallbackServer {
  static const int _port = 8888;
  HttpServer? _server;
  Completer<String>? _codeCompleter;

  /// Start the callback server
  Future<void> start() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      print('Spotify callback server started on port $_port');

      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
    } catch (e) {
      print('Error starting callback server: $e');
      rethrow;
    }
  }

  /// Stop the callback server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('Spotify callback server stopped');
    }
  }

  /// Wait for authorization code
  Future<String> waitForCode() async {
    // If there's already a completer, complete it with error first
    if (_codeCompleter != null && !_codeCompleter!.isCompleted) {
      _codeCompleter!.completeError('New authorization request started');
    }
    
    // Reset completer
    _codeCompleter = Completer<String>();
    print('Waiting for authorization code...');
    return _codeCompleter!.future;
  }

  /// Handle incoming HTTP requests
  void _handleRequest(HttpRequest request) {
    final uri = request.uri;
    print('Received callback: $uri');

    // Set CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      request.response.close();
      return;
    }

    // Handle favicon.ico requests
    if (uri.path == '/favicon.ico') {
      request.response.statusCode = 404;
      request.response.close();
      return;
    }

    try {
      // Extract authorization code from URL
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        print('Authorization error: $error');
        _sendErrorResponse(request, 'Authorization failed: $error');
        if (_codeCompleter != null && !_codeCompleter!.isCompleted) {
          _codeCompleter!.completeError('Authorization failed: $error');
        }
        return;
      }

      if (code != null) {
        print('Authorization code received: ${code.substring(0, 10)}...');
        _sendSuccessResponse(request, code);
        // Only complete if not already completed
        if (_codeCompleter != null && !_codeCompleter!.isCompleted) {
          _codeCompleter!.complete(code);
          print('Authorization code completed successfully');
        } else {
          print('Completer already completed, ignoring duplicate callback');
        }
      } else {
        print('No authorization code found in callback');
        _sendErrorResponse(request, 'No authorization code found');
        if (_codeCompleter != null && !_codeCompleter!.isCompleted) {
          _codeCompleter!.completeError('No authorization code found');
        }
      }
    } catch (e) {
      print('Error processing callback: $e');
      _sendErrorResponse(request, 'Error processing callback: $e');
      if (_codeCompleter != null && !_codeCompleter!.isCompleted) {
        _codeCompleter!.completeError('Error processing callback: $e');
      }
    }
  }

    /// Send success response
  void _sendSuccessResponse(HttpRequest request, String code) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Spotify Authorization Success</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1DB954 0%, #1ed760 100%);
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            max-width: 400px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        .icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0 0 10px 0;
            font-size: 24px;
            font-weight: 600;
        }
        p {
            margin: 0 0 20px 0;
            opacity: 0.9;
            line-height: 1.5;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🎵</div>
        <h1>Authorization Successful!</h1>
        <p>Your Spotify account has been successfully connected to Sonnet.</p>
        <p>You will be redirected back to the app automatically.</p>
    </div>
         <script>
         // Auto-close immediately without showing anything
         try {
             if (window.opener) {
                 window.close();
             } else {
                 if (window.history.length > 1) {
                     window.history.back();
                 } else {
                     window.close();
                 }
             }
         } catch (e) {
             console.log('Auto-closing window...');
         }
     </script>
</body>
</html>
''';

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }

  /// Send error response
  void _sendErrorResponse(HttpRequest request, String error) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Spotify Authorization Error</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%);
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            max-width: 400px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        .icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0 0 10px 0;
            font-size: 24px;
            font-weight: 600;
        }
        p {
            margin: 0 0 20px 0;
            opacity: 0.9;
            line-height: 1.5;
        }
        .error {
            background: rgba(255, 255, 255, 0.2);
            padding: 12px;
            border-radius: 8px;
            font-family: monospace;
            font-size: 12px;
            word-break: break-all;
            margin: 20px 0;
        }
        .close-btn {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            padding: 12px 24px;
            border-radius: 25px;
            cursor: pointer;
            font-size: 16px;
            transition: background 0.3s;
        }
        .close-btn:hover {
            background: rgba(255, 255, 255, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">❌</div>
        <h1>Authorization Failed</h1>
        <p>There was an error connecting your Spotify account.</p>
        <div class="error">Error: $error</div>
        <p>Please try again or contact support if the problem persists.</p>
        <button class="close-btn" onclick="closeWindow()">Close Window</button>
        <div id="closeMessage" style="display: none; margin-top: 16px; padding: 12px; background: rgba(255, 255, 255, 0.2); border-radius: 8px; font-size: 14px;">
            <p style="margin: 0;">If the window doesn't close automatically, please close it manually and return to the app.</p>
        </div>
    </div>
    <script>
        // Try to close window when button is clicked
        function closeWindow() {
            try {
                // Try multiple methods to close the window
                if (window.opener) {
                    window.close();
                } else {
                    // For mobile browsers, try to go back
                    if (window.history.length > 1) {
                        window.history.back();
                    } else {
                        // Final fallback - try to close anyway
                        window.close();
                    }
                }
            } catch (e) {
                console.log('Could not close window automatically');
                // Show message to user
                document.getElementById('closeMessage').style.display = 'block';
            }
        }
        
                 // Auto-close after 3 seconds
         setTimeout(() => {
             closeWindow();
         }, 3000);
    </script>
</body>
</html>
''';

    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }
}
