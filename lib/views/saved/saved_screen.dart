import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/saved_provider.dart';
import '../../utils/pdf_helper.dart';
import 'package:intl/intl.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavedProvider>(context);
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفوظات'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('لا توجد ملفات محفوظة حالياً'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(item.date);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(item.name),
                    subtitle: Text('$dateStr - ${(item.size / 1024).toStringAsFixed(1)} KB'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.blue),
                          tooltip: 'تحميل على الجهاز',
                          onPressed: () async {
                            final bytes = await provider.getBytes(item.id);
                            if (bytes != null && context.mounted) {
                              try {
                                PdfHelper.downloadPdf(bytes, item.name);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('جاري تحميل الملف على جهازك...')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('خطأ أثناء التحميل: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => provider.remove(item.id),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final bytes = await provider.getBytes(item.id);
                      if (bytes != null) {
                        PdfHelper.openPdfInNewTab(bytes, item.name);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
