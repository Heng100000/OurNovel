import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../features/payway/services/payway_service.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey('waiting'),
      children: [
        const Text(
          "ស្កេនដើម្បីទូទាត់", // Scan to Pay
          style: TextStyle(
            fontFamily: 'Hanuman',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF5a7335),
          ),
        ),
        const SizedBox(height: 20),
        
        // QR Code
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: widget.qrString,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        const Text(
          "KHQR",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        
        const SizedBox(height: 25),
        
        // Polling Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5a7335)),
            ),
            const SizedBox(width: 15),
            Flexible(
              child: Text(
                "កំពុងផ្ទៀងផ្ទាត់ការទូទាត់... ($_secondsRemaining)", // Verifying payment...
                style: TextStyle(
                  fontFamily: 'Hanuman',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 5),
        Text(
          "សូមស្កេនឥឡូវនេះ (Please scan now)",
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),

        const SizedBox(height: 20),
        
        // Cancel Button
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            "បោះបង់ (Cancel)",
            style: TextStyle(color: Colors.red, fontFamily: 'Hanuman'),
          ),
        )
      ],
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
