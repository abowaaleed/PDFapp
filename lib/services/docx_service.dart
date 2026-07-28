import 'dart:typed_data';
import 'package:docx_dart/docx_dart.dart';
import 'package:docx_dart/src/enum/text.dart' as dxt;
import 'package:docx_dart/src/oxml/document.dart';

class DocxService {
  static Uint8List generateDocx(List<String> pages) {
    final doc = loadDocxDocument();
    final ctBody = (doc.element as CT_Document).body;
    ctBody.clearContent();

    for (int i = 0; i < pages.length; i++) {
      if (pages[i].trim().isEmpty) continue;

      final para = doc.addParagraph();
      para.alignment = dxt.WD_PARAGRAPH_ALIGNMENT.RIGHT;
      para.addRun(pages[i]);

      if (i < pages.length - 1) {
        doc.addPageBreak();
      }
    }

    final bb = BytesBuilder();
    doc.save(bb);
    return bb.toBytes();
  }
}
