class PuzzlePieceModel {
  final int id;
  int currentX;
  int currentY;
  final int correctX;
  final int correctY;
  bool isPlacedCorrectly;

  PuzzlePieceModel({
    required this.id,
    required this.currentX,
    required this.currentY,
    required this.correctX,
    required this.correctY,
    this.isPlacedCorrectly = false,
  });
}
