import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../../models/image_item.dart';
import '../../models/text_element.dart';

Uint8List _processImage(Map<String, dynamic> params) {
  final Uint8List bytes = params['bytes'] as Uint8List;
  final int quality = (params['quality'] as int).clamp(40, 100);
  final double resizeFactor = (params['resizeFactor'] as num).toDouble();

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return Uint8List(0);

  img.Image processed = decoded;
  if (resizeFactor < 0.99) {
    final newW = (decoded.width * resizeFactor).round().clamp(1, decoded.width);
    final newH = (decoded.height * resizeFactor).round().clamp(1, decoded.height);
    processed = img.copyResize(decoded, width: newW, height: newH);
  }

  return Uint8List.fromList(img.encodeJpg(processed, quality: quality));
}

Future<Uint8List> _renderTextOnImage(Map<String, dynamic> params) async {
  final Uint8List imageBytes = params['bytes'] as Uint8List;
  final List<dynamic> textsJson = params['textElements'] as List<dynamic>;

  if (textsJson.isEmpty) return imageBytes;

  final decoded = img.decodeImage(Uint8List.fromList(imageBytes));
  if (decoded == null) return imageBytes;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final imageWidth = decoded.width.toDouble();
  final imageHeight = decoded.height.toDouble();

  canvas.drawImage(
    await _decodeUiImage(imageBytes),
    Offset.zero,
    Paint(),
  );

  for (final tj in textsJson) {
    final el = TextElement.fromJson(Map<String, dynamic>.from(tj));
    if (el.text.isEmpty) continue;

    canvas.save();
    canvas.translate(el.x + el.boxWidth / 2, el.y + el.boxHeight / 2);
    canvas.rotate(el.rotation * 3.14159265 / 180);
    canvas.translate(-el.boxWidth / 2, -el.boxHeight / 2);

    if (el.backgroundColorHex != null) {
      final bgPaint = Paint()
        ..color = el.backgroundColor!.withOpacity(el.backgroundOpacity);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, el.boxWidth, el.boxHeight),
        bgPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: el.text,
        style: TextStyle(
          color: el.color.withOpacity(el.opacity),
          fontSize: el.fontSize,
          fontWeight: el.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
          decoration:
              el.isUnderline ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: el.alignment,
      maxLines: null,
    );

    textPainter.layout(maxWidth: el.boxWidth);
    textPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }

  final picture = recorder.endRecording();
  final renderedImage = await picture.toImage(
    imageWidth.toInt(),
    imageHeight.toInt(),
  );

  final byteData = await renderedImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  return byteData!.buffer.asUint8List();
}

Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

class PdfHelper {
  static Future<Uint8List> generatePdf({
    required List<ImageItem> imageItems,
    required double quality,
    double resizeFactor = 1.0,
    void Function(int current, int total)? onProgress,
  }) async {
    final pdf = pw.Document();
    final qualityInt = (quality * 100).toInt().clamp(40, 100);

    for (int i = 0; i < imageItems.length; i++) {
      final item = imageItems[i];

      Uint8List processedBytes;
      try {
        processedBytes = await compute(_processImage, {
          'bytes': item.bytes,
          'quality': qualityInt,
          'resizeFactor': resizeFactor,
        });
      } catch (e) {
        final decoded = img.decodeImage(item.bytes);
        if (decoded == null) {
          onProgress?.call(i + 1, imageItems.length);
          continue;
        }
        img.Image processed = decoded;
        if (resizeFactor < 0.99) {
          final newW = (decoded.width * resizeFactor).round().clamp(1, decoded.width);
          final newH = (decoded.height * resizeFactor).round().clamp(1, decoded.height);
          processed = img.copyResize(decoded, width: newW, height: newH);
        }
        processedBytes =
            Uint8List.fromList(img.encodeJpg(processed, quality: qualityInt.clamp(40, 100)));
      }

      if (item.hasTexts && processedBytes.isNotEmpty) {
        try {
          processedBytes = await compute(_renderTextOnImage, {
            'bytes': processedBytes,
            'textElements': item.textElements.map((e) => e.toJson()).toList(),
          });
        } catch (_) {}
      }

      if (processedBytes.isNotEmpty) {
        final pdfImage = pw.MemoryImage(processedBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(0),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      onProgress?.call(i + 1, imageItems.length);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return pdf.save();
  }

  static Future<Uint8List> generatePdfWithTargetSize({
    required List<ImageItem> imageItems,
    required double targetSizeKb,
    void Function(int current, int total)? onProgress,
  }) async {
    final double originalSizeKb =
        imageItems.fold(0.0, (sum, item) => sum + item.bytes.length) / 1024;
    final double sizeRatio = targetSizeKb / originalSizeKb;

    if (sizeRatio >= 0.95) {
      return generatePdf(
        imageItems: imageItems,
        quality: 0.92,
        resizeFactor: 1.0,
        onProgress: onProgress,
      );
    }

    double resizeFactor = 1.0;
    if (sizeRatio < 0.15) {
      resizeFactor = (sizeRatio / 0.15).clamp(0.55, 1.0);
    }

    const int maxIterations = 10;
    final int totalSteps = maxIterations * imageItems.length;
    double low = 0.30;
    double high = 0.95;
    Uint8List bestPdf = Uint8List(0);

    for (int i = 0; i < maxIterations; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      double mid = (low + high) / 2;
      bestPdf = await generatePdf(
        imageItems: imageItems,
        quality: mid,
        resizeFactor: resizeFactor,
        onProgress: onProgress != null
            ? (current, total) =>
                onProgress((i * total) + current, totalSteps)
            : null,
      );
      final double currentSizeKb = bestPdf.length / 1024;
      if (currentSizeKb > targetSizeKb * 1.05) {
        high = mid;
      } else {
        low = mid;
      }
    }

    if (bestPdf.length / 1024 > targetSizeKb * 1.15 && resizeFactor > 0.55) {
      resizeFactor = (resizeFactor * 0.85).clamp(0.55, 1.0);
      for (int i = 0; i < 4; i++) {
        double mid = (low + high) / 2;
        bestPdf = await generatePdf(
          imageItems: imageItems,
          quality: mid,
          resizeFactor: resizeFactor,
          onProgress: onProgress != null
              ? (current, total) => onProgress(
                  totalSteps + (i * total) + current,
                  totalSteps + 4 * imageItems.length)
              : null,
        );
        if (bestPdf.length / 1024 > targetSizeKb * 1.05) {
          high = mid;
        } else {
          low = mid;
        }
      }
    }

    return bestPdf;
  }

  static double estimateSizeKb(List<ImageItem> imageItems, double quality) {
    double totalOriginalSize =
        imageItems.fold(0.0, (sum, item) => sum + item.bytes.length);
    double estimatedSize = totalOriginalSize * (0.02 + (quality * 0.4));
    return estimatedSize / 1024;
  }

  static void openPdfInNewTab(Uint8List pdfBytes, String filename) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  }

  static void downloadPdf(Uint8List pdfBytes, String filename) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> sharePdfBytes(Uint8List pdfBytes, String filename) async {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  }
}
