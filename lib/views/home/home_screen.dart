import 'package:flutter/material.dart';
import '../merge/merge_screen.dart';
import '../compress/compress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('PDF-sw411', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text('v1.0.6', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 100, color: Color(0xFF1A3A5F)),
                  const SizedBox(height: 24),
                  const Text(
                    'مرحباً بك في PDF-sw411',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5F)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'الأداة الاحترافية لدمج وضغط ملفات PDF بسهولة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          title: 'دمج صور إلى PDF',
                          icon: Icons.auto_awesome_motion,
                          description: 'اجمع صورك في مستند واحد مع تحكم كامل في الحجم',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MergeScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _FeatureCard(
                          title: 'ضغط ملف PDF',
                          icon: Icons.compress_rounded,
                          description: 'قلل حجم ملفاتك مع الحفاظ على الجودة العالية',
                          color: Theme.of(context).colorScheme.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CompressScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 56, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
