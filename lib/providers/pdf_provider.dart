import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/image_item.dart';
import '../models/text_element.dart';

class PdfProvider with ChangeNotifier {
  List<ImageItem> _items = [];
  double _compressionQuality = 0.5;
  double _targetSizeKb = 1000;
  bool _isProcessing = false;

  List<ImageItem> get items => _items;
  bool get isProcessing => _isProcessing;
  double get compressionQuality => _compressionQuality;
  double get targetSizeKb => _targetSizeKb;

  List<Uint8List> get images => _items.map((e) => e.bytes).toList();

  void addImages(List<Uint8List> newImages) {
    _items.addAll(newImages.map((b) => ImageItem(bytes: b)));
    notifyListeners();
  }

  void removeImage(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    notifyListeners();
  }

  void updateTextElements(int index, List<TextElement> elements) {
    _items[index].textElements
      ..clear()
      ..addAll(elements);
    notifyListeners();
  }

  void setCompressionQuality(double quality) {
    _compressionQuality = quality;
    notifyListeners();
  }

  void setTargetSize(double size) {
    _targetSizeKb = size;
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void clearImages() {
    _items = [];
    notifyListeners();
  }
}
