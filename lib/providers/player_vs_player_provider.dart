import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/base_game_state.dart';
import '../models/chess_piece.dart';
import '../utils/sound_manager.dart';
import 'dart:convert';
import 'package:vibration/vibration.dart';

class PlayerVsPlayerProvider with ChangeNotifier {
  static const String _storageKey = 'chess_game_state_pvp';
  final SoundManager _soundManager = SoundManager();

  late PlayerVsPlayerState _state;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  PlayerVsPlayerProvider() {
    _state = PlayerVsPlayerState();
  }

  // Getters for game state
  bool get gameOver => _state.gameOver;
  PieceColor? get winner => _state.winner;
  PieceColor get currentTurn => _state.currentTurn;
  String? get selectedPosition => _state.selectedPosition;
  List<ChessPiece> get pieces => _state.pieces;

  // Load and Save state
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(_storageKey);
    if (stateJson != null) {
      final stateMap = jsonDecode(stateJson);
      _state = PlayerVsPlayerState.fromJson(stateMap);
      notifyListeners();
    } else {
      initializeGame();
    }
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = jsonEncode(_state.toJson());
    await prefs.setString(_storageKey, stateJson);
  }

  void initializeGame() {
    _state = PlayerVsPlayerState();
    _state.initializeBoard();
    notifyListeners();
    saveState();
  }

  void selectPosition(String position) {
    final selectedPiece = _getPieceAt(position);

    if (selectedPiece?.color == _state.currentTurn) {
      _state.selectedPosition = position;
      notifyListeners();
    } else if (_state.selectedPosition != null) {
      movePiece(_state.selectedPosition!, position);
    }
  }

  void movePiece(String from, String to) {
    final movingPiece = _getPieceAt(from);
    if (movingPiece == null || movingPiece.color != _state.currentTurn) return;

    final validMoves = getValidMoves(movingPiece);
    if (!validMoves.contains(to)) return;

    final capturedPiece = _getPieceAt(to);
    if (capturedPiece != null) {
      capturedPiece.isCaputured = true;
      _playSound('capture');
      _vibrate();
    } else {
      _playSound('move');
    }

    movingPiece.position = to;
    _state.selectedPosition = null;
    _state.currentTurn = _state.currentTurn == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    _checkGameOver();
    notifyListeners();
    saveState();
  }

  List<String> getValidMoves(ChessPiece piece) {
    if (piece.isCaputured) return [];

    List<String> validMoves = [];
    final file = piece.position[0];
    final rank = int.parse(piece.position[1]);
    final fileIndex = file.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rankIndex = rank - 1;

    switch (piece.type) {
      case PieceType.pawn:
        _getPawnMoves(piece, fileIndex, rankIndex, validMoves);
        break;
      case PieceType.knight:
        _getKnightMoves(piece, fileIndex, rankIndex, validMoves);
        break;
      case PieceType.bishop:
        _getBishopMoves(piece, fileIndex, rankIndex, validMoves);
        break;
      case PieceType.rook:
        _getRookMoves(piece, fileIndex, rankIndex, validMoves);
        break;
      case PieceType.queen:
        _getBishopMoves(piece, fileIndex, rankIndex, validMoves);
        _getRookMoves(piece, fileIndex, rankIndex, validMoves);
        break;
      case PieceType.king:
        _getKingMoves(piece, fileIndex, rankIndex, validMoves);
        break;
    }

    return validMoves;
  }

  void _getPawnMoves(ChessPiece pawn, int fileIndex, int rankIndex, List<String> validMoves) {
    final direction = pawn.color == PieceColor.white ? 1 : -1;
    final startingRank = pawn.color == PieceColor.white ? 1 : 6;

    // Forward move
    final newRankIndex = rankIndex + direction;
    if (newRankIndex >= 0 && newRankIndex < 8) {
      final newPosition = '${String.fromCharCode('a'.codeUnitAt(0) + fileIndex)}${newRankIndex + 1}';
      if (_getPieceAt(newPosition) == null) {
        validMoves.add(newPosition);

        // Double move from starting position
        if (rankIndex == startingRank) {
          final doubleRankIndex = rankIndex + 2 * direction;
          if (doubleRankIndex >= 0 && doubleRankIndex < 8) {
            final doublePosition = '${String.fromCharCode('a'.codeUnitAt(0) + fileIndex)}${doubleRankIndex + 1}';
            if (_getPieceAt(doublePosition) == null) {
              validMoves.add(doublePosition);
            }
          }
        }
      }
    }

    // Capture moves
    for (var i = -1; i <= 1; i += 2) {
      final newFileIndex = fileIndex + i;
      if (newFileIndex >= 0 && newFileIndex < 8 && newRankIndex >= 0 && newRankIndex < 8) {
        final capturePosition = '${String.fromCharCode('a'.codeUnitAt(0) + newFileIndex)}${newRankIndex + 1}';
        final targetPiece = _getPieceAt(capturePosition);
        if (targetPiece != null && targetPiece.color != pawn.color) {
          validMoves.add(capturePosition);
        }
      }
    }
  }

  void _getKnightMoves(ChessPiece knight, int fileIndex, int rankIndex, List<String> validMoves) {
    final moves = [
      [2, 1], [2, -1], [-2, 1], [-2, -1],
      [1, 2], [1, -2], [-1, 2], [-1, -2]
    ];

    for (var move in moves) {
      final newFileIndex = fileIndex + move[0];
      final newRankIndex = rankIndex + move[1];

      if (newFileIndex >= 0 && newFileIndex < 8 && newRankIndex >= 0 && newRankIndex < 8) {
        final newPosition = '${String.fromCharCode('a'.codeUnitAt(0) + newFileIndex)}${newRankIndex + 1}';
        final targetPiece = _getPieceAt(newPosition);

        if (targetPiece == null || targetPiece.color != knight.color) {
          validMoves.add(newPosition);
        }
      }
    }
  }

  void _getBishopMoves(ChessPiece bishop, int fileIndex, int rankIndex, List<String> validMoves) {
    final directions = [
      [1, 1], [1, -1], [-1, 1], [-1, -1]
    ];

    for (var direction in directions) {
      for (var i = 1; i < 8; i++) {
        final newFileIndex = fileIndex + i * direction[0];
        final newRankIndex = rankIndex + i * direction[1];

        if (newFileIndex < 0 || newFileIndex >= 8 || newRankIndex < 0 || newRankIndex >= 8) {
          break;
        }

        final newPosition = '${String.fromCharCode('a'.codeUnitAt(0) + newFileIndex)}${newRankIndex + 1}';
        final targetPiece = _getPieceAt(newPosition);

        if (targetPiece == null) {
          validMoves.add(newPosition);
        } else {
          if (targetPiece.color != bishop.color) {
            validMoves.add(newPosition);
          }
          break;
        }
      }
    }
  }

  void _getRookMoves(ChessPiece rook, int fileIndex, int rankIndex, List<String> validMoves) {
    final directions = [
      [1, 0], [-1, 0], [0, 1], [0, -1]
    ];

    for (var direction in directions) {
      for (var i = 1; i < 8; i++) {
        final newFileIndex = fileIndex + i * direction[0];
        final newRankIndex = rankIndex + i * direction[1];

        if (newFileIndex < 0 || newFileIndex >= 8 || newRankIndex < 0 || newRankIndex >= 8) {
          break;
        }

        final newPosition = '${String.fromCharCode('a'.codeUnitAt(0) + newFileIndex)}${newRankIndex + 1}';
        final targetPiece = _getPieceAt(newPosition);

        if (targetPiece == null) {
          validMoves.add(newPosition);
        } else {
          if (targetPiece.color != rook.color) {
            validMoves.add(newPosition);
          }
          break;
        }
      }
    }
  }

  void _getKingMoves(ChessPiece king, int fileIndex, int rankIndex, List<String> validMoves) {
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;

        final newFileIndex = fileIndex + i;
        final newRankIndex = rankIndex + j;

        if (newFileIndex >= 0 && newFileIndex < 8 && newRankIndex >= 0 && newRankIndex < 8) {
          final newPosition = '${String.fromCharCode('a'.codeUnitAt(0) + newFileIndex)}${newRankIndex + 1}';
          final targetPiece = _getPieceAt(newPosition);

          if (targetPiece == null || targetPiece.color != king.color) {
            validMoves.add(newPosition);
          }
        }
      }
    }
  }

  int getPlayerScore(PieceColor color) {
    return _state.pieces
        .where((p) => p.color != color && p.isCaputured)
        .fold(0, (sum, piece) => sum + piece.points);
  }

  List<ChessPiece> getCapturedPieces(PieceColor capturedBy) {
    return _state.pieces
        .where((p) => p.color != capturedBy && p.isCaputured)
        .toList();
  }

  ChessPiece? _getPieceAt(String position) {
    try {
      return _state.pieces.firstWhere(
        (p) => p.position == position && !p.isCaputured,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _playSound(String soundType) async {
    if (!_soundEnabled) return;
    print('Playing sound: $soundType (Sound enabled: $_soundEnabled)'); // Debug print
    if (soundType == 'move') {
      await _soundManager.playMoveSound();
    } else if (soundType == 'capture') {
      print('Playing capture sound...'); // Debug print
      await _soundManager.playCaptureSound();
    }
  }

  Future<void> _vibrate() async {
    if (!_vibrationEnabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 100);
    }
  }

  void _checkGameOver() {
    bool canMove = false;
    for (final piece in _state.pieces.where(
      (p) => p.color == _state.currentTurn && !p.isCaputured)) {
      if (getValidMoves(piece).isNotEmpty) {
        canMove = true;
        break;
      }
    }
    if (!canMove) {
      _state.gameOver = true;
      // The opponent wins when current player has no moves
      _state.winner = _state.currentTurn == PieceColor.white 
          ? PieceColor.black 
          : PieceColor.white;
    }
  }

  @override
  void dispose() {
    saveState();
    _soundManager.dispose();
    super.dispose();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Add logic to load preferences
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Add logic to save preferences
  }
}

class PlayerVsPlayerState extends BaseGameState {
  PlayerVsPlayerState({
    super.pieces,
    super.selectedPosition,
    super.currentTurn,
    super.gameOver,
    super.winner,
  });

  factory PlayerVsPlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerVsPlayerState(
      pieces: (json['pieces'] as List).map((piece) => ChessPiece(
        type: PieceType.values[piece['type']],
        color: PieceColor.values[piece['color']],
        position: piece['position'],
        isCaputured: piece['isCaptured'],
      )).toList(),
      selectedPosition: json['selectedPosition'],
      currentTurn: PieceColor.values[json['currentTurn']],
      gameOver: json['gameOver'],
      winner: json['winner'] != null ? PieceColor.values[json['winner']] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pieces': pieces.map((piece) => {
        'type': piece.type.index,
        'color': piece.color.index,
        'position': piece.position,
        'isCaptured': piece.isCaputured,
      }).toList(),
      'selectedPosition': selectedPosition,
      'currentTurn': currentTurn.index,
      'gameOver': gameOver,
      'winner': winner?.index,
    };
  }
}
