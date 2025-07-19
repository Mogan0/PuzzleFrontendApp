class PuzzlePieceModel {
  final int id; // ID unico della tessera
  int currentX; // Colonna attuale della tessera nella griglia
  int currentY; // Riga attuale della tessera nella griglia
  final int correctX; // Colonna corretta in cui la tessera dovrebbe trovarsi
  final int correctY; // Riga corretta in cui la tessera dovrebbe trovarsi
  bool isPlacedCorrectly; // Indica se la tessera è al suo posto

  PuzzlePieceModel({
    required this.id,
    required this.currentX,
    required this.currentY,
    required this.correctX,
    required this.correctY,
    this.isPlacedCorrectly = false,
  });
}
