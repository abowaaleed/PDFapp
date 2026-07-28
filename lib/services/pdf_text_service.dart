import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import '../models/extracted_page.dart';

@JS('PDFUtils.extractText')
external JSPromise<JSString> _extractText(JSAny data);

class PdfTextService {
  static Future<List<ExtractedPage>> extractText(Uint8List pdfBytes) async {
    final jsResult = await _extractText(pdfBytes.toJS).toDart;
    final jsonStr = jsResult?.toDart ?? '{}';
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception(data['error']);
    }

    final pagesJson = data['pages'] as List<dynamic>;
    return pagesJson.asMap().entries.map((e) {
      final text = e.value as String;
      return ExtractedPage(
        pageNumber: e.key + 1,
        text: text,
        confidence: text.isNotEmpty ? 100 : 0,
        isScanned: text.trim().isEmpty,
      );
    }).toList();
  }
}
