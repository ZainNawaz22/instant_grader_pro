class OmrResult {
  final int rowIndex;
  final int colIndex;
  final bool isMarked;
  final double confidence;

  OmrResult({
    required this.rowIndex,
    required this.colIndex,
    required this.isMarked,
    required this.confidence,
  });

  @override
  String toString() {
    return 'OmrResult(row: $rowIndex, col: $colIndex, marked: $isMarked, conf: ${confidence.toStringAsFixed(2)})';
  }
} 