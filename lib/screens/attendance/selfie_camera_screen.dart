import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key, this.title = 'Ambil Foto'});

  final String title;

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  String? _errorMessage;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final previousController = _controller;

    if (mounted) {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
        _warningMessage = null;
      });
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Kamera tidak tersedia di perangkat ini.');
      }

      var selectedCamera = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } on CameraException {
        // Some devices do not support orientation locking; preview still works.
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await previousController?.dispose();

      setState(() {
        _controller = controller;
        _isInitializing = false;
        _warningMessage =
            selectedCamera.lensDirection == CameraLensDirection.front
            ? null
            : 'Kamera depan tidak tersedia, jadi aplikasi memakai kamera lain.';
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _controller = null;
        _isInitializing = false;
        _errorMessage =
            'Kamera gagal dibuka (${error.code}). Pastikan izin kamera sudah diizinkan.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _controller = null;
        _isInitializing = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (_isTakingPicture ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final photo = await controller.takePicture();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(photo.path);
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil foto (${error.code}). Silakan coba lagi.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isReady)
                      _buildCameraPreview(controller)
                    else
                      _buildCameraFallback(),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.14),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.42, 1.0],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const IgnorePointer(
                      child: CustomPaint(
                        painter: _SelfieGuidePainter(),
                        child: SizedBox.expand(),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: _buildGuideHint(),
                    ),
                    if (_warningMessage != null)
                      Positioned(
                        top: 16,
                        left: 18,
                        right: 18,
                        child: _buildMessageCard(
                          text: _warningMessage!,
                          color: Colors.orange.withValues(alpha: 0.94),
                          textColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              _buildBottomBar(isReady: isReady),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
            tooltip: 'Kembali',
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'HRIS Mobile',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return const ColoredBox(color: Colors.black);
        }

        final deviceRatio = constraints.maxWidth / constraints.maxHeight;
        var scale = controller.value.aspectRatio / deviceRatio;
        if (scale < 1) {
          scale = 1 / scale;
        }

        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(controller)),
          ),
        );
      },
    );
  }

  Widget _buildGuideHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        'Posisikan wajah dan bahu di dalam garis siluet.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomBar({required bool isReady}) {
    return Container(
      height: 144,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.flash_off_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 34,
              ),
            ),
          ),
          _buildCaptureButton(isReady: isReady),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildCaptureButton({required bool isReady}) {
    final isEnabled = isReady && !_isTakingPicture;

    return Semantics(
      button: true,
      label: _isTakingPicture ? 'Memotret' : 'Ambil Foto',
      child: GestureDetector(
        onTap: isEnabled ? _capturePhoto : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isEnabled ? 1 : 0.55,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: _isTakingPicture
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFallback() {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Membuka kamera depan...',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Kamera tidak dapat dibuka.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => unawaited(_initializeCamera()),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SelfieGuidePainter extends CustomPainter {
  const _SelfieGuidePainter();

  Offset _point(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  Path _buildCatmullRomPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) {
      return path;
    }

    path.moveTo(points.first.dx, points.first.dy);

    for (var index = 0; index < points.length - 1; index++) {
      final previous = index == 0 ? points[index] : points[index - 1];
      final current = points[index];
      final next = points[index + 1];
      final nextNext = index + 2 < points.length ? points[index + 2] : next;

      final controlPoint1 = Offset(
        current.dx + (next.dx - previous.dx) / 6,
        current.dy + (next.dy - previous.dy) / 6,
      );
      final controlPoint2 = Offset(
        next.dx - (nextNext.dx - current.dx) / 6,
        next.dy - (nextNext.dy - current.dy) / 6,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bustOutline = _buildCatmullRomPath([
      _point(size, 0.02, 0.95),
      _point(size, 0.05, 0.86),
      _point(size, 0.12, 0.79),
      _point(size, 0.24, 0.74),
      _point(size, 0.36, 0.66),
      _point(size, 0.38, 0.57),
      _point(size, 0.29, 0.48),
      _point(size, 0.31, 0.38),
      _point(size, 0.34, 0.24),
      _point(size, 0.40, 0.12),
      _point(size, 0.46, 0.08),
      _point(size, 0.50, 0.07),
      _point(size, 0.54, 0.08),
      _point(size, 0.60, 0.12),
      _point(size, 0.66, 0.24),
      _point(size, 0.69, 0.38),
      _point(size, 0.71, 0.48),
      _point(size, 0.62, 0.57),
      _point(size, 0.64, 0.66),
      _point(size, 0.76, 0.74),
      _point(size, 0.88, 0.79),
      _point(size, 0.95, 0.86),
      _point(size, 0.98, 0.95),
    ]);

    final glowPaint = Paint()
      ..color = const Color(0xFFFFEEF7).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final strokePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD8EA), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bustOutline, glowPaint);
    canvas.drawPath(bustOutline, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
