import 'dart:typed_data';
import 'package:flutter/material.dart';

class PdfProvider with ChangeNotifier {
  List<Uint8List> _images = [];
  double _compressionQuality = 0.5;
  double _targetSizeKb = 1000; // Default 1MB
  bool _isProcessing = false;

  List<Uint8List> get images => _images;
  double get compressionQuality => _compressionQuality;
  double get targetSizeKb => _targetSizeKb;
  bool get isProcessing => _isProcessing;

  void addImages(List<Uint8List> newImages) {
    _images.addAll(newImages);
    notifyListeners();
  }

  void removeImage(int index) {
    _images.removeAt(index);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Uint8List item = _images.removeAt(oldIndex);
    _images.insert(newIndex, item);
    notifyListeners();
  }

  void updateAllImages(List<Uint8List> newImages) {
    _images = newImages;
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
    _images = [];
    notifyListeners();
  }
}
