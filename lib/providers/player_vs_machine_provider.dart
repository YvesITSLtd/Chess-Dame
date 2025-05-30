import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/base_game_state.dart';
import '../models/chess_piece.dart';
import '../utils/sound_manager.dart';
import 'dart:convert';
import 'dart:math';
import 'package:vibration/vibration.dart';

class PlayerVsMachineProvider with ChangeNotifier {
  static const String _storageKey = 'chess_game_state_pvm';
  final SoundManager _soundManager = SoundManager();
  
  late PlayerVsMachineState _state;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _difficulty = 'Medium';

  PlayerVsMachineProvider() {
    _state = PlayerVsMachineState();
  }

  // Getters
  List<ChessPiece> get pieces => _state.pieces;
  String? get selectedPosition => _state.selectedPosition;
  PieceColor get currentTurn => _state.currentTurn;
  bool get gameOver => _state.gameOver;
  PieceColor? get winner => _state.winner;

  String get difficulty => _difficulty;

  // Load and Save state
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(_storageKey);
    if (stateJson != null) {
      final stateMap = jsonDecode(stateJson);
      _state = PlayerVsMachineState.fromJson(stateMap);
      _difficulty = stateMap['difficulty'] ?? 'Medium';
      notifyListeners();
    } else {
      initializeGame();
    }
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = jsonEncode({
      ..._state.toJson(),
      'difficulty': _difficulty,
    });
    await prefs.setString(_storageKey, stateJson);
  }

  void initializeGame() {
    _state = PlayerVsMachineState();
    _state.initializeBoard();
    notifyListeners();
    saveState();
  }

  void selectPosition(String position) {
    if (_state.currentTurn == PieceColor.black) return; // Machine's turn

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

    if (!_state.gameOver && _state.currentTurn == PieceColor.black) {
      _makeMachineMove();
    }
  }

  void _makeMachineMove() {
    if (_state.gameOver) return;

    final availablePieces = _state.pieces.where(
      (p) => p.color == _state.currentTurn && !p.isCaputured
    ).toList();

    if (availablePieces.isEmpty) {
      _state.gameOver = true;
      notifyListeners();
      return;
    }

    final thinkingTime = _difficulty == 'Easy' ? 300 : 
                        _difficulty == 'Medium' ? 500 : 800;

    Future.delayed(Duration(milliseconds: thinkingTime), () {
      if (_state.gameOver) return;

      final random = Random();
      final maxAttempts = _difficulty == 'Easy' ? 3 : 
                         _difficulty == 'Medium' ? 5 : 10;
      
      int attempts = 0;
      bool moveMade = false;

      while (!moveMade && attempts < maxAttempts) {
        final piece = availablePieces[random.nextInt(availablePieces.length)];
        final possibleMoves = getValidMoves(piece);

        if (possibleMoves.isNotEmpty) {
          final newPosition = _getBestMove(possibleMoves, piece);
          movePiece(piece.position, newPosition);
          moveMade = true;
        }
        attempts++;
      }

      if (!moveMade) {
        _state.gameOver = true;
        notifyListeners();
      }
    });
  }

  String _getBestMove(List<String> possibleMoves, ChessPiece piece) {
    if (_difficulty == 'Easy') {
      return possibleMoves[Random().nextInt(possibleMoves.length)];
    }

    final capturingMoves = possibleMoves.where((move) {
      final targetPiece = _getPieceAt(move);
      return targetPiece != null && targetPiece.color != piece.color;
    }).toList();

    if (capturingMoves.isNotEmpty && (_difficulty == 'Hard' || Random().nextBool())) {
      return capturingMoves[Random().nextInt(capturingMoves.length)];
    }

    return possibleMoves[Random().nextInt(possibleMoves.length)];
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
    if (soundType == 'move') {
      await _soundManager.playMoveSound();
    } else if (soundType == 'capture') {
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

  Future<void> updateDifficulty(String value) async {
    _difficulty = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game_difficulty', value);
    notifyListeners();
  }

  @override
  void dispose() {
    saveState();
    _soundManager.dispose();
    super.dispose();
  }
}

class PlayerVsMachineState extends BaseGameState {
  PlayerVsMachineState({
    super.pieces,
    super.selectedPosition,
    super.currentTurn,
    super.gameOver,
  });

  factory PlayerVsMachineState.fromJson(Map<String, dynamic> json) {
    return PlayerVsMachineState(
      pieces: (json['pieces'] as List).map((piece) => ChessPiece(
        type: PieceType.values[piece['type']],
        color: PieceColor.values[piece['color']],
        position: piece['position'],
        isCaputured: piece['isCaptured'],
      )).toList(),
      selectedPosition: json['selectedPosition'],
      currentTurn: PieceColor.values[json['currentTurn']],
      gameOver: json['gameOver'],
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
    };
  }
}

Future<void> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  // Add logic to load preferences
}

Future<void> savePreferences() async {
  final prefs = await SharedPreferences.getInstance();
  // Add logic to save preferences
}

