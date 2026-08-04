import 'dart:typed_data';

class PdfMergeService {
  static Future<Uint8List> mergePdfs(List<Uint8List> pdfList) async {
    if (pdfList.isEmpty) throw Exception('No PDFs to merge');
    if (pdfList.length == 1) return pdfList[0];

    final List<_PdfInfo> infos = [];
    for (final pdf in pdfList) {
      infos.add(_PdfInfo(pdf));
    }

    int maxObjId = 0;
    for (final info in infos) {
      info.parse();
      if (info.maxObjectId > maxObjId) {
        maxObjId = info.maxObjectId;
      }
    }

    int idOffset = maxObjId + 1;
    final List<int> output = [];

    output.addAll(_ascii('%PDF-1.4\n'));

    final List<_XrefEntry> xrefEntries = [];
    int currentOffset = output.length;

    for (int fileIdx = 0; fileIdx < infos.length; fileIdx++) {
      final info = infos[fileIdx];
      final int idBase = fileIdx == 0 ? 0 : idOffset * fileIdx;

      for (final obj in info.objects) {
        final int newId = obj.id + idBase;
        final int objOffset = currentOffset;

        final objBytes = info.extractObject(obj);
        if (objBytes.isNotEmpty) {
          final header = _ascii('${newId} 0 obj\n');
          final trailer = _ascii('\nendobj\n');

          final combined = Uint8List(header.length + objBytes.length + trailer.length);
          combined.setAll(0, header);
          combined.setAll(header.length, objBytes);
          combined.setAll(header.length + objBytes.length, trailer);

          output.addAll(combined);
          currentOffset += combined.length;

          xrefEntries.add(_XrefEntry(
            byteOffset: objOffset,
            generation: 0,
            inUse: true,
          ));
        }
      }
    }

    final int xrefOffset = currentOffset;

    output.addAll(_ascii('xref\n'));
    output.addAll(_ascii('0 ${xrefEntries.length + 1}\n'));

    final firstEntry = _xrefEntryString(0, 65535, false);
    output.addAll(_ascii(firstEntry));
    for (final entry in xrefEntries) {
      output.addAll(_ascii(_xrefEntryString(entry.byteOffset, entry.generation, entry.inUse)));
    }

    output.addAll(_ascii('trailer\n'));
    output.addAll(_ascii('<< /Size ${xrefEntries.length + 1} /Root 1 0 R >>\n'));
    output.addAll(_ascii('startxref\n'));
    output.addAll(_ascii('$xrefOffset\n'));
    output.addAll(_ascii('%%EOF\n'));

    return Uint8List.fromList(output);
  }

  static List<int> _ascii(String s) {
    final codeUnits = <int>[];
    for (int i = 0; i < s.length; i++) {
      codeUnits.add(s.codeUnitAt(i));
    }
    return codeUnits;
  }

  static String _xrefEntryString(int offset, int generation, bool inUse) {
    final offsetStr = offset.toString().padLeft(10, '0');
    final genStr = generation.toString().padLeft(5, '0');
    final typeChar = inUse ? 'n' : 'f';
    return '$offsetStr $genStr $typeChar \n';
  }
}

class _XrefEntry {
  final int byteOffset;
  final int generation;
  final bool inUse;

  _XrefEntry({
    required this.byteOffset,
    required this.generation,
    required this.inUse,
  });
}

class _PdfObj {
  final int id;
  final int startOffset;
  final int endOffset;

  _PdfObj(this.id, this.startOffset, this.endOffset);
}

class _PdfInfo {
  final Uint8List bytes;
  int maxObjectId = 0;
  List<_PdfObj> objects = [];

  _PdfInfo(this.bytes);

  void parse() {
    _findObjects();
    _findTrailer();
  }

  void _findObjects() {
    final str = String.fromCharCodes(bytes);
    objects.clear();
    maxObjectId = 0;

    final objPattern = RegExp(r'(\d+)\s+(\d+)\s+obj');
    for (final match in objPattern.allMatches(str)) {
      final objId = int.parse(match.group(1)!);
      final start = match.start;

      int end = str.indexOf('endobj', start);
      if (end == -1) end = str.indexOf('%%EOF', start);
      if (end == -1) end = bytes.length;
      end += 6;

      objects.add(_PdfObj(objId, start, end));
      if (objId > maxObjectId) maxObjectId = objId;
    }

    objects.sort((a, b) => a.startOffset.compareTo(b.startOffset));
  }

  void _findTrailer() {}

  Uint8List extractObject(_PdfObj obj) {
    if (obj.endOffset > bytes.length) return Uint8List(0);
    final start = obj.startOffset;
    final end = obj.endOffset;
    if (end <= start) return Uint8List(0);
    return bytes.sublist(start, end);
  }
}
