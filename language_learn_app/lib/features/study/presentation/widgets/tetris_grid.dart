import 'package:flutter/material.dart';

import '../../providers/vocab_tetris_provider.dart';

class TetrisGrid extends StatelessWidget {
  final List<List<TetrisCell>> grid;
  final FallingPiece? currentPiece;
  final int ghostY;

  const TetrisGrid({
    super.key,
    required this.grid,
    this.currentPiece,
    this.ghostY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 10 / 20,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 2),
          color: Colors.black,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 10;
            final cellHeight = constraints.maxHeight / 20;

            return CustomPaint(
              painter: TetrisGridPainter(
                grid: grid,
                currentPiece: currentPiece,
                ghostY: ghostY,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        ),
      ),
    );
  }
}

class TetrisGridPainter extends CustomPainter {
  final List<List<TetrisCell>> grid;
  final FallingPiece? currentPiece;
  final int ghostY;
  final double cellWidth;
  final double cellHeight;

  TetrisGridPainter({
    required this.grid,
    this.currentPiece,
    required this.ghostY,
    required this.cellWidth,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    // Draw grid lines
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= 20; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
    }

    // Draw locked cells
    for (int row = 0; row < 20; row++) {
      for (int col = 0; col < 10; col++) {
        if (grid[row][col].filled) {
          _drawCell(canvas, col, row, grid[row][col].color ?? Colors.grey);
        }
      }
    }

    // Draw ghost piece
    if (currentPiece != null && ghostY != currentPiece!.y) {
      _drawGhostPiece(canvas);
    }

    // Draw current falling piece
    if (currentPiece != null) {
      final shape = currentPiece!.shape;
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
          if (shape[row][col] == 1) {
            final gridX = currentPiece!.x + col;
            final gridY = currentPiece!.y + row;
            if (gridX >= 0 && gridX < 10 && gridY >= 0 && gridY < 20) {
              _drawCell(canvas, gridX, gridY, currentPiece!.color);
            }
          }
        }
      }
    }
  }

  void _drawCell(Canvas canvas, int x, int y, Color color) {
    final rect = Rect.fromLTWH(
      x * cellWidth + 1,
      y * cellHeight + 1,
      cellWidth - 2,
      cellHeight - 2,
    );

    // Main fill
    final fillPaint = Paint()..color = color;
    canvas.drawRect(rect, fillPaint);

    // 3D effect - highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    canvas.drawLine(rect.topLeft, rect.topRight, highlightPaint);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, highlightPaint);

    // 3D effect - shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, shadowPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, shadowPaint);
  }

  void _drawGhostPiece(Canvas canvas) {
    if (currentPiece == null) return;

    final shape = currentPiece!.shape;
    final ghostPaint = Paint()
      ..color = currentPiece!.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if (shape[row][col] == 1) {
          final gridX = currentPiece!.x + col;
          final gridY = ghostY + row;
          if (gridX >= 0 && gridX < 10 && gridY >= 0 && gridY < 20) {
            final rect = Rect.fromLTWH(
              gridX * cellWidth + 2,
              gridY * cellHeight + 2,
              cellWidth - 4,
              cellHeight - 4,
            );
            canvas.drawRect(rect, ghostPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TetrisGridPainter oldDelegate) {
    return true;
  }
}

class NextPiecePreview extends StatelessWidget {
  final TetrominoType? type;

  const NextPiecePreview({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    if (type == null) return const SizedBox(height: 80);

    final shape = tetrominoShapes[type]![0];
    final color = tetrominoColors[type]!;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black,
      ),
      child: CustomPaint(
        painter: _NextPiecePainter(shape: shape, color: color),
      ),
    );
  }
}

class _NextPiecePainter extends CustomPainter {
  final List<List<int>> shape;
  final Color color;

  _NextPiecePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 5;
    final offset = cellSize / 2;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if (shape[row][col] == 1) {
          final rect = Rect.fromLTWH(
            offset + col * cellSize + 1,
            offset + row * cellSize + 1,
            cellSize - 2,
            cellSize - 2,
          );

          final fillPaint = Paint()..color = color;
          canvas.drawRect(rect, fillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NextPiecePainter oldDelegate) {
    return shape != oldDelegate.shape || color != oldDelegate.color;
  }
}
