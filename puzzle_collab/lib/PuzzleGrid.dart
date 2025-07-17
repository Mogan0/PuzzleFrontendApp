import 'package:flutter/material.dart';
import 'package:puzzle_collab/model/puzzle_pieces_model.dart';

class PuzzleGrid extends StatelessWidget {
  final List<PuzzlePieceModel> pieces;

  const PuzzleGrid({required this.pieces, super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, PuzzlePieceModel> posMap = {
      for (var p in pieces) '${p.x}-${p.y}': p,
    };

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 20,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          int x = index % 10;
          int y = index ~/ 10;
          final piece = posMap['$x-$y'];

          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: piece != null ? Colors.blueAccent : Colors.grey[200],
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: piece != null
                  ? Text(
                      'P${piece.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
