import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

Uint8List _processImage(Map<String, dynamic> params) {
  final Uint8List bytes = params['bytes'] as Uint8List;
  final int quality = params['quality'] as int;
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

class PdfHelper {
  static Future<Uint8List> generatePdf({
    required List<Uint8List> images,
    required double quality,
    double resizeFactor = 1.0,
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
          'resizeFactor': resizeFactor,
        });
      } catch (e) {
        final decoded = img.decodeImage(images[i]);
        if (decoded == null) {
          onProgress?.call(i + 1, images.length);
          continue;
        }
        img.Image processed = decoded;
        if (resizeFactor < 0.99) {
          final newW = (decoded.width * resizeFactor).round().clamp(1, decoded.width);
          final newH = (decoded.height * resizeFactor).round().clamp(1, decoded.height);
          processed = img.copyResize(decoded, width: newW, height: newH);
        }
        processedBytes = Uint8List.fromList(img.encodeJpg(processed, quality: qualityInt));
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
    final double originalSizeKb =
        images.fold(0.0, (sum, item) => sum + item.length) / 1024;
    final double sizeRatio = targetSizeKb / originalSizeKb;

    double resizeFactor =
        sizeRatio >= 0.5 ? 1.0 : (sizeRatio * 2).clamp(0.05, 1.0);

    double low = 0.05;
    double high = 1.0;
    Uint8List bestPdf = Uint8List(0);
    const int maxIterations = 8;
    final int totalSteps = maxIterations * images.length;

    for (int i = 0; i < maxIterations; i++) {
      await Future.delayed(const Duration(milliseconds: 50));

      double mid = (low + high) / 2;
      bestPdf = await generatePdf(
        images: images,
        quality: mid,
        resizeFactor: resizeFactor,
        onProgress: onProgress != null
            ? (current, total) =>
                onProgress((i * total) + current, totalSteps)
            : null,
      );

      if (bestPdf.length / 1024 > targetSizeKb) {
        high = mid;
      } else {
        low = mid;
      }
    }

    if (bestPdf.length / 1024 > targetSizeKb * 1.3) {
      resizeFactor *=
          (targetSizeKb / (bestPdf.length / 1024) * 0.9).clamp(0.3, 0.8);
      const int extra = 4;
      final int extraSteps = extra * images.length;

      for (int i = 0; i < extra; i++) {
        double mid = (low + high) / 2;
        bestPdf = await generatePdf(
          images: images,
          quality: mid,
          resizeFactor: resizeFactor,
          onProgress: onProgress != null
              ? (current, total) => onProgress(
                  totalSteps + (i * total) + current,
                  totalSteps + extraSteps)
              : null,
        );
        if (bestPdf.length / 1024 > targetSizeKb) {
          high = mid;
        } else {
          low = mid;
        }
      }
    }

    return bestPdf;
  }

  static double estimateSizeKb(List<Uint8List> images, double quality) {
    double totalOriginalSize =
        images.fold(0.0, (sum, item) => sum + item.length);
    double estimatedSize = totalOriginalSize * (0.02 + (quality * 0.4));
    return estimatedSize / 1024;
  }
}
