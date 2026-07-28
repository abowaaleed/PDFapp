class ExtractedPage {
  final int pageNumber;
  String text;
  double confidence;
  bool isScanned;

  ExtractedPage({
    required this.pageNumber,
    this.text = '',
    this.confidence = 0,
    this.isScanned = false,
  });
}
