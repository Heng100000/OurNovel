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
    final size = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
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
                left: scanWindow.left + 20,
                right: scanWindow.left + 20,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white,
                        Colors.white.withOpacity(0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Top Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom Curved Container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Curved White Background
                CustomPaint(
                  size: Size(size.width, 160),
                  painter: BottomCurvePainter(),
                ),
                
                // Centered Scanner Icon/Button
                Positioned(
                  top: -45,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5a7335), // Dark green border/bg
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.document_scanner_outlined,
                          color: Color(0xFF5a7335),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

                // Action Labels or Buttons inside white area
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomAction(
                        icon: Icons.flashlight_on_rounded,
                        label: 'Flashlight',
                        onTap: () => _controller.toggleTorch(),
                      ),
                      const SizedBox(width: 80), // Space for centered button
                      _buildBottomAction(
                        icon: Icons.flip_camera_ios_rounded,
                        label: 'Flip Camera',
                        onTap: () => _controller.switchCamera(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Helper Text
          Positioned(
            top: scanWindow.bottom + 40,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'ដាក់បាកូដក្នុងប្រអប់ដើម្បីស្កែន',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'Hanuman',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF5a7335), size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 60);
    
    // Create the curve
    path.quadraticBezierTo(
      size.width / 2, -20, // Control point
      0, 60, // End point
    );
    
    path.close();
    canvas.drawShadow(path, Colors.black, 10, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Dimmed background with cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(24))),
      ),
      backgroundPaint,
    );

    // Draw 4 corners (brackets)
    const double cornerLength = 40.0;
    const double radius = 24.0;
    final rect = scanWindow;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..arcToPoint(Offset(rect.left + radius, rect.top), radius: const Radius.circular(radius))
        ..lineTo(rect.left + cornerLength, rect.top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + radius), radius: const Radius.circular(radius))
        ..lineTo(rect.right, rect.top + cornerLength),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - cornerLength)
        ..lineTo(rect.right, rect.bottom - radius)
        ..arcToPoint(Offset(rect.right - radius, rect.bottom), radius: const Radius.circular(radius))
        ..lineTo(rect.right - cornerLength, rect.bottom),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + cornerLength, rect.bottom)
        ..lineTo(rect.left + radius, rect.bottom)
        ..arcToPoint(Offset(rect.left, rect.bottom - radius), radius: const Radius.circular(radius))
        ..lineTo(rect.left, rect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
