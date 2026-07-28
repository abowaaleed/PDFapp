import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../models/extracted_page.dart';
import '../../services/pdf_text_service.dart';
import '../../services/ocr_service.dart';
import '../../services/docx_service.dart';
import '../../providers/saved_provider.dart';
import '../../utils/pdf_helper.dart';

class ExtractScreen extends StatefulWidget {
  const ExtractScreen({super.key});

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends State<ExtractScreen> {
  Uint8List? _pdfBytes;
  String? _fileName;
  bool _isExtracting = false;
  bool _isOcrRunning = false;
  String _progressMsg = '';
  int _ocrProgress = 0;
  int _ocrTotal = 0;
  List<ExtractedPage>? _pages;
  bool _needOcr = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pdfBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
        _pages = null;
        _needOcr = false;
      });
      _extractText();
    }
  }

  Future<void> _extractText() async {
    if (_pdfBytes == null) return;
    setState(() {
      _isExtracting = true;
      _progressMsg = 'جاري تحليل الملف...';
    });

    try {
      final pages = await PdfTextService.extractText(_pdfBytes!);

      final hasText = pages.any((p) => p.text.trim().isNotEmpty);
      if (hasText) {
        setState(() {
          _pages = pages;
          _needOcr = false;
          _isExtracting = false;
        });
      } else {
        setState(() {
          _pages = pages;
          _needOcr = true;
          _isExtracting = false;
        });
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _needOcr = true;
        _progressMsg = '';
      });
    }
  }

  Future<void> _runOcr() async {
    if (_pdfBytes == null) return;
    setState(() {
      _isOcrRunning = true;
      _pages = [];
    });

    try {
      final document = await PdfDocument.openData(_pdfBytes!);
      final total = document.pagesCount;
      final ocrPages = <ExtractedPage>[];

      for (int i = 1; i <= total; i++) {
        setState(() {
          _ocrProgress = i;
          _ocrTotal = total;
          _progressMsg = 'جاري التعرف على النص - صفحة $i من $total';
        });

        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageImageFormat.jpeg,
          quality: 80,
        );

        if (pageImage != null) {
          final text = await OcrService.recognizeImage(pageImage.bytes);
          ocrPages.add(ExtractedPage(
            pageNumber: i,
            text: text,
            isScanned: true,
            confidence: text.isNotEmpty ? 70 : 0,
          ));
        } else {
          ocrPages.add(ExtractedPage(pageNumber: i, isScanned: true));
        }

        await page.close();
      }

      await document.close();

      setState(() {
        _pages = ocrPages;
        _isOcrRunning = false;
        _needOcr = false;
        _progressMsg = '';
      });
    } catch (e) {
      setState(() {
        _isOcrRunning = false;
        _progressMsg = 'خطأ في OCR: $e';
      });
    }
  }

  String get _fullText => _pages?.map((p) => p.text).join('\n\n---\n\n') ?? '';

  Future<void> _copyToClipboard() async {
    if (_pages == null) return;
    final clipboard = html.window.navigator.clipboard;
    if (clipboard != null) {
      await clipboard.writeText(_fullText);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ النص إلى الحافظة')),
        );
      }
    }
  }

  Future<void> _exportDocx() async {
    if (_pages == null) return;
    final texts = _pages!.map((p) => p.text).toList();
    final bytes = DocxService.generateDocx(texts);

    final filename = (_fileName ?? 'document').replaceAll('.pdf', '') + '.docx';
    PdfHelper.openPdfInNewTab(bytes, filename);

    if (context.mounted) {
      final savedProvider = Provider.of<SavedProvider>(context, listen: false);
      await savedProvider.save(filename, bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ ملف $filename')),
        );
      }
    }
  }

  Future<void> _exportTxt() async {
    if (_pages == null) return;
    final text = _fullText;
    final bytes = Uint8List.fromList(text.codeUnits);

    final filename = (_fileName ?? 'document').replaceAll('.pdf', '') + '.txt';
    PdfHelper.openPdfInNewTab(bytes, filename);

    if (context.mounted) {
      final savedProvider = Provider.of<SavedProvider>(context, listen: false);
      await savedProvider.save(filename, bytes);
    }
  }

  void _updatePageText(int index, String newText) {
    if (_pages == null || index >= _pages!.length) return;
    setState(() {
      _pages![index].text = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل PDF إلى نص'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isExtracting || _isOcrRunning) {
      return _buildProgress();
    }

    if (_pdfBytes == null) {
      return _buildEmptyState();
    }

    if (_needOcr) {
      return _buildOcrPrompt();
    }

    if (_pages != null) {
      return _buildPreview();
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.text_snippet, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('اختر ملف PDF لاستخراج النص منه',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.file_open),
            label: const Text('اختيار ملف PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(_progressMsg,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          if (_ocrTotal > 0) ...[
            const SizedBox(height: 16),
            Text('$_ocrProgress / $_ocrTotal',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5F))),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _ocrProgress / _ocrTotal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOcrPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_search, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('لم يتم العثور على نصوص قابلة للاستخراج المباشر',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('يبدو أن الملف ممسوح ضوئياً',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _runOcr,
            icon: const Icon(Icons.text_fields),
            label: const Text('استخدام التعرف الضوئي (OCR)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _pickFile,
            child: const Text('اختيار ملف آخر'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_pages == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text('تم استخراج ${_pages!.length} صفحة',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_pages!.any((p) => p.isScanned))
                Text('(جودة منخفضة)',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700])),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _pages!.length,
            itemBuilder: (context, index) {
              final page = _pages![index];
              final hasText = page.text.trim().isNotEmpty;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('صفحة ${page.pageNumber}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (!hasText)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('فارغة',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.orange[800])),
                            ),
                          if (page.isScanned && hasText)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('OCR',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.orange[800])),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: page.text),
                        maxLines: null,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                        onChanged: (v) => _updatePageText(index, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportTxt,
                    icon: const Icon(Icons.text_snippet, size: 18),
                    label: const Text('.txt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportDocx,
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('.docx'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A5F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
