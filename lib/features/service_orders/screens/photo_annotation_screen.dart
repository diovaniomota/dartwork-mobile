import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke({required this.points, required this.color, required this.width});
}

class _AnnotationPainter extends CustomPainter {
  final ui.Image image;
  final List<_Stroke> strokes;
  final _Stroke? current;

  _AnnotationPainter({
    required this.image,
    required this.strokes,
    this.current,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());

    void drawStroke(_Stroke stroke) {
      if (stroke.points.isEmpty) return;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) {
      drawStroke(s);
    }
    if (current != null) drawStroke(current!);
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}

class PhotoAnnotationScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileName;

  const PhotoAnnotationScreen({
    super.key,
    required this.imageBytes,
    required this.fileName,
  });

  @override
  State<PhotoAnnotationScreen> createState() => _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends State<PhotoAnnotationScreen> {
  ui.Image? _uiImage;
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  final GlobalKey _repaintKey = GlobalKey();

  Color _selectedColor = Colors.red;
  double _strokeWidth = 4.0;
  bool _saving = false;

  static const _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.white,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _uiImage = frame.image);
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _currentStroke = _Stroke(
        points: [d.localPosition],
        color: _selectedColor,
        width: _strokeWidth,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke = _Stroke(
        points: [..._currentStroke!.points, d.localPosition],
        color: _currentStroke!.color,
        width: _currentStroke!.width,
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(widget.imageBytes);
        return;
      }
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final result = byteData?.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(context).pop(result ?? widget.imageBytes);
    } catch (_) {
      if (mounted) Navigator.of(context).pop(widget.imageBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0d1a36) : const Color(0xFF102456),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            highlightColor: Colors.white12,
          ),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: const Text('Anotar foto', style: TextStyle(fontSize: 16)),
        actions: [
          if (_strokes.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _undo,
              icon: const Icon(Icons.undo, color: Colors.white70, size: 18),
              label: const Text('Desfazer', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
              label: const Text('Limpar', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
          const SizedBox(width: 4),
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check, color: Colors.greenAccent),
                  label: const Text('Salvar', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: Column(
        children: [
          // Canvas de desenho
          Expanded(
            child: _uiImage == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RepaintBoundary(
                    key: _repaintKey,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _AnnotationPainter(
                          image: _uiImage!,
                          strokes: _strokes,
                          current: _currentStroke,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
          ),

          // Toolbar
          Container(
            color: isDark ? const Color(0xFF0d1a36) : const Color(0xFF102456),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seletor de cores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _colors.map((c) {
                      final selected = c.toARGB32() == _selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: selected ? 34 : 28,
                          height: selected ? 34 : 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white30,
                              width: selected ? 3 : 1.5,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: c.withAlpha(120), blurRadius: 6, spreadRadius: 1)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Espessura do traço
                  Row(
                    children: [
                      const Icon(Icons.brush, color: Colors.white54, size: 16),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 2,
                          max: 20,
                          divisions: 9,
                          activeColor: _selectedColor == Colors.white ? Colors.grey : _selectedColor,
                          inactiveColor: Colors.white24,
                          onChanged: (v) => setState(() => _strokeWidth = v),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${_strokeWidth.round()}px',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
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
}
