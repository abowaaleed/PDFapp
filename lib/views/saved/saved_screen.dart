import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/saved_provider.dart';
import '../../utils/pdf_helper.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفوظات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'الصفحة الرئيسية',
          ),
        ],
      ),
      body: Consumer<SavedProvider>(
        builder: (context, provider, child) {
          if (!provider.isReady) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('لا توجد ملفات محفوظة',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('ستظهر هنا جميع الملفات التي قمت بتصديرها',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return _SavedCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  final SavedItem item;
  const _SavedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavedProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
        ),
        title: Text(item.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${_formatDate(item.date)}  •  ${_formatSize(item.size)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[500]),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) =>
              _handleAction(context, provider, value),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'open',
              child: ListTile(
                  leading: Icon(Icons.open_in_new),
                  title: Text('فتح الملف'),
                  dense: true,
                  contentPadding: EdgeInsets.zero),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                  leading: Icon(Icons.share_rounded),
                  title: Text('مشاركة'),
                  dense: true,
                  contentPadding: EdgeInsets.zero),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('حذف', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, SavedProvider provider, String action) async {
    final bytes = await provider.getBytes(item.id);
    if (bytes == null || !context.mounted) return;

    switch (action) {
      case 'open':
        PdfHelper.openPdfInNewTab(bytes, '${item.name}.pdf');
        break;
      case 'share':
        PdfHelper.sharePdfBytes(bytes, '${item.name}.pdf');
        break;
      case 'delete':
        _confirmDelete(context, provider);
        break;
    }
  }

  void _confirmDelete(BuildContext context, SavedProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل أنت متأكد من حذف "${item.name}"؟'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              provider.remove(item.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
