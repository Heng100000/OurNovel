import 'dart:async';
import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5), // Very light green-white background
      drawer: const SideMenuDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF5a7335)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
                  
                  const SizedBox(height: 24),
                  
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: GlobalLoader(size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _langService.translate('payment_pending'),
                          style: const TextStyle(
                            fontFamily: 'Hanuman',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636E72),
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
}

