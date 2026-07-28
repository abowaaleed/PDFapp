import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SavedItem {
  final String id;
  final String name;
  final DateTime date;
  final int size;

  SavedItem({
    required this.id,
    required this.name,
    required this.date,
    required this.size,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'size': size,
      };

  factory SavedItem.fromMap(Map<String, dynamic> m) => SavedItem(
        id: m['id'] as String,
        name: m['name'] as String,
        date: DateTime.parse(m['date'] as String),
        size: m['size'] as int,
      );
}

class SavedProvider with ChangeNotifier {
  static const _storageKey = 'pdf_sw411_saved';
  static const _bytesKey = 'pdf_sw411_bytes';
  List<SavedItem> _items = [];
  bool _isReady = false;

  List<SavedItem> get items => List.unmodifiable(_items);
  bool get isReady => _isReady;

  Future<void> init() async {
    _loadItems();
    _isReady = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> _getStoredList() {
    try {
      final json = html.window.localStorage[_storageKey];
      if (json == null || json.isEmpty) return [];
      final List data = jsonDecode(json);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('_getStoredList: $e');
      return [];
    }
  }

  Map<String, String> _getStoredBytes() {
    try {
      final json = html.window.localStorage[_bytesKey];
      if (json == null || json.isEmpty) return {};
      final Map data = jsonDecode(json);
      return data.cast<String, String>();
    } catch (e) {
      debugPrint('_getStoredBytes: $e');
      return {};
    }
  }

  void _saveBytesMap(Map<String, String> bytesMap) {
    try {
      html.window.localStorage[_bytesKey] = jsonEncode(bytesMap);
    } catch (e) {
      debugPrint('_saveBytesMap: $e');
    }
  }

  void _loadItems() {
    final stored = _getStoredList();
    _items = stored.map((e) => SavedItem.fromMap(e)).toList();
    _items.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> save(String name, Uint8List bytes) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final item = SavedItem(
        id: id,
        name: name,
        date: DateTime.now(),
        size: bytes.length,
      );

      final list = _getStoredList();
      list.insert(0, item.toMap());

      final bytesMap = _getStoredBytes();
      bytesMap[id] = base64Encode(bytes);

      _saveBytesMap(bytesMap);

      html.window.localStorage[_storageKey] = jsonEncode(list);

      _loadItems();
      notifyListeners();
    } catch (e) {
      debugPrint('SavedProvider.save: $e');
    }
  }

  Future<Uint8List?> getBytes(String id) async {
    try {
      final bytesMap = _getStoredBytes();
      final b64 = bytesMap[id];
      if (b64 == null) return null;
      return base64Decode(b64);
    } catch (e) {
      debugPrint('SavedProvider.getBytes: $e');
      return null;
    }
  }

  Future<void> remove(String id) async {
    try {
      final list = _getStoredList();
      list.removeWhere((e) => e['id'] == id);
      html.window.localStorage[_storageKey] = jsonEncode(list);

      final bytesMap = _getStoredBytes();
      bytesMap.remove(id);
      _saveBytesMap(bytesMap);

      _loadItems();
      notifyListeners();
    } catch (e) {
      debugPrint('SavedProvider.remove: $e');
    }
  }
}
