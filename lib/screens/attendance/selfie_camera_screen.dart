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

class SelfieGuideGeometry {
  const SelfieGuideGeometry();

  Rect _templateFrame(Size size) {
    final width = size.width * 0.76;
    final height = width * (326 / 353);
    final left = (size.width - width) / 2;
    final top = size.height * 0.12;

    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _templatePoint(Rect frame, double x, double y) {
    const sourceLeft = 267.0;
    const sourceTop = 129.0;
    const sourceWidth = 353.0;
    const sourceHeight = 326.0;

    return Offset(
      frame.left + ((x - sourceLeft) / sourceWidth) * frame.width,
      frame.top + ((y - sourceTop) / sourceHeight) * frame.height,
    );
  }

  Rect headBounds(Size size) {
    final frame = _templateFrame(size);
    final left = _templatePoint(frame, 335, 129).dx;
    final top = _templatePoint(frame, 335, 129).dy;
    final right = _templatePoint(frame, 552, 129).dx;
    final bottom = _templatePoint(frame, 335, 346).dy;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect guideBounds(Size size) {
    final frame = _templateFrame(size);

    return Rect.fromLTRB(
      _templatePoint(frame, 267, 129).dx,
      _templatePoint(frame, 267, 129).dy,
      _templatePoint(frame, 620, 455).dx,
      _templatePoint(frame, 620, 455).dy,
    );
  }

  double neckWidth(Size size) {
    final frame = _templateFrame(size);

    return _templatePoint(frame, 500, 380).dx -
        _templatePoint(frame, 386, 380).dx;
  }

  Path buildBustOutline(Size size) {
    final frame = _templateFrame(size);
    Offset p(double x, double y) => _templatePoint(frame, x, y);

    return Path()
      ..moveTo(p(267, 454).dx, p(267, 454).dy)
      ..cubicTo(
        p(270, 443).dx,
        p(270, 443).dy,
        p(326, 435).dx,
        p(326, 435).dy,
        p(358, 425).dx,
        p(358, 425).dy,
      )
      ..cubicTo(
        p(388, 416).dx,
        p(388, 416).dy,
        p(390, 407).dx,
        p(390, 407).dy,
        p(386, 395).dx,
        p(386, 395).dy,
      )
      ..cubicTo(
        p(383, 384).dx,
        p(383, 384).dy,
        p(371, 376).dx,
        p(371, 376).dy,
        p(366, 364).dx,
        p(366, 364).dy,
      )
      ..cubicTo(
        p(360, 349).dx,
        p(360, 349).dy,
        p(354, 334).dx,
        p(354, 334).dy,
        p(351, 326).dx,
        p(351, 326).dy,
      )
      ..cubicTo(
        p(335, 324).dx,
        p(335, 324).dy,
        p(327, 315).dx,
        p(327, 315).dy,
        p(326, 296).dx,
        p(326, 296).dy,
      )
      ..cubicTo(
        p(325, 281).dx,
        p(325, 281).dy,
        p(330, 270).dx,
        p(330, 270).dy,
        p(339, 266).dx,
        p(339, 266).dy,
      )
      ..cubicTo(
        p(333, 232).dx,
        p(333, 232).dy,
        p(338, 200).dx,
        p(338, 200).dy,
        p(384, 145).dx,
        p(384, 145).dy,
      )
      ..cubicTo(
        p(413, 130).dx,
        p(413, 130).dy,
        p(462, 126).dx,
        p(462, 126).dy,
        p(496, 139).dx,
        p(496, 139).dy,
      )
      ..cubicTo(
        p(536, 154).dx,
        p(536, 154).dy,
        p(557, 201).dx,
        p(557, 201).dy,
        p(548, 266).dx,
        p(548, 266).dy,
      )
      ..cubicTo(
        p(558, 270).dx,
        p(558, 270).dy,
        p(563, 285).dx,
        p(563, 285).dy,
        p(560, 300).dx,
        p(560, 300).dy,
      )
      ..cubicTo(
        p(557, 316).dx,
        p(557, 316).dy,
        p(548, 324).dx,
        p(548, 324).dy,
        p(533, 326).dx,
        p(533, 326).dy,
      )
      ..cubicTo(
        p(530, 341).dx,
        p(530, 341).dy,
        p(523, 360).dx,
        p(523, 360).dy,
        p(513, 374).dx,
        p(513, 374).dy,
      )
      ..cubicTo(
        p(503, 388).dx,
        p(503, 388).dy,
        p(497, 397).dx,
        p(497, 397).dy,
        p(501, 409).dx,
        p(501, 409).dy,
      )
      ..cubicTo(
        p(505, 423).dx,
        p(505, 423).dy,
        p(524, 429).dx,
        p(524, 429).dy,
        p(557, 435).dx,
        p(557, 435).dy,
      )
      ..cubicTo(
        p(587, 440).dx,
        p(587, 440).dy,
        p(617, 447).dx,
        p(617, 447).dy,
        p(620, 455).dx,
        p(620, 455).dy,
      );
  }
}

class _SelfieGuidePainter extends CustomPainter {
  const _SelfieGuidePainter();

  static const SelfieGuideGeometry _geometry = SelfieGuideGeometry();

  @override
  void paint(Canvas canvas, Size size) {
    final bustOutline = _geometry.buildBustOutline(size);

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bustOutline, glowPaint);
    canvas.drawPath(bustOutline, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
