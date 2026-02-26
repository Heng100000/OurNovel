import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import 'dart:ui';

class ModernScannerPage extends StatefulWidget {
  final Function(String code) onScan;

  const ModernScannerPage({super.key, required this.onScan});

  @override
  State<ModernScannerPage> createState() => _ModernScannerPageState();
}

class _ModernScannerPageState extends State<ModernScannerPage>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
      width: 280,
      height: 280,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  widget.onScan(code);
                  Navigator.pop(context);
                }
              }
            },
          ),
          // Dimmed Background with Cutout
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow: scanWindow),
            child: Container(),
          ),
          // Animated Scanning Line
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: scanWindow.top + (scanWindow.height * _animation.value),
                left: scanWindow.left + 10,
                right: scanWindow.left + 10,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Top Controls (Close)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
          // Center Title
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'ស្កែនបាកូដ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Hanuman',
                ),
              ),
            ),
          ),
          // Bottom Controls (Torch & Camera Flip)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.flashlight_on_outlined,
                  onTap: () => _controller.toggleTorch(),
                  label: 'Torch',
                ),
                const SizedBox(width: 40),
                _buildActionButton(
                  icon: Icons.flip_camera_ios_outlined,
                  onTap: () => _controller.switchCamera(),
                  label: 'Flip',
                ),
              ],
            ),
          ),
          // Helper Text
          Positioned(
            top: scanWindow.bottom + 20,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'ដាក់បាកូដក្នុងប្រអប់ដើម្បីស្កែន',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Hanuman',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white.withOpacity(0.2),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;


    // This is tricky, let's use a simpler way to draw the dimmed background with a hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20))),
      ),
      backgroundPaint,
    );

    // Draw the corners of the box instead of full border for a "cooler" look
    final rrect = RRect.fromRectAndRadius(scanWindow, const Radius.circular(20));
    
    // Draw 4 corners
    const double cornerLength = 30.0;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left, rrect.top + cornerLength)
        ..lineTo(rrect.left, rrect.top + 20)
        ..arcToPoint(Offset(rrect.left + 20, rrect.top), radius: const Radius.circular(20))
        ..lineTo(rrect.left + cornerLength, rrect.top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right - cornerLength, rrect.top)
        ..lineTo(rrect.right - 20, rrect.top)
        ..arcToPoint(Offset(rrect.right, rrect.top + 20), radius: const Radius.circular(20))
        ..lineTo(rrect.right, rrect.top + cornerLength),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right, rrect.bottom - cornerLength)
        ..lineTo(rrect.right, rrect.bottom - 20)
        ..arcToPoint(Offset(rrect.right - 20, rrect.bottom), radius: const Radius.circular(20))
        ..lineTo(rrect.right - cornerLength, rrect.bottom),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left + cornerLength, rrect.bottom)
        ..lineTo(rrect.left + 20, rrect.bottom)
        ..arcToPoint(Offset(rrect.left, rrect.bottom - 20), radius: const Radius.circular(20))
        ..lineTo(rrect.left, rrect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
