import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

Uint8List _processImage(Map<String, dynamic> params) {
  final Uint8List bytes = params['bytes'] as Uint8List;
  final int quality = params['quality'] as int;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return Uint8List(0);

  return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
}

class PdfHelper {
  static Future<Uint8List> generatePdf({
    required List<Uint8List> images,
    required double quality,
    void Function(int current, int total)? onProgress,
  }) async {
    final pdf = pw.Document();
    final qualityInt = (quality * 100).toInt();

    for (int i = 0; i < images.length; i++) {
      Uint8List processedBytes;
      try {
        processedBytes = await compute(_processImage, {
          'bytes': images[i],
          'quality': qualityInt,
        });
      } catch (e) {
        final decoded = img.decodeImage(images[i]);
        processedBytes = decoded != null
            ? Uint8List.fromList(img.encodeJpg(decoded, quality: qualityInt))
            : Uint8List(0);
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

      onProgress?.call(i + 1, images.length);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return pdf.save();
  }

  static Future<Uint8List> generatePdfWithTargetSize({
    required List<Uint8List> images,
    required double targetSizeKb,
    void Function(int current, int total)? onProgress,
  }) async {
    double low = 0.05;
    double high = 1.0;
    Uint8List bestPdf = Uint8List(0);
    const int maxIterations = 4;

    for (int i = 0; i < maxIterations; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      double mid = (low + high) / 2;
      final int currentIteration = i + 1;
      bestPdf = await generatePdf(
        images: images,
        quality: mid,
        onProgress: onProgress != null
            ? (currentInIteration, totalInIteration) {
                onProgress(
                  ((currentIteration - 1) * totalInIteration) + currentInIteration,
                  maxIterations * totalInIteration,
                );
              }
            : null,
      );

      double currentSizeKb = bestPdf.length / 1024;

      if (currentSizeKb > targetSizeKb) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return bestPdf;
  }

  static double estimateSizeKb(List<Uint8List> images, double quality) {
    double totalOriginalSize = images.fold(0.0, (sum, item) => sum + item.length);
    double estimatedSize = totalOriginalSize * (0.02 + (quality * 0.4));
    return estimatedSize / 1024;
  }
}
