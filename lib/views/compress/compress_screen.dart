import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:typed_data';
import '../../utils/pdf_helper.dart';
import '../../widgets/loading_overlay.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  Uint8List? _originalPdfBytes;
  String? _fileName;
  int? _originalSize;
  double _targetSizeKb = 500;
  final TextEditingController _nameController = TextEditingController();

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['pdf'], 
        withData: true
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _originalPdfBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _originalSize = result.files.single.size;
          _targetSizeKb = (_originalSize! / 1024) * 0.5;
          _nameController.text = _fileName!.replaceAll('.pdf', '') + '_compressed';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في اختيار الملف: $e')));
      }
    }
  }

  Future<void> _compressPdf() async {
    if (_originalPdfBytes == null) return;
    
    // إظهار الروح (التحميل) فوراً
    LoadingDialog.show(context, 'Compressing PDF');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final document = await PdfDocument.openData(_originalPdfBytes!);
      List<Uint8List> pageImages = [];
      final int totalPages = document.pagesCount;
      final int totalSteps = totalPages * 2;

      for (int i = 1; i <= totalPages; i++) {
        final page = await document.getPage(i);

        final pageImage = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageImageFormat.jpeg,
          quality: 80,
        );

        if (pageImage != null) {
          pageImages.add(pageImage.bytes);
        }
        await page.close();

        LoadingDialog.updateProgress(i, totalSteps, message: 'قراءة الصفحات');
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await document.close();

      if (pageImages.isEmpty) throw 'لم يتم العثور على صفحات صالحة في الملف';

      double totalImgSize = pageImages.fold(0.0, (sum, item) => sum + item.length);
      double quality = ((_targetSizeKb * 1024) / totalImgSize).clamp(0.05, 0.9);

      final compressedPdf = await PdfHelper.generatePdf(
        images: pageImages,
        quality: quality,
        onProgress: (current, total) {
          LoadingDialog.updateProgress(
            totalPages + current,
            totalSteps,
            message: 'إنشاء PDF',
          );
        },
      );
      
      final filename = _nameController.text.isEmpty ? 'PDF-sw411_Compressed' : _nameController.text;
      
      PdfHelper.downloadPdf(compressedPdf, '$filename.pdf');
      
      if (mounted) {
        LoadingDialog.hide(context);
        _showResultDialog(_originalSize!, compressedPdf.length);
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('حدث خطأ أثناء الضغط'),
            content: Text('التفاصيل: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
          ),
        );
      }
    }
  }

  void _showResultDialog(int original, int compressed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تمت العملية بنجاح'),
        content: Text('نسبة الضغط المحققة: ${((original - compressed) / original * 100).toStringAsFixed(1)}%'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ضغط ملف PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home), 
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _originalPdfBytes == null ? _buildUploadState() : _buildCompressState(),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.picture_as_pdf_outlined, size: 100, color: Colors.grey[300]),
        const SizedBox(height: 24),
        const Text('اختر ملف PDF لتصغير حجمه', style: TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _pickPdf, 
          icon: const Icon(Icons.file_upload), 
          label: const Text('اختيار ملف PDF'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompressState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40), 
              title: Text(_fileName ?? '', overflow: TextOverflow.ellipsis), 
              subtitle: Text('${(_originalSize! / 1024).toStringAsFixed(1)} KB')
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController, 
            decoration: const InputDecoration(
              labelText: 'اسم الملف الجديد',
              border: OutlineInputBorder(),
            )
          ),
          const SizedBox(height: 32),
          const Text('الحجم المستهدف:', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _targetSizeKb, 
            min: 50, 
            max: _originalSize! / 1024, 
            divisions: 50, 
            onChanged: (v) => setState(() => _targetSizeKb = v)
          ),
          Center(
            child: Text(
              '${_targetSizeKb.toInt()} KB', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5F))
            )
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _compressPdf, 
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color(0xFF1A3A5F),
              foregroundColor: Colors.white,
            ),
            child: const Text('بدء الضغط والتصدير', style: TextStyle(fontSize: 18)),
          ),
        ]
      )
    );
  }
}
