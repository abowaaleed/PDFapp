import 'dart:ui';

class TextElement {
  String text;
  double x;
  double y;
  double fontSize;
  String fontFamily;
  String colorHex;
  double opacity;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  int textAlign;
  double rotation;
  double boxWidth;
  double boxHeight;
  String? backgroundColorHex;
  double backgroundOpacity;

  TextElement({
    this.text = '',
    this.x = 0,
    this.y = 0,
    this.fontSize = 24,
    this.fontFamily = 'Cairo',
    this.colorHex = '#000000',
    this.opacity = 1.0,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textAlign = 1,
    this.rotation = 0,
    this.boxWidth = 200,
    this.boxHeight = 60,
    this.backgroundColorHex,
    this.backgroundOpacity = 0.5,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  set color(Color c) {
    colorHex = '#${c.value.toRadixString(16).substring(2)}';
  }

  Color? get backgroundColor {
    if (backgroundColorHex == null) return null;
    final hex = backgroundColorHex!.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  TextAlign get alignment {
    switch (textAlign) {
      case 0:
        return TextAlign.left;
      case 2:
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'colorHex': colorHex,
        'opacity': opacity,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'textAlign': textAlign,
        'rotation': rotation,
        'boxWidth': boxWidth,
        'boxHeight': boxHeight,
        'backgroundColorHex': backgroundColorHex,
        'backgroundOpacity': backgroundOpacity,
      };

  factory TextElement.fromJson(Map<String, dynamic> j) => TextElement(
        text: j['text'] ?? '',
        x: (j['x'] ?? 0).toDouble(),
        y: (j['y'] ?? 0).toDouble(),
        fontSize: (j['fontSize'] ?? 24).toDouble(),
        fontFamily: j['fontFamily'] ?? 'Cairo',
        colorHex: j['colorHex'] ?? '#000000',
        opacity: (j['opacity'] ?? 1.0).toDouble(),
        isBold: j['isBold'] ?? false,
        isItalic: j['isItalic'] ?? false,
        isUnderline: j['isUnderline'] ?? false,
        textAlign: j['textAlign'] ?? 1,
        rotation: (j['rotation'] ?? 0).toDouble(),
        boxWidth: (j['boxWidth'] ?? 200).toDouble(),
        boxHeight: (j['boxHeight'] ?? 60).toDouble(),
        backgroundColorHex: j['backgroundColorHex'],
        backgroundOpacity: (j['backgroundOpacity'] ?? 0.5).toDouble(),
      );

  TextElement copy() => TextElement.fromJson(toJson());
}
