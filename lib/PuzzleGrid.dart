import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:puzzle_collab/model/puzzle_pieces_model.dart';

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
  int? _draggingId;

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
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.40),
                  Colors.white.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Sfondo glassmorphism
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
                ..._currentPieces.map((piece) {
                  final Offset pieceScreenPosition = Offset(
                    piece.currentX * _pieceSize,
                    piece.currentY * _pieceSize,
                  );

                  return AnimatedPositioned(
                    key: ValueKey(piece.id),
                    left: pieceScreenPosition.dx,
                    top: pieceScreenPosition.dy,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: DragTarget<PuzzlePieceModel>(
                      onWillAcceptWithDetails: (details) =>
                          details.data.id != piece.id,
                      onAcceptWithDetails: (details) {
                        final draggedPiece = details.data;
                        widget.onPieceMoveRequested(
                          draggedPiece.id,
                          piece.currentX,
                          piece.currentY,
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isDragging = _draggingId == piece.id;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Draggable<PuzzlePieceModel>(
                            data: piece,
                            onDragStarted: () {
                              setState(() {
                                _draggingId = piece.id;
                              });
                            },
                            onDraggableCanceled: (_, __) {
                              setState(() {
                                _draggingId = null;
                              });
                            },
                            onDragEnd: (_) {
                              setState(() {
                                _draggingId = null;
                              });
                            },
                            feedback: SizedBox(
                              width: _pieceSize,
                              height: _pieceSize,
                              child: Opacity(
                                opacity: 0.8,
                                child: _buildPuzzlePieceWidget(
                                  piece,
                                  widget.originalImage,
                                  _pieceSize,
                                  widget.gridCount,
                                  isDragging: true,
                                ),
                              ),
                            ),
                            childWhenDragging: _buildEmptySlot(),
                            child: AnimatedScale(
                              scale: isDragging ? 1.10 : 1.0,
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutBack,
                              child: _buildPuzzlePieceWidget(
                                piece,
                                widget.originalImage,
                                _pieceSize,
                                widget.gridCount,
                                isDragging: false,
                              ),
                            ),
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

  Widget _buildPuzzlePieceWidget(
    PuzzlePieceModel piece,
    ui.Image image,
    double pieceDisplaySize,
    int gridCount, {
    required bool isDragging,
  }) {
    final double imageSliceWidth = image.width / gridCount;
    final double imageSliceHeight = image.height / gridCount;

    final Rect imageRect = Rect.fromLTWH(
      piece.correctX * imageSliceWidth,
      piece.correctY * imageSliceHeight,
      imageSliceWidth,
      imageSliceHeight,
    );

    final borderColor = piece.isPlacedCorrectly
        ? Colors.greenAccent.shade400
        : Colors.black.withOpacity(0.15);

    final borderWidth = piece.isPlacedCorrectly ? 0.0 : 1.2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (piece.isPlacedCorrectly)
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.24),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          if (!piece.isPlacedCorrectly)
            BoxShadow(
              color: Colors.red,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(2, 4),
            ),
        ],
        color: isDragging
            ? Colors.blue.withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(
          painter: _ImageSlicePainter(image, imageRect),
          size: Size(pieceDisplaySize, pieceDisplaySize),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 0.9),
        borderRadius: BorderRadius.circular(2),
        color: Colors.grey.withOpacity(0.09),
      ),
    );
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
