class PuzzlePieceModel {
  final int id;
  int x;
  int y;

  PuzzlePieceModel({required this.id, required this.x, required this.y});

  // Factory per creazione da lista/dati SignalR
  factory PuzzlePieceModel.fromMap(Map<String, dynamic> map) {
    return PuzzlePieceModel(id: map['id'], x: map['x'], y: map['y']);
  }
}
