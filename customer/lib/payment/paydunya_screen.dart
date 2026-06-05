import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constant/constant.dart';

class PaydunyaScreen extends StatefulWidget {
  final String paymentUrl;
  final String token;
  final String orderId;

  const PaydunyaScreen({
    super.key,
    required this.paymentUrl,
    required this.token,
    required this.orderId,
  });

  @override
  State<PaydunyaScreen> createState() => _PaydunyaScreenState();
}

class _PaydunyaScreenState extends State<PaydunyaScreen> {
  WebViewController _controller = WebViewController();
  bool isLoading = true;
  Timer? _timeoutTimer;

  static const _timeoutMinutes = 15;

  @override
  void initState() {
    super.initState();
    _controller.clearCache();
    _startTimeoutTimer();
    _initController();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(minutes: _timeoutMinutes), () {
      if (mounted) {
        Get.back(result: 'expired');
      }
    });
  }

  Future<void> _confirmAndClose(String token) async {
    if (token.isEmpty) {
      debugPrint('[PayDunya WebView] no token in return URL — trusting redirect');
      Get.back(result: true);
      return;
    }
    try {
      final confirmUrl =
          '${Uri.parse(Constant.globalUrl).origin}/paydunya-mobile-confirm?token=$token';
      debugPrint('[PayDunya WebView] confirm → $confirmUrl');
      final response = await http.get(
        Uri.parse(confirmUrl),
        headers: {'Accept': 'application/json'},
      );
      debugPrint('[PayDunya WebView] confirm ← ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Get.back(result: data['confirmed'] == true);
      } else {
        Get.back(result: true); // fallback: trust redirect
      }
    } catch (e) {
      debugPrint('[PayDunya WebView] confirm error: $e');
      Get.back(result: true); // fallback: trust redirect
    }
  }

  void _initController() {
    debugPrint('[PayDunya WebView] loadRequest → ${widget.paymentUrl}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => debugPrint('[PayDunya WebView] onPageStarted: $url'),
          onPageFinished: (url) {
            debugPrint('[PayDunya WebView] onPageFinished: $url');
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[PayDunya WebView] onWebResourceError: ${error.errorCode} ${error.errorType} ${error.description} url=${error.url}');
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('[PayDunya WebView] onHttpError: ${error.response?.statusCode} url=${error.request?.uri}');
          },
          onNavigationRequest: (NavigationRequest nav) {
            final url = nav.url;
            debugPrint('[PayDunya WebView] onNavigationRequest: $url');
            if (url.contains('paydunya-return') ||
                url.contains('paydunya/return')) {
              _timeoutTimer?.cancel();
              final token = Uri.tryParse(url)?.queryParameters['token'] ?? '';
              debugPrint('[PayDunya WebView] return token: $token');
              _confirmAndClose(token);
              return NavigationDecision.prevent;
            }
            if (url.contains('paydunya-cancel') ||
                url.contains('paydunya/cancel')) {
              _timeoutTimer?.cancel();
              Get.back(result: false);
              return NavigationDecision.prevent;
            }
            // Deep links (wave://, tel:, intent://, etc.) — open externally
            final uri = Uri.tryParse(url);
            if (uri != null &&
                uri.scheme != 'http' &&
                uri.scheme != 'https') {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Annuler le paiement ?'.tr),
        content: Text('Le paiement sera annulé et la commande supprimée.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Continuer'.tr, style: const TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Annuler'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _timeoutTimer?.cancel();
      Get.back(result: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _confirmCancel();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Paiement OM/WAVE'.tr),
          centerTitle: false,
          leading: GestureDetector(
            onTap: _confirmCancel,
            child: const Icon(Icons.arrow_back),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
