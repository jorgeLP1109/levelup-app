import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const AdScreen({super.key, required this.onComplete});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  bool _canSkip = false;
  int _countdown = 5;
  Timer? _timer;
  Map<String, dynamic>? _ad;
  bool _loading = true;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _checkAndLoadAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndLoadAd() async {
    try {
      final api = ApiService();
      final res = await api.get('/ads/active');

      if (res.data == null) {
        widget.onComplete();
        return;
      }

      final ad = res.data as Map<String, dynamic>;
      final frecuencia = ad['frecuencia'] ?? 3;

      final storage = const FlutterSecureStorage();
      final countStr = await storage.read(key: 'ad_open_count') ?? '0';
      int count = int.parse(countStr) + 1;
      await storage.write(key: 'ad_open_count', value: count.toString());

      if (count % frecuencia != 0) {
        widget.onComplete();
        return;
      }

      _webController = _createController(ad['videoUrl'] ?? '');

      setState(() {
        _ad = ad;
        _loading = false;
      });

      _startCountdown();
    } catch (_) {
      widget.onComplete();
    }
  }

  WebViewController _createController(String videoUrl) {
    String embedUrl = videoUrl;

    // YouTube
    if (videoUrl.contains('youtube.com/watch')) {
      final videoId = Uri.parse(videoUrl).queryParameters['v'] ?? '';
      embedUrl = 'https://www.youtube.com/embed/$videoId?autoplay=1&mute=1&controls=0&modestbranding=1&rel=0&playsinline=1';
    } else if (videoUrl.contains('youtu.be/')) {
      final videoId = videoUrl.split('youtu.be/').last.split('?').first;
      embedUrl = 'https://www.youtube.com/embed/$videoId?autoplay=1&mute=1&controls=0&modestbranding=1&rel=0&playsinline=1';
    }
    // Google Drive
    else if (videoUrl.contains('drive.google.com')) {
      String fileId = '';
      if (videoUrl.contains('/file/d/')) {
        fileId = videoUrl.split('/file/d/').last.split('/').first;
      } else if (videoUrl.contains('id=')) {
        fileId = Uri.parse(videoUrl).queryParameters['id'] ?? '';
      }
      if (fileId.isNotEmpty) {
        embedUrl = 'https://drive.google.com/file/d/$fileId/preview';
      }
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..loadRequest(Uri.parse(embedUrl));

    return controller;
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        setState(() => _canSkip = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ad == null || _webController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final titulo = _ad!['titulo'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _webController!),
            ),

            // Skip button
            Positioned(
              top: 16,
              right: 16,
              child: _canSkip
                  ? GestureDetector(
                      onTap: widget.onComplete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Saltar', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.skip_next, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Saltar en ${_countdown}s',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
            ),

            // Título
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Ad', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
