import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/text_element.dart';
import '../../providers/pdf_provider.dart';

class TextEditorScreen extends StatefulWidget {
  final int imageIndex;
  const TextEditorScreen({super.key, required this.imageIndex});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  late List<TextElement> _elements;
  int _selectedIndex = -1;
  bool _isTyping = false;
  final TextEditingController _textController = TextEditingController();
  final List<List<TextElement>> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PdfProvider>(context, listen: false);
    _elements =
        provider.items[widget.imageIndex].textElements.map((e) => e.copy()).toList();
    _saveHistory();
  }

  void _saveHistory() {
    _history.removeRange(_historyIndex + 1, _history.length);
    _history.add(_elements.map((e) => e.copy()).toList());
    _historyIndex = _history.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      setState(() {
        _elements = _history[_historyIndex].map((e) => e.copy()).toList();
        _selectedIndex = -1;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      setState(() {
        _elements = _history[_historyIndex].map((e) => e.copy()).toList();
        _selectedIndex = -1;
      });
    }
  }

  void _addText() {
    final element = TextElement(
      x: 50,
      y: 100,
      text: '',
      fontSize: 28,
    );
    setState(() {
      _elements.add(element);
      _selectedIndex = _elements.length - 1;
      _textController.text = '';
      _isTyping = true;
    });
  }

  void _deleteSelected() {
    if (_selectedIndex >= 0 && _selectedIndex < _elements.length) {
      setState(() {
        _elements.removeAt(_selectedIndex);
        _selectedIndex = -1;
        _isTyping = false;
      });
      _saveHistory();
    }
  }

  void _save() {
    if (_selectedIndex >= 0 && _selectedIndex < _elements.length) {
      _elements[_selectedIndex].text = _textController.text;
    }
    final provider = Provider.of<PdfProvider>(context, listen: false);
    provider.updateTextElements(widget.imageIndex, _elements);
    Navigator.pop(context);
  }

  void _onTapElement(int index) {
    if (_isTyping && _selectedIndex >= 0) {
      _elements[_selectedIndex].text = _textController.text;
    }
    setState(() {
      _selectedIndex = index;
      _textController.text = _elements[index].text;
      _isTyping = false;
    });
  }

  void _onTapBackground() {
    if (_isTyping && _selectedIndex >= 0 && _selectedIndex < _elements.length) {
      _elements[_selectedIndex].text = _textController.text;
      _saveHistory();
    }
    setState(() {
      _selectedIndex = -1;
      _isTyping = false;
    });
    FocusScope.of(context).unfocus();
  }

  TextElement? get _selected =>
      _selectedIndex >= 0 && _selectedIndex < _elements.length
          ? _elements[_selectedIndex]
          : null;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PdfProvider>(context, listen: false);
    final imageBytes = provider.items[widget.imageIndex].bytes;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('تحرير النصوص', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.undo,
                color: _historyIndex > 0 ? Colors.white : Colors.grey),
            onPressed: _historyIndex > 0 ? _undo : null,
          ),
          IconButton(
            icon: Icon(Icons.redo,
                color: _historyIndex < _history.length - 1
                    ? Colors.white
                    : Colors.grey),
            onPressed:
                _historyIndex < _history.length - 1 ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: _addText,
          ),
          if (_selected != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelected,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('حفظ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _onTapBackground,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.memory(imageBytes,
                            width: constraints.maxWidth,
                            fit: BoxFit.fitWidth),
                        ...List.generate(_elements.length, (i) {
                          final el = _elements[i];
                          final sel = i == _selectedIndex;
                          return Positioned(
                            left: el.x,
                            top: el.y,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                setState(() {
                                  el.x += d.delta.dx;
                                  el.y += d.delta.dy;
                                });
                              },
                              onPanEnd: (_) => _saveHistory(),
                              onDoubleTap: () {
                                _onTapElement(i);
                                setState(() => _isTyping = true);
                              },
                              onTap: () => _onTapElement(i),
                              child: _buildTextWidget(el, sel, constraints.maxWidth),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (_selected != null) _buildPropertiesPanel(),
        ],
      ),
    );
  }

  Widget _buildTextWidget(TextElement el, bool selected, double maxWidth) {
    final displayText = el.text.isEmpty ? 'اكتب هنا...' : el.text;

    Widget textWidget = Text(
      displayText,
      style: GoogleFonts.getFont(
        el.fontFamily,
        fontSize: el.fontSize,
        color: el.color.withOpacity(el.opacity),
        fontWeight: el.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            el.isUnderline ? TextDecoration.underline : TextDecoration.none,
      ),
      textAlign: el.alignment,
      maxLines: null,
    );

    if (el.backgroundColorHex != null) {
      textWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: el.backgroundColor!.withOpacity(el.backgroundOpacity),
        child: textWidget,
      );
    }

    return Transform.rotate(
      angle: el.rotation * 3.14159265 / 180,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 80,
          maxWidth: maxWidth - el.x - 20,
        ),
        padding: const EdgeInsets.all(4),
        decoration: selected
            ? BoxDecoration(
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              )
            : null,
        child: textWidget,
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    final el = _selected!;
    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildField('الحجم', '${el.fontSize.round()}', () {
              _showSliderDialog('حجم الخط', el.fontSize, 10, 80, (v) {
                setState(() => el.fontSize = v);
              });
            }),
            const SizedBox(width: 8),
            _buildField('اللون', '', () {
              _showColorPicker(el);
            }, colorDot: el.color),
            const SizedBox(width: 8),
            _buildField('الخط', el.fontFamily, () {
              _showFontPicker(el);
            }),
            const SizedBox(width: 8),
            _buildField(
                'الشفافية', '${(el.opacity * 100).round()}%', () {
              _showSliderDialog(
                  'الشفافية', el.opacity * 100, 10, 100, (v) {
                setState(() => el.opacity = v / 100);
              });
            }),
            const SizedBox(width: 8),
            _buildField('الدوران', '${el.rotation.round()}°', () {
              _showSliderDialog('الدوران', el.rotation, -180, 180, (v) {
                setState(() => el.rotation = v);
              });
            }),
            const SizedBox(width: 8),
            _buildAlignButton(el),
            const SizedBox(width: 8),
            _buildStyleButton(el),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value, VoidCallback onTap,
      {Color? colorDot}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (colorDot != null)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54),
                ),
              )
            else
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignButton(TextElement el) {
    final icons = [
      Icons.format_align_left,
      Icons.format_align_center,
      Icons.format_align_right,
    ];
    return GestureDetector(
      onTap: () {
        setState(() => el.textAlign = (el.textAlign + 1) % 3);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[el.textAlign], color: Colors.white, size: 20),
            const SizedBox(height: 2),
            const Text('محاذاة',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleButton(TextElement el) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _styleIcon(Icons.format_bold, el.isBold, () {
          setState(() => el.isBold = !el.isBold);
        }),
        _styleIcon(Icons.format_italic, el.isItalic, () {
          setState(() => el.isItalic = !el.isItalic);
        }),
        _styleIcon(Icons.format_underlined, el.isUnderline, () {
          setState(() => el.isUnderline = !el.isUnderline);
        }),
      ],
    );
  }

  Widget _styleIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A3A5F) : Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  void _showSliderDialog(
      String title, double value, double min, double max, ValueChanged<double> onChange) {
    double temp = value;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${temp.round()}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Slider(
                value: temp,
                min: min,
                max: max,
                onChanged: (v) {
                  setDialogState(() => temp = v);
                  setState(() => onChange(v));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _saveHistory();
              Navigator.pop(ctx);
            },
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(TextElement el) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      const Color(0xFF1A3A5F),
      const Color(0xFFD4AF37),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر اللون'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors
              .map((c) => GestureDetector(
                    onTap: () {
                      setState(() => el.color = c);
                      Navigator.pop(ctx);
                      _saveHistory();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showFontPicker(TextElement el) {
    final fonts = ['Cairo', 'Tajawal', 'Almarai', 'Roboto', 'Arial'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر الخط'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts
              .map((f) => ListTile(
                    title: Text(f, style: TextStyle(fontFamily: f)),
                    trailing: el.fontFamily == f
                        ? const Icon(Icons.check, color: Color(0xFF1A3A5F))
                        : null,
                    onTap: () {
                      setState(() => el.fontFamily = f);
                      Navigator.pop(ctx);
                      _saveHistory();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
