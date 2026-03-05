import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/global_loader.dart';
import '../../../../core/models/payment.dart';
import '../../../../l10n/language_service.dart';
import '../../data/payment_service.dart';
import '../../../menu/presentation/pages/menu_page.dart';

class PaymentPage extends StatefulWidget {
  final Payment payment;

  const PaymentPage({super.key, required this.payment});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final LanguageService _langService = LanguageService();
  
  bool _isChecking = false;
  bool _isPaid = false;
  Timer? _pollingTimer;
  int _retryCount = 0;
  final int _maxRetries = 100; // Increased to 100 (5 minutes) for better UX

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchBankApp() async {
    final String? deepLink = widget.payment.deepLink;
    final String? qrCode = widget.payment.qrCode;

    if (deepLink == null && qrCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR data not available. Please wait or refresh.")),
      );
      return;
    }
    
    // Try generic bakong scheme first as it's the most universal
    final String urlString = deepLink ?? "bakong://khqr/qr?code=$qrCode";
    final Uri url = Uri.parse(urlString);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("មិនស្គាល់កម្មវិធីធនាគារក្នុងទូរសព្ទអ្នកឡើយ។ សូមព្យាយាមស្កែន QR ជំនួសវិញ។"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
       debugPrint("Launch error: $e");
    }
  }

  void _startPolling() {
    // Initial check immediately
    _checkPaymentStatus();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_retryCount >= _maxRetries) {
        timer.cancel();
        return;
      }
      _checkPaymentStatus();
      _retryCount++;
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || _isPaid) return;

    setState(() => _isChecking = true);
    
    final result = await _paymentService.checkKhqrStatus(widget.payment.id);
    print('DEBUG: Payment Status Result: $result');
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        if (result['paid'] == true) {
          _isPaid = true;
          _pollingTimer?.cancel();
          
          // Auto-navigate back after 2 seconds success visibility
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5a7335), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _langService.translate('scan_to_pay'),
          style: const TextStyle(
            fontFamily: 'Hanuman', 
            fontWeight: FontWeight.bold,
            color: Color(0xFF5a7335),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAF5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isPaid) ...[
                  // Header Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5a7335).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _langService.translate('bakong_khqr'),
                          style: const TextStyle(
                            fontFamily: 'Hanuman',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5a7335),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _langService.translate('amount_to_pay'),
                          style: TextStyle(
                            fontFamily: 'Hanuman',
                            color: Colors.grey[600], 
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${widget.payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3436),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // QR Code Container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5a7335).withOpacity(0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF5a7335).withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.payment.qrImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.payment.qrImageUrl!,
                                  width: 200,
                                  height: 200,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(child: GlobalLoader(size: 32)),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[50],
                                    child: const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[50],
                                  child: const Center(child: GlobalLoader(size: 32)),
                                ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bank Selection Section
                  if (widget.payment.qrCode != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ជ្រើសរើសធនាគារ (Select Bank)",
                        style: TextStyle(
                          fontFamily: 'Hanuman',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBankItem(
                          name: "ABA",
                          label: "ABA Mobile",
                          color: const Color(0xFF005D7E),
                          scheme: "aba-merchant-khqr://qr?code=${widget.payment.qrCode}",
                        ),
                        _buildBankItem(
                          name: "ACLEDA",
                          label: "ACLEDA",
                          color: const Color(0xFF1B3C92),
                          scheme: "acledabank://qr?code=${widget.payment.qrCode}",
                        ),
                        _buildBankItem(
                          name: "Bakong",
                          label: "Bakong",
                          color: const Color(0xFFE41E26),
                          scheme: "bakong://khqr/qr?code=${widget.payment.qrCode}",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pay with Bank App button (General)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5a7335), Color(0xFF7aad45)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5a7335).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _launchBankApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "បើកកម្មវិធីធនាគារផ្សេងទៀត", // Open Other Bank Apps
                            style: TextStyle(
                              fontFamily: 'Hanuman',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status Indicator (Compact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: GlobalLoader(size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _langService.translate('payment_pending'),
                          style: const TextStyle(
                            fontFamily: 'Hanuman',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636E72),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Check Status Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkPaymentStatus,
                      icon: _isChecking 
                        ? const SizedBox(width: 20, height: 20, child: GlobalLoader(size: 20))
                        : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _langService.translate('check_status'),
                        style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a7335),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  // Celebrate Success
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, size: 120, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _langService.translate('payment_success'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Hanuman',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Redirecting to cart...',
                    style: TextStyle(
                      fontFamily: 'Hanuman',
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        _langService.translate('close'),
                        style: const TextStyle(
                          fontFamily: 'Hanuman',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5a7335),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankItem({required String name, required String label, required Color color, required String scheme}) {
    return InkWell(
      onTap: () async {
        final List<String> urlsToTry = [];
        final String rawQrCode = widget.payment.qrCode ?? "";
        final String encodedQr = Uri.encodeComponent(rawQrCode);
        
        // Auto-copy to clipboard for convenience (Scan from Gallery / Paste fallback)
        await Clipboard.setData(ClipboardData(text: rawQrCode));
        
        if (name == "Bakong") {
           // For Android, 'intent:' scheme is the most powerful way to force open a specific package
           urlsToTry.add("intent://khqr/qr?code=$encodedQr#Intent;scheme=bakong;package=kh.gov.nbc.bakong;end");
           urlsToTry.add("bakong://khqr/qr?code=$encodedQr");
           urlsToTry.add("bakong://qr?code=$encodedQr");
           urlsToTry.add("https://api-bakong.nbc.gov.kh/checkout/qr?code=$encodedQr");
        } else if (name == "ABA") {
           urlsToTry.add("intent://qr?code=$encodedQr#Intent;scheme=aba-merchant-khqr;package=kh.com.ababank.mobile;end");
           urlsToTry.add("aba-merchant-khqr://qr?code=$encodedQr");
        } else if (name == "ACLEDA") {
           urlsToTry.add("intent://qr?code=$encodedQr#Intent;scheme=acledabank;package=com.acledabank.mobile;end");
           urlsToTry.add("acledabank://qr?code=$encodedQr");
        } else {
           if (scheme.contains("?code=")) {
              final String base = scheme.split("?code=")[0];
              urlsToTry.add("$base?code=$encodedQr");
           } else {
              urlsToTry.add(scheme);
           }
        }

        bool success = false;
        
        for (String urlString in urlsToTry) {
          try {
            final Uri uri = Uri.parse(urlString);
            // Try launching as external application
            success = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (success) break;
          } catch (e) {
            debugPrint("Failed to launch $urlString: $e");
          }
        }

        if (!success && mounted) {
          // Final fallback for any KHQR: try the generic Bakong scheme
          if (name != "Bakong") {
             try {
                success = await launchUrl(Uri.parse("bakong://khqr/qr?code=$encodedQr"), mode: LaunchMode.externalApplication);
             } catch (_) {}
          }
          
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("មិនអាចបើកកម្មវិធី $name បានទេ។ លេខកូដត្រូវបានចម្លង (Copied) រួចរាល់។"),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: "Open App",
                  textColor: Colors.white,
                  onPressed: () {
                    // Try to open the app gateway if possible, or just let them use the copied code
                  },
                ),
              ),
            );
          }
        } else if (success && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text("កំពុងបើកកម្មវិធីធនាគារ... (លេខកូដត្រូវបានចម្លងទុកជាស្រេច)"),
               duration: Duration(seconds: 2),
             ),
           );
        }
      },
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                name[0], 
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800], fontFamily: 'Hanuman'),
          ),
        ],
      ),
    );
  }
}

