import 'dart:async';
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
}

class SavedProvider with ChangeNotifier {
  List<SavedItem> _items = [];
  dynamic _db;
  bool _isReady = false;

  List<SavedItem> get items => List.unmodifiable(_items);
  bool get isReady => _isReady;

  Future<void> init() async {
    try {
      final completer = Completer<void>();
      final request = html.window.indexedDB!.open(
        'pdf_sw411_saved',
        version: 1,
        onUpgradeNeeded: (e) {
          final req = (e.target as dynamic);
          final db = req.result;
          if (!(db.objectStoreNames as dynamic).contains('pdfs')) {
            db.createObjectStore('pdfs', keyPath: 'id');
          }
        },
      );

      (request as dynamic).onSuccess.listen((_) {
        _db = (request as dynamic).result;
        if (!completer.isCompleted) completer.complete();
      });

      (request as dynamic).onError.listen((_) {
        if (!completer.isCompleted) {
          completer.completeError('IndexedDB not available');
        }
      });

      await completer.future;
      await _loadItems();
      _isReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SavedProvider init: $e');
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> _loadItems() async {
    if (_db == null) return;
    try {
      final tx = _db.transaction('pdfs', 'readonly');
      final store = tx.objectStore('pdfs');
      final request = store.getAll();

      final completer = Completer<List<SavedItem>>();
      request.onSuccess.listen((_) {
        final List raw = (request.result as List?) ?? [];
        final list = raw.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return SavedItem(
            id: m['id'] as String,
            name: m['name'] as String,
            date: DateTime.parse(m['date'] as String),
            size: m['size'] as int,
          );
        }).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        completer.complete(list);
      });
      request.onError.listen((_) => completer.complete([]));

      _items = await completer.future;
    } catch (e) {
      debugPrint('_loadItems: $e');
    }
  }

  Future<void> save(String name, Uint8List bytes) async {
    if (_db == null) return;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final tx = _db.transaction('pdfs', 'readwrite');
      final store = tx.objectStore('pdfs');
      store.put({
        'id': id,
        'name': name,
        'bytes': bytes,
        'date': DateTime.now().toIso8601String(),
        'size': bytes.length,
      });
      await _loadItems();
      notifyListeners();
    } catch (e) {
      debugPrint('save: $e');
    }
  }

  Future<Uint8List?> getBytes(String id) async {
    if (_db == null) return null;
    try {
      final tx = _db.transaction('pdfs', 'readonly');
      final store = tx.objectStore('pdfs');
      final request = store.getObject(id);

      final completer = Completer<Uint8List?>();
      request.onSuccess.listen((_) {
        final r = request.result as Map?;
        completer.complete(r != null ? r['bytes'] as Uint8List : null);
      });
      request.onError.listen((_) => completer.complete(null));
      return completer.future;
    } catch (e) {
      return null;
    }
  }

  Future<void> remove(String id) async {
    if (_db == null) return;
    try {
      final tx = _db.transaction('pdfs', 'readwrite');
      final store = tx.objectStore('pdfs');
      store.delete(id);
      await _loadItems();
      notifyListeners();
    } catch (e) {
      debugPrint('remove: $e');
    }
  }
}
