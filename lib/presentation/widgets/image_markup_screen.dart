import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:restro/presentation/widgets/voice_note_recorder.dart';
import 'package:restro/utils/theme/theme.dart';

class ImageMarkupScreen extends StatefulWidget {
  final String imageUrl;
  final Function(Uint8List markedImageBytes, String reason, File? voiceNote)
      onConfirm;

  const ImageMarkupScreen({
    super.key,
    required this.imageUrl,
    required this.onConfirm,
  });

  @override
  State<ImageMarkupScreen> createState() => _ImageMarkupScreenState();
}

enum _MarkupMode {
  draw,
  zoom,
}

class _ImageMarkupScreenState extends State<ImageMarkupScreen> {
  final GlobalKey _imageKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  List<DrawnLine> lines = [];
  DrawnLine? currentLine;
  bool isDrawing = false;
  String? selectedReason;
  File? _voiceNote;
  bool _isVoiceRecording = false;
  ui.Image? _resolvedImage;
  _MarkupMode _mode = _MarkupMode.draw;
  final List<String> rejectionReasons = [
    'Visible Dirt / Dust',
    'Stains / Marks',
    'Unorganized / Messy',
    'Bad Photo Quality (unclear / blurry photo)',
    'Food Safety Risk (e.g., old chicken, unpasteurized eggs)',
  ];

  bool get _canConfirm =>
      selectedReason != null && lines.isNotEmpty && !_isVoiceRecording;

