import '../models/chess_piece.dart';

abstract class BaseGameState {
  List<ChessPiece> pieces;
  String? selectedPosition;
  PieceColor currentTurn;
  bool gameOver;

  BaseGameState({
    List<ChessPiece>? pieces,
    this.selectedPosition,
    this.currentTurn = PieceColor.white,
    this.gameOver = false,
  }) : pieces = pieces ?? [];

  void initializeBoard() {
    pieces = [];
    _setupPieces(PieceColor.white);
    _setupPieces(PieceColor.black);
  }

  void _setupPieces(PieceColor color) {
    int pawnRow = color == PieceColor.white ? 1 : 6;
    int pieceRow = color == PieceColor.white ? 0 : 7;

    // Setup pawns
    for (int i = 0; i < 8; i++) {
      pieces.add(ChessPiece(
        type: PieceType.pawn,
        color: color,
        position: '${String.fromCharCode(97 + i)}${pawnRow + 1}',
      ));
    }

    final pieceSetup = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];

    for (int i = 0; i < pieceSetup.length; i++) {
      pieces.add(ChessPiece(
        type: pieceSetup[i],
        color: color,
        position: '${String.fromCharCode(97 + i)}${pieceRow + 1}',
      ));
    }
  }
}
