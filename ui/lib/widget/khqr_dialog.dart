import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/payway/services/payway_service.dart';
import '../core/widgets/global_loader.dart';

class KHQRDialog extends StatefulWidget {
  final String qrString;
  final String md5;

  final double amount;

  const KHQRDialog({
    super.key,
    required this.qrString,
    required this.md5,
    required this.amount,
  });

  @override
  State<KHQRDialog> createState() => _KHQRDialogState();
}

class _KHQRDialogState extends State<KHQRDialog> {
  final PayWayService _paywayService = PayWayService();
  bool _isSuccess = false;
  Timer? _timer;
  int _secondsRemaining = 30; // Set to 30s as requested

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining -= 2;
        });
        
        try {
          // Assuming result['status'] == 0 or similar for success
          // Adjust based on your actual API response structure
          // For now, let's print and assume if we get a valid response with status 0, it's success.
          // You said "response of it md5 response as well", implies we check 
          
          final result = await _paywayService.checkTransaction(widget.md5, widget.amount);
          debugPrint("Poll Result: $result");

          if (mounted) {
            // Check for both camelCase and PascalCase
            final isPaid = result['isPaid'] ?? result['IsPaid'] == true;
            final status = result['status'] ?? result['Status'];

            if (isPaid) {
              _timer?.cancel();
              setState(() {
                _isSuccess = true;
              });
              
              // Close dialog after 2 seconds
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                   Navigator.of(context).pop(true); // Return true to indicate success
                }
              });

            } else if (status == 'FAILED') {
               // Handle failure
            }
          }
        } catch (e) {
          debugPrint("Polling error: $e");
        }

      } else {
        timer.cancel();
        // Timeout - Close dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("QR Code expired")),
          );
        }
      }
    });
  }

  Future<void> _launchBankApp() async {
    final String bakongUrl = "https://api-bakong.nbc.gov.kh/checkout/qr?code=${widget.qrString}";
    final Uri url = Uri.parse(bakongUrl);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback or show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open bank app. Please scan the QR instead.")),
          );
        }
      }
    } catch (e) {
       debugPrint("Launch error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSuccess ? _buildSuccessState() : _buildWaitingState(),
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        key: const ValueKey('waiting'),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ទូទាត់ជាមួយ KHQR", // Pay with KHQR
                style: TextStyle(
                  fontFamily: 'Hanuman',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF5a7335),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // QR Code Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: const Color(0xFF5a7335).withOpacity(0.1)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: QrImageView(
                    data: widget.qrString,
                    version: QrVersions.auto,
                    size: 160.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF5a7335),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "KHQR",
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 16, 
                    letterSpacing: 1,
                    color: Color(0xFF5a7335)
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
  
          // Deep Link Button for Mobile Apps
          Container(
            width: double.infinity,
            height: 54,
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
                  blurRadius: 12,
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
                  SizedBox(width: 10),
                  Text(
                    "ទូទាត់ជាមួយកម្មវិធីធនាគារ", // Pay with Bank App
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
          
          const SizedBox(height: 10),
          Text(
            "Supports ABA, ACLEDA, Wing and more",
            style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
  
          const SizedBox(height: 20),
          
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: GlobalLoader(size: 16, color: Color(0xFF5a7335)),
              ),
              const SizedBox(width: 10),
              Text(
                "កំពុងរង់ចាំការទូទាត់... ($_secondsRemaining)", // Waiting for payment...
                style: TextStyle(
                  fontFamily: 'Hanuman',
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF5a7335).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Color(0xFF5a7335), size: 60),
        ),
        const SizedBox(height: 20),
        const Text(
          "ការទូទាត់ជោគជ័យ", // Payment Successful
          style: TextStyle(
            fontFamily: 'Hanuman',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF5a7335),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "ទទួលបានការទូទាត់ពីធនាគារ", // Payment received from bank
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Hanuman',
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Return success result
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5a7335),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "រួចរាល់ (Done)",
              style: TextStyle(
                fontFamily: 'Hanuman',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
