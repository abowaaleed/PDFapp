import 'dart:typed_data';
import 'text_element.dart';

class ImageItem {
  final Uint8List bytes;
  final List<TextElement> textElements;

  ImageItem({
    required this.bytes,
    List<TextElement>? textElements,
  }) : textElements = textElements ?? [];

  bool get hasTexts => textElements.isNotEmpty;
}
