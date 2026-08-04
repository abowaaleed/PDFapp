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
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('$dateStr - ${(item.size / 1024).toStringAsFixed(1)} KB'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Color(0xFF1A3A5F)),
                          tooltip: 'مشاركة',
                          onPressed: () async {
                            final bytes = await provider.getBytes(item.id);
                            if (bytes == null || !context.mounted) return;
                            final shared = await PdfHelper.sharePdf(bytes, item.name);
                            if (!shared && context.mounted) {
                              PdfHelper.downloadPdf(bytes, item.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('جاري تحميل الملف...')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.blue),
                          tooltip: 'حفظ على الجهاز',
                          onPressed: () async {
                            final bytes = await provider.getBytes(item.id);
                            if (bytes != null && context.mounted) {
                              PdfHelper.downloadPdf(bytes, item.name);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('جاري تحميل الملف على جهازك...')),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          tooltip: 'حذف',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('حذف الملف'),
                                content: Text('هل أنت متأكد من حذف "${item.name}"؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              provider.remove(item.id);
                            }
                          },
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
