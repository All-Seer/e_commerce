import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen image cropper with:
///   • Pan (drag to move image)
///   • Pinch-to-zoom
///   • Free or 1:1 / 4:3 / 16:9 aspect lock
///   • Corner & edge handles to resize crop window
///   • Confirm → returns cropped PNG bytes via Navigator.pop(bytes)
class ImageCropperScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropperScreen({super.key, required this.imageBytes});

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  ui.Image? _uiImage;
  bool _loading = true;

  // Image transform (pan + zoom)
  Offset _imageOffset = Offset.zero;
  double _imageScale = 1.0;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _lastFocalPoint = Offset.zero; // tracks single-finger drag delta

  // Crop rect in widget-space
  Rect _cropRect = Rect.zero;
  bool _cropInitialized = false;

  // Which handle is being dragged (null = dragging image)
  _Handle? _activeHandle;

  // Aspect ratio lock  (null = free)
  double? _aspectRatio;
  final List<_AspectOption> _aspectOptions = const [
    _AspectOption('Free', null),
    _AspectOption('1:1', 1.0),
    _AspectOption('4:3', 4 / 3),
    _AspectOption('16:9', 16 / 9),
  ];
  int _selectedAspect = 0;

  static const double _handleSize = 24.0;
  static const double _minCrop = 60.0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final codec =
        await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _uiImage = frame.image;
      _loading = false;
    });
  }

  // ── Initialize crop rect to 80% of canvas after first layout ──────────────
  void _initCrop(Size canvasSize) {
    if (_cropInitialized || canvasSize.isEmpty) return;
    _cropInitialized = true;
    final w = canvasSize.width * 0.8;
    final h = _aspectRatio != null ? w / _aspectRatio! : canvasSize.height * 0.8;
    final l = (canvasSize.width - w) / 2;
    final t = (canvasSize.height - h) / 2;
    _cropRect = Rect.fromLTWH(l, t, w, h.clamp(_minCrop, canvasSize.height));

    // Fit image inside crop initially
    if (_uiImage != null) {
      final imgAspect = _uiImage!.width / _uiImage!.height;
      final cropAspect = w / _cropRect.height;
      double scale;
      if (imgAspect > cropAspect) {
        scale = _cropRect.width / _uiImage!.width;
      } else {
        scale = _cropRect.height / _uiImage!.height;
      }
      _imageScale = scale;
      _imageOffset = Offset(
        _cropRect.left + (_cropRect.width - _uiImage!.width * scale) / 2,
        _cropRect.top + (_cropRect.height - _uiImage!.height * scale) / 2,
      );
    }
  }

  // ── Hit test: which handle is at this position? ───────────────────────────
  _Handle? _hitHandle(Offset pos) {
    for (final handle in _Handle.values) {
      if (_handleRect(handle).inflate(8).contains(pos)) return handle;
    }
    return null;
  }

  Rect _handleRect(_Handle h) {
    final r = _cropRect;
    switch (h) {
      case _Handle.topLeft:     return Rect.fromCenter(center: r.topLeft,     width: _handleSize, height: _handleSize);
      case _Handle.topRight:    return Rect.fromCenter(center: r.topRight,    width: _handleSize, height: _handleSize);
      case _Handle.bottomLeft:  return Rect.fromCenter(center: r.bottomLeft,  width: _handleSize, height: _handleSize);
      case _Handle.bottomRight: return Rect.fromCenter(center: r.bottomRight, width: _handleSize, height: _handleSize);
      case _Handle.topCenter:   return Rect.fromCenter(center: r.topCenter,   width: _handleSize, height: _handleSize);
      case _Handle.bottomCenter:return Rect.fromCenter(center: r.bottomCenter,width: _handleSize, height: _handleSize);
      case _Handle.centerLeft:  return Rect.fromCenter(center: r.centerLeft,  width: _handleSize, height: _handleSize);
      case _Handle.centerRight: return Rect.fromCenter(center: r.centerRight, width: _handleSize, height: _handleSize);
    }
  }

  // ── Resize crop rect when dragging a handle ────────────────────────────────
  void _resizeCrop(Offset delta, Size canvasSize) {
    if (_activeHandle == null) return;
    double l = _cropRect.left;
    double t = _cropRect.top;
    double r = _cropRect.right;
    double b = _cropRect.bottom;

    switch (_activeHandle!) {
      case _Handle.topLeft:
        l += delta.dx; t += delta.dy;
      case _Handle.topRight:
        r += delta.dx; t += delta.dy;
      case _Handle.bottomLeft:
        l += delta.dx; b += delta.dy;
      case _Handle.bottomRight:
        r += delta.dx; b += delta.dy;
      case _Handle.topCenter:
        t += delta.dy;
      case _Handle.bottomCenter:
        b += delta.dy;
      case _Handle.centerLeft:
        l += delta.dx;
      case _Handle.centerRight:
        r += delta.dx;
    }

    // Clamp to canvas
    l = l.clamp(0.0, canvasSize.width - _minCrop);
    t = t.clamp(0.0, canvasSize.height - _minCrop);
    r = r.clamp(_minCrop, canvasSize.width);
    b = b.clamp(_minCrop, canvasSize.height);

    // Enforce min size
    if (r - l < _minCrop) {
      if (_activeHandle == _Handle.centerLeft || _activeHandle == _Handle.topLeft || _activeHandle == _Handle.bottomLeft) {
        l = r - _minCrop;
      } else {
        r = l + _minCrop;
      }
    }
    if (b - t < _minCrop) {
      if (_activeHandle == _Handle.topCenter || _activeHandle == _Handle.topLeft || _activeHandle == _Handle.topRight) {
        t = b - _minCrop;
      } else {
        b = t + _minCrop;
      }
    }

    double newW = r - l;
    double newH = b - t;

    // Apply aspect ratio lock
    if (_aspectRatio != null) {
      final isHorizontalHandle = _activeHandle == _Handle.centerLeft ||
          _activeHandle == _Handle.centerRight;
      final isVerticalHandle = _activeHandle == _Handle.topCenter ||
          _activeHandle == _Handle.bottomCenter;

      if (isHorizontalHandle) {
        newH = newW / _aspectRatio!;
        b = t + newH;
      } else if (isVerticalHandle) {
        newW = newH * _aspectRatio!;
        r = l + newW;
      } else {
        // Corner — dominant axis
        if (delta.dx.abs() > delta.dy.abs()) {
          newH = newW / _aspectRatio!;
          if (_activeHandle == _Handle.topLeft || _activeHandle == _Handle.topRight) {
            t = b - newH;
          } else {
            b = t + newH;
          }
        } else {
          newW = newH * _aspectRatio!;
          if (_activeHandle == _Handle.topLeft || _activeHandle == _Handle.bottomLeft) {
            l = r - newW;
          } else {
            r = l + newW;
          }
        }
      }
    }

    setState(() {
      _cropRect = Rect.fromLTRB(l, t, r, b);
    });
  }

  // ── Crop and return PNG bytes ─────────────────────────────────────────────
  Future<void> _confirmCrop(Size canvasSize) async {
    if (_uiImage == null) return;

    // Map crop rect from widget-space to image-space
    final imgW = _uiImage!.width.toDouble();
    final imgH = _uiImage!.height.toDouble();
    final scaleX = imgW / (imgW * _imageScale);
    final scaleY = imgH / (imgH * _imageScale);

    final srcLeft   = (_cropRect.left   - _imageOffset.dx) * scaleX;
    final srcTop    = (_cropRect.top    - _imageOffset.dy) * scaleY;
    final srcWidth  = _cropRect.width   * scaleX;
    final srcHeight = _cropRect.height  * scaleY;

    final clampedLeft   = srcLeft.clamp(0.0, imgW).toInt();
    final clampedTop    = srcTop.clamp(0.0, imgH).toInt();
    final clampedWidth  = srcWidth.clamp(1.0, imgW - clampedLeft).toInt();
    final clampedHeight = srcHeight.clamp(1.0, imgH - clampedTop).toInt();

    // Draw cropped region onto a new canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    canvas.drawImageRect(
      _uiImage!,
      Rect.fromLTWH(clampedLeft.toDouble(), clampedTop.toDouble(),
          clampedWidth.toDouble(), clampedHeight.toDouble()),
      Rect.fromLTWH(0, 0, clampedWidth.toDouble(), clampedHeight.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final croppedImage =
        await picture.toImage(clampedWidth, clampedHeight);
    final byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return;
    final result = byteData.buffer.asUint8List();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Crop Image',
            style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          // Aspect ratio buttons
          ..._aspectOptions.asMap().entries.map((e) {
            final selected = _selectedAspect == e.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAspect = e.key;
                    _aspectRatio = e.value.ratio;
                    // Re-apply aspect to current crop
                    if (_aspectRatio != null) {
                      final newH = _cropRect.width / _aspectRatio!;
                      _cropRect = Rect.fromLTWH(
                          _cropRect.left, _cropRect.top,
                          _cropRect.width, newH);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accent
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected
                            ? AppTheme.accent
                            : AppTheme.border),
                  ),
                  child: Center(
                    child: Text(e.value.label,
                        style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final size = context.size ?? Size.zero;
                await _confirmCrop(size);
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Apply'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                _initCrop(canvasSize);

                return GestureDetector(
                  // ── Scale subsumes pan: handles both single-finger drag
                  //    (pan/handle resize) and two-finger pinch-to-zoom ─────────
                  onScaleStart: (d) {
                    _startScale = _imageScale;
                    _startOffset = _imageOffset;
                    _lastFocalPoint = d.localFocalPoint;

                    // Hit-test handles only on single-finger start
                    if (d.pointerCount == 1) {
                      final hit = _hitHandle(d.localFocalPoint);
                      setState(() => _activeHandle = hit);
                    }
                  },
                  onScaleUpdate: (d) {
                    if (d.pointerCount >= 2) {
                      // ── Pinch-to-zoom ──────────────────────────────────────
                      setState(() {
                        final newScale =
                            (_startScale * d.scale).clamp(0.1, 10.0);
                        final scaleDiff = newScale / _imageScale;
                        _imageOffset = d.localFocalPoint -
                            (d.localFocalPoint - _imageOffset) * scaleDiff;
                        _imageScale = newScale;
                      });
                    } else {
                      // ── Single-finger: resize handle or pan image ──────────
                      final delta = d.localFocalPoint - _lastFocalPoint;
                      if (_activeHandle != null) {
                        _resizeCrop(delta, canvasSize);
                      } else if (_cropRect
                          .contains(d.localFocalPoint - delta)) {
                        setState(() => _imageOffset += delta);
                      }
                    }
                    _lastFocalPoint = d.localFocalPoint;
                  },
                  onScaleEnd: (_) => setState(() => _activeHandle = null),

                  child: CustomPaint(
                    size: canvasSize,
                    painter: _CropPainter(
                      image: _uiImage!,
                      imageOffset: _imageOffset,
                      imageScale: _imageScale,
                      cropRect: _cropRect,
                      handleRects: {
                        for (final h in _Handle.values) h: _handleRect(h)
                      },
                      activeHandle: _activeHandle,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Custom painter ───────────────────────────────────────────────────────────
class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Offset imageOffset;
  final double imageScale;
  final Rect cropRect;
  final Map<_Handle, Rect> handleRects;
  final _Handle? activeHandle;

  const _CropPainter({
    required this.image,
    required this.imageOffset,
    required this.imageScale,
    required this.cropRect,
    required this.handleRects,
    this.activeHandle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Draw image ───────────────────────────────────────────────────────────
    canvas.save();
    canvas.translate(imageOffset.dx, imageOffset.dy);
    canvas.scale(imageScale);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();

    // ── Dim outside crop ─────────────────────────────────────────────────────
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // ── Crop border ───────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(cropRect, borderPaint);

    // ── Rule of thirds grid ───────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdW * i, cropRect.top),
        Offset(cropRect.left + thirdW * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdH * i),
        Offset(cropRect.right, cropRect.top + thirdH * i),
        gridPaint,
      );
    }

    // ── Corner L-brackets ────────────────────────────────────────────────────
    final cornerPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const cLen = 16.0;
    // top-left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft.translate(cLen, 0), cornerPaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft.translate(0, cLen), cornerPaint);
    // top-right
    canvas.drawLine(cropRect.topRight, cropRect.topRight.translate(-cLen, 0), cornerPaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight.translate(0, cLen), cornerPaint);
    // bottom-left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft.translate(cLen, 0), cornerPaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft.translate(0, -cLen), cornerPaint);
    // bottom-right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight.translate(-cLen, 0), cornerPaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight.translate(0, -cLen), cornerPaint);

    // ── Handle circles ────────────────────────────────────────────────────────
    for (final entry in handleRects.entries) {
      final isActive = entry.key == activeHandle;
      final center = entry.value.center;
      // Outer ring
      canvas.drawCircle(
        center,
        10,
        Paint()
          ..color = isActive ? AppTheme.accent : Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        10,
        Paint()
          ..color = isActive ? AppTheme.accent : Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // ── Size label ────────────────────────────────────────────────────────────
    final textPainter = TextPainter(
      text: TextSpan(
        text:
            '${cropRect.width.toInt()} × ${cropRect.height.toInt()}',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        cropRect.left + (cropRect.width - textPainter.width) / 2,
        cropRect.bottom + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.imageOffset != imageOffset ||
      old.imageScale != imageScale ||
      old.cropRect != cropRect ||
      old.activeHandle != activeHandle;
}

// ─── Handle enum & aspect option ─────────────────────────────────────────────
enum _Handle {
  topLeft, topRight, bottomLeft, bottomRight,
  topCenter, bottomCenter, centerLeft, centerRight,
}

class _AspectOption {
  final String label;
  final double? ratio;
  const _AspectOption(this.label, this.ratio);
}