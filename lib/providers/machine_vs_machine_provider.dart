import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/base_game_state.dart';
import '../models/chess_piece.dart';
import '../utils/sound_manager.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:vibration/vibration.dart';

class MachineVsMachineProvider with ChangeNotifier {
  static const String _storageKey = 'chess_game_state_mvm';
  final SoundManager _soundManager = SoundManager();

  late MachineVsMachineState _state;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _difficulty = 'Medium';
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  bool _isMoveInProgress = false; // Add a flag to track if a move is in progress

  MachineVsMachineProvider() {
    _state = MachineVsMachineState();
  }

  // Getters
  List<ChessPiece> get pieces => _state.pieces;
  String? get selectedPosition => _state.selectedPosition;
  PieceColor get currentTurn => _state.currentTurn;
  bool get gameOver => _state.gameOver;
  bool get isAutoPlaying => _isAutoPlaying;
  String get difficulty => _difficulty;

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
      _state = MachineVsMachineState.fromJson(stateMap);
      _difficulty = stateMap['difficulty'] ?? 'Medium';
      _isAutoPlaying = stateMap['isAutoPlaying'] ?? false;

      if (_isAutoPlaying && !_state.gameOver) {
        startAutoPlay();
      }
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
      'isAutoPlaying': _isAutoPlaying,
    });
    await prefs.setString(_storageKey, stateJson);
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _difficulty = prefs.getString('difficulty') ?? 'Medium';
    notifyListeners();
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setString('difficulty', _difficulty);
  }

  void initializeGame() {
    _state = MachineVsMachineState();
    _state.initializeBoard();
    _stopAutoPlay();
    notifyListeners();
    saveState();
  }

  void toggleAutoPlay() {
    if (_isAutoPlaying) {
      _stopAutoPlay();
    } else {
      startAutoPlay();
    }
    saveState();
  }

  void startAutoPlay() {
    if (_state.gameOver) return;

    _isAutoPlaying = true;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_state.gameOver) {
        _makeMachineMove();
      } else {
        _stopAutoPlay();
      }
    });
    notifyListeners();
  }

  void _stopAutoPlay() {
    _isAutoPlaying = false;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    notifyListeners();
  }

  void _makeMachineMove() {
    if (_state.gameOver || _isMoveInProgress) return; // Prevent overlapping calculations

    _isMoveInProgress = true; // Set the flag to true when a move calculation starts
    notifyListeners(); // Notify about the status change

    final availablePieces = _state.pieces.where(
      (p) => p.color == _state.currentTurn && !p.isCaputured
    ).toList();

    if (availablePieces.isEmpty) {
      _state.gameOver = true;
      _isMoveInProgress = false; // Reset the flag when the calculation ends
      notifyListeners();
      return;
    }

    final thinkingTime = _difficulty == 'Easy' ? 300 :
                        _difficulty == 'Medium' ? 500 : 800;

    // Use a safer approach to perform delayed operations
    Timer(Duration(milliseconds: thinkingTime), () {
      if (_state.gameOver) {
        _isMoveInProgress = false; // Reset the flag when the calculation ends
        notifyListeners();
        return;
      }

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
          _movePiece(piece.position, newPosition);
          moveMade = true;
        }
        attempts++;
      }

      if (!moveMade) {
        _state.gameOver = true;
      }

      _isMoveInProgress = false; // Reset the flag when the calculation ends
      notifyListeners();
      saveState(); // Save state after all changes are complete
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

  void _movePiece(String from, String to) {
    final movingPiece = _getPieceAt(from);
    if (movingPiece == null) return;

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
    // Check if any king is captured
    final whiteKing = _state.pieces.any((p) =>
      p.type == PieceType.king &&
      p.color == PieceColor.white &&
      !p.isCaputured
    );

    final blackKing = _state.pieces.any((p) =>
      p.type == PieceType.king &&
      p.color == PieceColor.black &&
      !p.isCaputured
    );

    if (!whiteKing) {
      _state.gameOver = true;
      _state.winner = PieceColor.black;
    } else if (!blackKing) {
      _state.gameOver = true;
      _state.winner = PieceColor.white;
    } else {
      // Check if current player has no valid moves
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
  }
}

class MachineVsMachineState extends BaseGameState {
  MachineVsMachineState({
    List<ChessPiece>? pieces,
    String? selectedPosition,
    PieceColor currentTurn = PieceColor.white,
    bool gameOver = false,
    PieceColor? winner,
  }) : super(
          pieces: pieces,
          selectedPosition: selectedPosition,
          currentTurn: currentTurn,
          gameOver: gameOver,
          winner: winner,
        );

  Map<String, dynamic> toJson() {
    return {
      'pieces': pieces.map((piece) => piece.toJson()).toList(),
      'selectedPosition': selectedPosition,
      'currentTurn': currentTurn == PieceColor.white ? 'white' : 'black',
      'gameOver': gameOver,
      'winner': winner == null ? null : (winner == PieceColor.white ? 'white' : 'black'),
    };
  }

  factory MachineVsMachineState.fromJson(Map<String, dynamic> json) {
    final piecesList = (json['pieces'] as List)
        .map((pieceJson) => ChessPiece.fromJson(pieceJson))
        .toList();

    return MachineVsMachineState(
      pieces: piecesList,
      selectedPosition: json['selectedPosition'],
      currentTurn: json['currentTurn'] == 'white' ? PieceColor.white : PieceColor.black,
      gameOver: json['gameOver'] ?? false,
      winner: json['winner'] == null ? null : (json['winner'] == 'white' ? PieceColor.white : PieceColor.black),
    );
  }
}
