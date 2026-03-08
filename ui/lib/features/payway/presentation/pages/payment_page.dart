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
import '../../../invoice/data/invoice_service.dart';
import '../../../invoice/data/invoice_model.dart';
import '../../../invoice/presentation/pages/invoice_detail_page.dart';
import '../../../../widget/cart_page.dart';

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
  bool _isExpired = false;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 5);
  int _retryCount = 0;
  final int _maxRetries = 100; // Increased to 100 (5 minutes) for better UX
  String _debugStatus = "Initializing...";

  @override
  void initState() {
    super.initState();
    _isPaid = widget.payment.status == 'paid';
    _calculateRemainingTime();
    _startCountdown();
    _startPolling();
  }

  void _calculateRemainingTime() {
    if (widget.payment.expiresAt != null) {
      final now = DateTime.now();
      _remainingTime = widget.payment.expiresAt!.difference(now);
      if (_remainingTime.isNegative) {
        _remainingTime = Duration.zero;
        _isExpired = true;
      }
    }
  }

  void _startCountdown() {
    if (_isExpired || _isPaid) return;
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          _isExpired = true;
          _countdownTimer?.cancel();
          _pollingTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchBankApp() async {
    if (_isExpired) return;
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

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_retryCount >= _maxRetries || _isPaid) {
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

    try {
      setState(() => _debugStatus = "Checking server...");
      final result = await _paymentService.checkKhqrStatus(widget.payment.id);
      debugPrint('Payment Status: $result');

      if (!mounted) return;

      if (result['paid'] == true) {
        setState(() {
          _isPaid = true;
          _isChecking = false;
          _debugStatus = "Paid! Redirecting...";
          _countdownTimer?.cancel();
        });
        _pollingTimer?.cancel();

        // Navigate to invoice after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _navigateToInvoice();
        });
      } else {
        if (mounted) setState(() {
          _isChecking = false;
          _debugStatus = "Not paid (status: ${result['status']})";
        });
      }
    } catch (e) {
      debugPrint('Payment check error: $e');
      if (mounted) setState(() {
        _isChecking = false;
        _debugStatus = "Error: ${e.toString().split('\n').first}";
      });
    }
  }

  Future<void> _navigateToInvoice() async {
    try {
      final invoices = await InvoiceService().getInvoices();
      final invoice = invoices.firstWhere(
        (inv) => inv.orderId == widget.payment.orderId,
        orElse: () => invoices.first,
      );
      if (mounted) {
        // Replace payment page + go to invoice detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailPage(invoice: invoice),
          ),
        );
      }
    } catch (_) {
      // Fallback: just pop if invoice fetch fails
      if (mounted) Navigator.pop(context, true);
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
                if (!_isPaid && !_isExpired) ...[
                  // Amount
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
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
                            fontSize: 18,
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
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${widget.payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3436),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(24),
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _isExpired ? 0.3 : 1.0,
                            child: widget.payment.qrImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.payment.qrImageUrl!,
                                    width: 240,
                                    height: 240,
                                    placeholder: (context, url) => const SizedBox(
                                      width: 240,
                                      height: 240,
                                      child: Center(child: GlobalLoader(size: 40)),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 240,
                                      height: 240,
                                      color: Colors.grey[50],
                                      child: const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    width: 240,
                                    height: 240,
                                    color: Colors.grey[50],
                                    child: const Center(child: GlobalLoader(size: 40)),
                                  ),
                          ),
                          if (_isExpired)
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_off_rounded, color: Colors.red.withOpacity(0.8), size: 60),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Expired',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Timer Display
                  const SizedBox(height: 24),
                  if (!_isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _remainingTime.inSeconds < 60 ? Colors.red.withOpacity(0.3) : const Color(0xFF5a7335).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined, 
                            size: 18, 
                            color: _remainingTime.inSeconds < 60 ? Colors.red : const Color(0xFF5a7335),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expires in: ${_remainingTime.inMinutes.toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: 'Hanuman',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _remainingTime.inSeconds < 60 ? Colors.red : const Color(0xFF5a7335),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _debugStatus,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
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
                    child: Icon(
                        _isPaid ? Icons.check_circle_rounded : Icons.timer_off_rounded, 
                        size: 120, 
                        color: _isPaid ? Colors.green : Colors.red
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isPaid ? _langService.translate('payment_success') : 'QR Code Expired',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Hanuman',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isPaid ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isPaid ? 'Redirecting to invoice...' : 'Please go back to cart to checkout again.',
                    style: TextStyle(
                      fontFamily: 'Hanuman',
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isPaid) {
                           _navigateToInvoice();
                        } else {
                           Navigator.of(context).pushAndRemoveUntil(
                             MaterialPageRoute(builder: (context) => const CartPage()),
                             (route) => false,
                           );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a7335),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isPaid ? 'View Invoice' : 'Back to Cart',
                        style: const TextStyle(
                          fontFamily: 'Hanuman',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