  @override
  void initState() {
    super.initState();
    final provider = NetworkImage(widget.imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _resolvedImage = info.image;
        });
        stream.removeListener(listener);
      },
      onError: (_, __) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Rect _getFittedImageRect(Size widgetSize) {
    final img = _resolvedImage;
    if (img == null) {
      return Offset.zero & widgetSize;
    }
    final imageSize = Size(img.width.toDouble(), img.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imageSize, widgetSize);
    final renderSize = fitted.destination;
    final dx = (widgetSize.width - renderSize.width) / 2.0;
    final dy = (widgetSize.height - renderSize.height) / 2.0;
    return Rect.fromLTWH(dx, dy, renderSize.width, renderSize.height);
  }

  Offset? _globalToNormalized(Offset globalPosition) {
    final ctx = _imageKey.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return null;

    final local = renderObject.globalToLocal(globalPosition);
    final rect = _getFittedImageRect(renderObject.size);

    if (!rect.contains(local)) return null;
    final nx = ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final ny = ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    return Offset(nx, ny);
  }

  Offset _normalizedToLocal(Offset normalized, Size widgetSize) {
    final rect = _getFittedImageRect(widgetSize);
    return Offset(
      rect.left + (normalized.dx * rect.width),
      rect.top + (normalized.dy * rect.height),
    );
  }

  Future<void> _openPreview() async {
    final updatedLines = await showDialog<List<DrawnLine>>(
      context: context,
      builder: (context) {
        return _PreviewMarkupDialog(
          imageUrl: widget.imageUrl,
          initialLines: List.from(lines),
          resolvedImage: _resolvedImage,
        );
      },
    );

    if (updatedLines != null) {
      setState(() {
        lines = updatedLines;
      });
    }
  }

  void _undoLastStroke() {
    if (lines.isEmpty) return;
    setState(() {
      lines.removeLast();
    });
  }

  void _clearAllStrokes() {
    setState(() {
      lines.clear();
      currentLine = null;
      isDrawing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which icon to show for the toggle button
    final bool isDrawMode = _mode == _MarkupMode.draw;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Image & Canvas Layer
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: !isDrawMode,
              scaleEnabled: !isDrawMode,
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // The actual image
                      if (_resolvedImage != null)
                        Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      
                      // The drawing layer (GestureDetector only active in Draw mode)
                      Positioned.fill(
                       child: IgnorePointer(
                         ignoring: !isDrawMode, // Pass clicks through if not in draw mode
                         child: GestureDetector(
                            onPanStart: (details) {
                              if (!isDrawMode) return;
                              final p = _globalToNormalized(details.globalPosition);
                              if (p == null) return;
                              setState(() {
                                currentLine = DrawnLine(
                                  points: [p],
                                  color: Colors.red,
                                  width: 3.5, // Slightly thicker for visibility
                                );
                                isDrawing = true;
                              });
                            },
                            onPanUpdate: (details) {
                              if (!isDrawing || currentLine == null) return;
                              final p = _globalToNormalized(details.globalPosition);
                              if (p == null) return;
                              setState(() {
                                currentLine!.points.add(p);
                              });
                            },
                            onPanEnd: (details) {
                              if (currentLine != null) {
                                setState(() {
                                  lines.add(currentLine!);
                                  currentLine = null;
                                  isDrawing = false;
                                });
                              }
                            },
                            child: CustomPaint(
                              painter: DrawingPainter(
                                lines: [
                                  ...lines,
                                  if (currentLine != null) currentLine!,
                                ],
                                normalizedToLocal: _normalizedToLocal,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                       ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Top Gradient Overlay with Toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Mark Issues',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Toolbar Actions
                  _buildToolbarButton(
                    icon: Icons.undo_rounded,
                    tooltip: 'Undo',
                    onPressed: lines.isNotEmpty ? _undoLastStroke : null,
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    icon: Icons.cleaning_services_rounded, // Cleaner icon than delete_sweep
                    tooltip: 'Clear All',
                    onPressed: lines.isNotEmpty ? _clearAllStrokes : null,
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    icon: Icons.visibility_rounded, // Preview icon
                    tooltip: 'Preview',
                    onPressed: _openPreview,
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Controls Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Mode Toggle (Draw / Zoom)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleOption(
                            label: 'Draw',
                            icon: Icons.edit_rounded,
                            isSelected: isDrawMode,
                            onTap: () => setState(() => _mode = _MarkupMode.draw),
                          ),
                          _buildToggleOption(
                            label: 'Zoom',
                            icon: Icons.zoom_in_rounded,
                            isSelected: !isDrawMode,
                            onTap: () => setState(() => _mode = _MarkupMode.zoom),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason Dropdown
                  Text(
                    'Why are you rejecting this?',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Select a reason...',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ),
                        isExpanded: true,
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey.shade500),
                        ),
                        items: rejectionReasons.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(r, style: const TextStyle(fontSize: 14)),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedReason = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  
                  // Voice Note
                   VoiceNoteRecorder(
                      onChanged: (file) {
                        setState(() {
                          _voiceNote = file;
                        });
                      },
                      onRecordingChanged: (v) {
                        setState(() {
                          _isVoiceRecording = v;
                        });
                      },
                    ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canConfirm ? _confirmRejection : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                             disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Confirm Rejection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(isEnabled ? 0.15 : 0.05),
        padding: const EdgeInsets.all(10),
      ),
      icon: Icon(
        icon, 
        color: isEnabled ? Colors.white : Colors.white38,
        size: 20,
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRejection() async {
    if (selectedReason == null || lines.isEmpty) return;

    try {
      if (_mode == _MarkupMode.zoom) {
        setState(() {
          _mode = _MarkupMode.draw;
        });
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }

      // Capture the marked image
      final RenderRepaintBoundary boundary =
          _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List markedImageBytes = byteData.buffer.asUint8List();
        widget.onConfirm(markedImageBytes, selectedReason!, _voiceNote);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing marked image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawnLine({
    required this.points,
    required this.color,
    required this.width,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final Offset Function(Offset normalized, Size widgetSize) normalizedToLocal;

  DrawingPainter({required this.lines, required this.normalizedToLocal});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final Paint paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(
          normalizedToLocal(line.points[i], size),
          normalizedToLocal(line.points[i + 1], size),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PreviewMarkupDialog extends StatefulWidget {
  final String imageUrl;
  final List<DrawnLine> initialLines;
  final ui.Image? resolvedImage;

  const _PreviewMarkupDialog({
    required this.imageUrl,
    required this.initialLines,
    this.resolvedImage,
  });

  @override
  State<_PreviewMarkupDialog> createState() => _PreviewMarkupDialogState();
}

class _PreviewMarkupDialogState extends State<_PreviewMarkupDialog> {
  late List<DrawnLine> lines;
  DrawnLine? currentLine;
  bool isDrawing = false;
  final GlobalKey _previewImageKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();
  _MarkupMode _mode = _MarkupMode.draw;

  @override
  void initState() {
    super.initState();
    lines = widget.initialLines;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _undoLastStroke() {
    if (lines.isEmpty) return;
    setState(() {
      lines.removeLast();
    });
  }

  Rect _getFittedImageRect(Size widgetSize) {
    final img = widget.resolvedImage;
    if (img == null) {
      return Offset.zero & widgetSize;
    }
    final imageSize = Size(img.width.toDouble(), img.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imageSize, widgetSize);
    final renderSize = fitted.destination;
    final dx = (widgetSize.width - renderSize.width) / 2.0;
    final dy = (widgetSize.height - renderSize.height) / 2.0;
    return Rect.fromLTWH(dx, dy, renderSize.width, renderSize.height);
  }

  Offset? _globalToNormalized(Offset globalPosition) {
    final ctx = _previewImageKey.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return null;

    final local = renderObject.globalToLocal(globalPosition);
    final rect = _getFittedImageRect(renderObject.size);

    if (!rect.contains(local)) return null;
    final nx = ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final ny = ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    return Offset(nx, ny);
  }

  Offset _normalizedToLocal(Offset normalized, Size widgetSize) {
    final rect = _getFittedImageRect(widgetSize);
    return Offset(
      rect.left + (normalized.dx * rect.width),
      rect.top + (normalized.dy * rect.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDrawMode = _mode == _MarkupMode.draw;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.black,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white.withOpacity(0.1),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context, lines),
                    ),
                    const Expanded(
                      child: Text(
                        'Preview & Edit',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(isDrawMode ? Icons.zoom_in : Icons.edit, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _mode = isDrawMode ? _MarkupMode.zoom : _MarkupMode.draw;
                        });
                      },
                      tooltip: isDrawMode ? 'Switch to Zoom' : 'Switch to Draw',
                    ),
                     IconButton(
                      icon: const Icon(Icons.undo, color: Colors.white),
                      onPressed: lines.isNotEmpty ? _undoLastStroke : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: !isDrawMode,
                  scaleEnabled: !isDrawMode,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Center(
                    child: RepaintBoundary(
                      key: _previewImageKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.resolvedImage != null)
                            Image.network(
                              widget.imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: !isDrawMode,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  if (!isDrawMode) return;
                                  final p = _globalToNormalized(details.globalPosition);
                                  if (p == null) return;
                                  setState(() {
                                    currentLine = DrawnLine(points: [p], color: Colors.red, width: 3.5);
                                    isDrawing = true;
                                  });
                                },
                                onPanUpdate: (details) {
                                  if (!isDrawing || currentLine == null) return;
                                  final p = _globalToNormalized(details.globalPosition);
                                  if (p == null) return;
                                  setState(() {
                                    currentLine!.points.add(p);
                                  });
                                },
                                onPanEnd: (details) {
                                  if (currentLine != null) {
                                    setState(() {
                                      lines.add(currentLine!);
                                      currentLine = null;
                                      isDrawing = false;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: DrawingPainter(
                                    lines: [...lines, if (currentLine != null) currentLine!],
                                    normalizedToLocal: (n, s) => _normalizedToLocal(n, s),
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
