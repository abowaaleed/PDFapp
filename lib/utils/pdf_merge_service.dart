import 'dart:js_interop';
import 'dart:typed_data';

@JS('PDFMerge.mergeFiles')
external JSPromise<JSUint8Array> _mergeFiles(JSArray<JSUint8Array> files);

class PdfMergeService {
  static Future<Uint8List> mergePdfs(List<Uint8List> pdfList) async {
    if (pdfList.isEmpty) throw Exception('لا توجد ملفات للدمج');
    if (pdfList.length == 1) return pdfList[0];

    try {
      final jsFiles = pdfList.map((b) => b.toJS).toList().toJS;
      final result = await _mergeFiles(jsFiles).toDart;
      final bytes = result?.toDart;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('فشل إنشاء الملف المدمج');
      }
      return bytes;
    } catch (e) {
      throw Exception('تعذر دمج الملفات: $e');
    }
  }
}
