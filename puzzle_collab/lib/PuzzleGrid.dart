import 'dart:math';
import 'dart:ui' as ui;

import 'package:puzzle_collab/model/puzzle_pieces_model.dart';
import 'package:flutter/material.dart';

class PuzzleGrid extends StatefulWidget {
  final ui.Image originalImage;
  final List<PuzzlePieceModel> pieces;
  final int gridCount;
  final Function(int pieceId, int targetX, int targetY) onPieceMoveRequested;

  const PuzzleGrid({
    required this.originalImage,
    required this.pieces,
    required this.gridCount,
    required this.onPieceMoveRequested,
    super.key,
  });

  @override
  State<PuzzleGrid> createState() => _PuzzleGridState();
}

class _PuzzleGridState extends State<PuzzleGrid> {
  late List<PuzzlePieceModel> _currentPieces;
  double _gridSize = 0;
  double _pieceSize = 0;

  @override
  void initState() {
    super.initState();
    _currentPieces = widget.pieces;
  }

  @override
  void didUpdateWidget(covariant PuzzleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pieces != oldWidget.pieces) {
      _currentPieces = widget.pieces;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _gridSize = min(constraints.maxWidth, constraints.maxHeight);
        _pieceSize = _gridSize / widget.gridCount;

        return Center(
          child: Container(
            width: _gridSize,
            height: _gridSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Stack(
              children: [
                ..._currentPieces.map((piece) {
                  final Offset pieceScreenPosition = Offset(
                    piece.currentX * _pieceSize,
                    piece.currentY * _pieceSize,
                  );

                  return Positioned(
                    key: ValueKey(piece.id),
                    left: pieceScreenPosition.dx,
                    top: pieceScreenPosition.dy,
                    child: DragTarget<PuzzlePieceModel>(
                      onWillAcceptWithDetails: (details) {
                        return details.data.id != piece.id;
                      },
                      onAcceptWithDetails: (details) {
                        final PuzzlePieceModel draggedPiece = details.data;
                        final PuzzlePieceModel targetPiece = piece;

                        widget.onPieceMoveRequested(
                          draggedPiece.id,
                          targetPiece.currentX,
                          targetPiece.currentY,
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Draggable<PuzzlePieceModel>(
                          data: piece,
                          feedback: SizedBox(
                            width: _pieceSize,
                            height: _pieceSize,
                            child: Opacity(
                              opacity: 0.7,
                              child: _buildPuzzlePieceWidget(
                                // Chiamata al metodo interno
                                piece,
                                widget.originalImage,
                                _pieceSize,
                                widget.gridCount,
                              ),
                            ),
                          ),
                          childWhenDragging: SizedBox(
                            width: _pieceSize,
                            height: _pieceSize,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                          child: _buildPuzzlePieceWidget(
                            // Chiamata al metodo interno
                            piece,
                            widget.originalImage,
                            _pieceSize,
                            widget.gridCount,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- FUNZIONE _buildPuzzlePieceWidget SPOSTATA QUI DENTRO ---
  Widget _buildPuzzlePieceWidget(
    PuzzlePieceModel piece,
    ui.Image image,
    double pieceDisplaySize,
    int gridCount,
  ) {
    final double imageSliceWidth = image.width / gridCount;
    final double imageSliceHeight = image.height / gridCount;

    final Rect imageRect = Rect.fromLTWH(
      piece.correctX * imageSliceWidth,
      piece.correctY * imageSliceHeight,
      imageSliceWidth,
      imageSliceHeight,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: piece.isPlacedCorrectly
              ? Colors.green
              : Colors.black26, // Bordo verde se al posto
          width: piece.isPlacedCorrectly ? 2.0 : 0.5,
        ),
      ),
      child: CustomPaint(
        painter: _ImageSlicePainter(image, imageRect),
        size: Size(pieceDisplaySize, pieceDisplaySize),
      ),
    );
  }
}

// L'estensione e il CustomPainter rimangono fuori, poiché non dipendono dallo stato del widget
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

class _ImageSlicePainter extends CustomPainter {
  final ui.Image image;
  final Rect imageRect;

  _ImageSlicePainter(this.image, this.imageRect);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect destRect = Offset.zero & size;
    canvas.drawImageRect(image, imageRect, destRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _ImageSlicePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.imageRect != imageRect;
  }
}
