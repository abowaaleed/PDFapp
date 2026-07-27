import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/pdf_provider.dart';
import 'export_settings_screen.dart';

class MergeScreen extends StatelessWidget {
  const MergeScreen({super.key});

  Future<void> _pickImages(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        final images = result.files.map((f) => f.bytes!).toList();
        if (context.mounted) {
          Provider.of<PdfProvider>(context, listen: false).addImages(images);
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دمج الصور'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'الصفحة الرئيسية',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => Provider.of<PdfProvider>(context, listen: false).clearImages(),
          ),
        ],
      ),
      body: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          if (provider.images.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_search, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('اضغط لاختيار الصور'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _pickImages(context),
                    child: const Text('اختيار صور من الجهاز'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.images.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: Image.memory(provider.images[index], width: 50, height: 50, fit: BoxFit.cover),
                        title: Text('صورة رقم ${index + 1}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => provider.removeImage(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportSettingsScreen())),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('تصدير كـ PDF'),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImages(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
