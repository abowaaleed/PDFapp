import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/pdf_merge_service.dart';
import '../../utils/pdf_helper.dart';
import '../../providers/saved_provider.dart';
import '../../widgets/loading_overlay.dart';

class MergePdfsScreen extends StatefulWidget {
  const MergePdfsScreen({super.key});

  @override
  State<MergePdfsScreen> createState() => _MergePdfsScreenState();
}

class _MergePdfsScreenState extends State<MergePdfsScreen> {
  final List<_PdfFileItem> _pdfFiles = [];
  bool _isProcessing = false;

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        for (final f in result.files) {
          if (f.bytes != null) {
            _pdfFiles.add(_PdfFileItem(file: f));
          }
        }
      });
    }
  }

  Future<void> _mergeAndSave() async {
    if (_pdfFiles.length < 2) return;

    setState(() => _isProcessing = true);
    LoadingDialog.show(context, 'دمج ملفات PDF');

    try {
      final pdfBytesList = _pdfFiles.map((f) => f.file.bytes!).toList();

      LoadingDialog.updateProgress(1, 3, message: 'قراءة الملفات');
      await Future.delayed(const Duration(milliseconds: 200));

      LoadingDialog.updateProgress(2, 3, message: 'دمج الملفات');
      final mergedBytes = await PdfMergeService.mergePdfs(pdfBytesList);

      LoadingDialog.updateProgress(3, 3, message: 'الحفظ');
      await Future.delayed(const Duration(milliseconds: 100));

      final filename = _pdfFiles.length == 2
          ? '${_pdfFiles[0].file.name.replaceAll('.pdf', '')}_و_${_pdfFiles[1].file.name.replaceAll('.pdf', '')}.pdf'
          : 'merged_${_pdfFiles.length}_files.pdf';

      if (context.mounted) {
        final savedProvider = Provider.of<SavedProvider>(context, listen: false);
        await savedProvider.save(filename, mergedBytes);
      }

      if (mounted) LoadingDialog.hide(context);

      if (mounted) {
        _showSuccessDialog(mergedBytes, filename);
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الدمج: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Uint8List mergedBytes, String filename) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم الدمج بنجاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عدد الملفات: ${_pdfFiles.length}'),
            Text('حجم الملف النهائي: ${(mergedBytes.length / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 8),
            const Text('تم الحفظ في المحفوظات.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              PdfHelper.downloadPdf(mergedBytes, filename);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري تحميل الملف على جهازك...')),
              );
            },
            child: const Text('تحميل على الجهاز', style: TextStyle(color: Color(0xFF1A3A5F), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              PdfHelper.openPdfInNewTab(mergedBytes, filename);
            },
            child: const Text('فتح في تبويب جديد'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دمج ملفات PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: _pdfFiles.isEmpty ? _buildEmptyState() : _buildFileList(),
      bottomNavigationBar: _pdfFiles.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _pdfFiles.length < 2 || _isProcessing
                      ? null
                      : _mergeAndSave,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _pdfFiles.length < 2
                              ? 'اختر ملفين على الأقل (${_pdfFiles.length})'
                              : 'دمج ${_pdfFiles.length} ملفات PDF',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            )
          : null,
      floatingActionButton: _pdfFiles.isNotEmpty
          ? FloatingActionButton(
              onPressed: _pickPdfs,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('اختر ملفين PDF على الأقل للدمج'),
          const SizedBox(height: 8),
          Text(
            'يمكنك ترتيب الملفات بعد الاختيار',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickPdfs,
            icon: const Icon(Icons.folder_open),
            label: const Text('اختيار ملفات PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'اضغط على الملف لفتحه · اسحب لإعادة الترتيب',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              TextButton.icon(
                onPressed: _pickPdfs,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final file = _pdfFiles.removeAt(oldIndex);
                _pdfFiles.insert(newIndex, file);
              });
            },
            children: [
              for (int i = 0; i < _pdfFiles.length; i++)
                Card(
                  key: ValueKey('${_pdfFiles[i].file.name}_$i'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[50],
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      _pdfFiles[i].file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${(_pdfFiles[i].file.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => _pdfFiles.removeAt(i)),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                    onTap: () async {
                      final bytes = _pdfFiles[i].file.bytes;
                      if (bytes != null) {
                        PdfHelper.openPdfInNewTab(bytes, _pdfFiles[i].file.name);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PdfFileItem {
  final PlatformFile file;
  _PdfFileItem({required this.file});
}
