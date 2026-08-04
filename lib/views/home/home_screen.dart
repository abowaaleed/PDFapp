import 'package:flutter/material.dart';
import '../merge/merge_screen.dart';
import '../compress/compress_screen.dart';
import '../saved/saved_screen.dart';
import '../editor/editor_screen.dart';
import '../extract/extract_screen.dart';

import '../merge_pdf/merge_pdf_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('PDF-sw411',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text('v1.2.0',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Icon(Icons.picture_as_pdf,
                        size: 70, color: primary),
                    const SizedBox(height: 14),
                    Text(
                      'مرحباً بك في PDF-sw411',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'الأداة الاحترافية لدمج وضغط واستخراج نصوص PDF',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 28),
                    _FeatureCard(
                      title: 'دمج ملفات PDF',
                      icon: Icons.merge,
                      description: 'اجمع عدة ملفات PDF في ملف واحد بلمسة واحدة',
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MergePdfsScreen())),
                    ),
                    const SizedBox(height: 14),
                    _FeatureCard(
                      title: 'دمج صور إلى PDF',
                      icon: Icons.auto_awesome_motion,
                      description:
                          'اجمع صورك في مستند واحد مع تحكم كامل في الحجم',
                      color: primary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MergeScreen())),
                    ),
                    const SizedBox(height: 14),
                    _FeatureCard(
                      title: 'ضغط ملف PDF',
                      icon: Icons.compress_rounded,
                      description:
                          'قلل حجم ملفاتك مع الحفاظ على الجودة العالية',
                      color: secondary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CompressScreen())),
                    ),
                    const SizedBox(height: 14),
                    _FeatureCard(
                      title: 'المحفوظات',
                      icon: Icons.bookmark_border,
                      description:
                          'تصفّح وحمّل وشارك الملفات التي قمت بحفظها',
                      color: Colors.teal,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SavedScreen())),
                    ),
                    const SizedBox(height: 14),
                    _FeatureCard(
                      title: 'تحويل PDF إلى نص',
                      icon: Icons.text_snippet,
                      description:
                          'استخرج النص من ملفات PDF وصدّره كـ Word أو نص عادي',
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ExtractScreen())),
                    ),
                    const SizedBox(height: 14),
                    _FeatureCard(
                      title: 'إضافة نصوص على الصور',
                      icon: Icons.text_fields,
                      description:
                          'أضف نصوصاً احترافية على صورك ثم صدّرها كـ PDF',
                      color: const Color(0xFFD4AF37),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditorScreen())),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Card(
          elevation: 4,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: widget.color.withValues(alpha: 0.12), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, size: 28, color: widget.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.description,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios_new,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
