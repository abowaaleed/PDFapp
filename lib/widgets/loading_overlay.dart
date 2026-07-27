import 'package:flutter/material.dart';

class ProgressInfo {
  final int current;
  final int total;
  final String? message;

  const ProgressInfo({this.current = 0, this.total = 0, this.message});

  double get percentage => total > 0 ? current / total : 0.0;

  static const ProgressInfo initial = ProgressInfo();
}

class LoadingDialog {
  static final ValueNotifier<ProgressInfo> _progress =
      ValueNotifier(ProgressInfo.initial);

  static void show(BuildContext context, String message) {
    _progress.value = ProgressInfo.initial;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      pageBuilder: (context, anim1, anim2) =>
          _LoadingWidget(message: message, progressNotifier: _progress),
    );
  }

  static void updateProgress(int current, int total, {String? message}) {
    _progress.value = ProgressInfo(
      current: current,
      total: total,
      message: message,
    );
  }

  static void hide(BuildContext context) {
    _progress.value = ProgressInfo.initial;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _LoadingWidget extends StatefulWidget {
  final String message;
  final ValueNotifier<ProgressInfo> progressNotifier;

  const _LoadingWidget({required this.message, required this.progressNotifier});

  @override
  State<_LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<_LoadingWidget> {
  late final Stream<int> _dotStream;

  @override
  void initState() {
    super.initState();
    _dotStream =
        Stream<int>.periodic(const Duration(milliseconds: 350), (i) => (i % 5));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20)
              ],
            ),
            child: ValueListenableBuilder<ProgressInfo>(
              valueListenable: widget.progressNotifier,
              builder: (context, progress, child) {
                final bool hasProgress = progress.total > 0;
                final String displayMessage =
                    progress.message ?? widget.message;
                final int percentage = (progress.percentage * 100).toInt();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasProgress) ...[
                      SizedBox(
                        width: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress.percentage,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1A3A5F)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${progress.current} / ${progress.total}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5F),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1A3A5F)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    StreamBuilder<int>(
                      stream: _dotStream,
                      builder: (context, snapshot) {
                        int dotCount = snapshot.data ?? 0;
                        String dots = '.' * dotCount;
                        return Text(
                          '$displayMessage$dots',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5F),
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    Text(
                      hasProgress
                          ? 'جاري المعالجة... $percentage%'
                          : 'جاري المعالجة... يرجى الانتظار ثواني',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
