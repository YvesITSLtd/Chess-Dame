import 'package:flutter/material.dart';

enum PieceType { pawn, rook, knight, bishop, queen, king }
enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  String position;
  bool isSelected;
  bool isCaputured;
  final int points;

  ChessPiece({
    required this.type,
    required this.color,
    required this.position,
    this.isSelected = false,
    this.isCaputured = false,
  }) : points = _getPointsForType(type);

  static int _getPointsForType(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 1;
      case PieceType.knight:
      case PieceType.bishop:
        return 3;
      case PieceType.rook:
        return 5;
      case PieceType.queen:
        return 9;
      case PieceType.king:
        return 0; // King's value is technically infinite
    }
  }

  bool canMove(String newPosition, List<ChessPiece> pieces) {
    // TODO: Implement move validation logic for each piece type
    return true;
  }

  // Convert piece to JSON for saving state
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'color': color.toString().split('.').last,
      'position': position,
      'isSelected': isSelected,
      'isCaputured': isCaputured,
    };
  }

  // Create a piece from JSON data when loading state
  factory ChessPiece.fromJson(Map<String, dynamic> json) {
    return ChessPiece(
      type: _typeFromString(json['type']),
      color: json['color'] == 'white' ? PieceColor.white : PieceColor.black,
      position: json['position'],
      isSelected: json['isSelected'] ?? false,
      isCaputured: json['isCaputured'] ?? false,
    );
  }

  // Helper method to convert string type to enum
  static PieceType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'pawn': return PieceType.pawn;
      case 'rook': return PieceType.rook;
      case 'knight': return PieceType.knight;
      case 'bishop': return PieceType.bishop;
      case 'queen': return PieceType.queen;
      case 'king': return PieceType.king;
      default: throw Exception('Unknown piece type: $typeStr');
    }
  }
}
