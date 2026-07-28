import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/pdf_provider.dart';
import '../../providers/saved_provider.dart';
import '../../utils/pdf_helper.dart';
import '../../widgets/loading_overlay.dart';

class ExportSettingsScreen extends StatefulWidget {
  const ExportSettingsScreen({super.key});

  @override
  State<ExportSettingsScreen> createState() => _ExportSettingsScreenState();
}

class _ExportSettingsScreenState extends State<ExportSettingsScreen> {
  double _sliderValue = 500; 
  final TextEditingController _nameController = TextEditingController(text: 'PDF-sw411_Document');
  
  @override
  void initState() {
    super.initState();
    _sliderValue = Provider.of<PdfProvider>(context, listen: false).targetSizeKb;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PdfProvider>(context);
    final images = provider.images;
    final originalSizeKb = images.fold(0.0, (sum, item) => sum + item.length) / 1024;
    final quality = ( (_sliderValue * 1024) / (originalSizeKb * 1024) ).clamp(0.05, 1.0);
    final estimatedSizeKb = PdfHelper.estimateSizeKb(images, quality);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التصدير'),
        actions: [
          IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSizeDisplay(originalSizeKb, estimatedSizeKb),
                const SizedBox(height: 32),
                const Text('اسم الملف:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit),
                    suffixText: '.pdf',
                  ),
                ),
                const SizedBox(height: 32),
                const Text('الحجم المطلوب للملف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('110 KB'),
                    Text(_sliderValue < 1000 ? '${_sliderValue.toInt()} KB' : '${(_sliderValue / 1024).toStringAsFixed(1)} MB',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                    const Text('10 MB'),
                  ],
                ),
                Slider(
                  value: _sliderValue,
                  min: 110,
                  max: 10000,
                  divisions: 100,
                  onChanged: (value) => setState(() => _sliderValue = value),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => _exportPdf(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تصدير وحفظ PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeDisplay(double original, double estimated) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _SizeRow(label: 'الحجم الأصلي:', value: original < 1024 ? '${original.toInt()} KB' : '${(original / 1024).toStringAsFixed(1)} MB', color: Colors.grey[700]!),
            const Divider(height: 24),
            _SizeRow(label: 'الحجم التقديري بعد التصدير:', value: estimated < 1024 ? '${estimated.toInt()} KB' : '${(estimated / 1024).toStringAsFixed(1)} MB', color: Theme.of(context).colorScheme.primary, isBold: true),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, PdfProvider provider) async {
    final imagesCount = provider.images.length;
    LoadingDialog.show(context, 'Image to PDF');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final pdfBytes = await PdfHelper.generatePdfWithTargetSize(
        images: provider.images,
        targetSizeKb: _sliderValue,
        onProgress: (current, total) {
          LoadingDialog.updateProgress(current, total, message: 'Image to PDF');
        },
      );

      final filename = _nameController.text.isEmpty ? 'PDF-sw411_Document' : _nameController.text;

      if (context.mounted) {
        final savedProvider = Provider.of<SavedProvider>(context, listen: false);
        await savedProvider.save('$filename.pdf', pdfBytes);
      }

      if (mounted) {
        LoadingDialog.hide(context);
      }

      final fullFilename = '$filename.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fullFilename);

      if (mounted) {
        _showSuccessDialog(imagesCount, pdfBytes.length);
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  void _showSuccessDialog(int count, int size) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم إنشاء الملف بنجاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عدد الصور المدمجة: $count'),
            Text('حجم الملف النهائي: ${(size / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 8),
            const Text('تم حفظ الملف بنجاح.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('تم الحفظ في المحفوظات أيضاً', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً')),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;
  const _SizeRow({required this.label, required this.value, required this.color, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
    ]);
  }
}
