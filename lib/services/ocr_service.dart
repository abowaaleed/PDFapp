import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:typed_data';

@JS('PDFUtils.ocrImage')
external JSPromise<JSString> _ocrImage(JSString url, JSString lang);

class OcrService {
  static Future<String> recognizeImage(
    Uint8List imageBytes, {
    String lang = 'ara+eng',
    void Function(String status)? onProgress,
  }) async {
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    try {
      final jsResult = await _ocrImage(url.toJS, lang.toJS).toDart;
      final jsonStr = jsResult?.toDart ?? '{}';
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }
      return data['text'] as String;
    } finally {
      html.Url.revokeObjectUrl(url);
    }
  }
}
