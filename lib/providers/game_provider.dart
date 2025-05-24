import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/chess_piece.dart';
import '../utils/sound_manager.dart';

enum GameMode {
  playerVsPlayer,
  playerVsMachine,
  machineVsMachine
}

class GameProvider with ChangeNotifier {
  static const String _baseStorageKey = 'chess_game_state';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _difficultyKey = 'game_difficulty';

  String get _storageKey => '${_baseStorageKey}_${_gameMode.toString().split('.').last}';

  final SoundManager _soundManager = SoundManager();

  List<ChessPiece> _pieces = [];
  String? _selectedPosition;
  PieceColor _currentTurn = PieceColor.white;
  bool _gameOver = false;
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  GameMode _gameMode = GameMode.playerVsPlayer;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _difficulty = 'Medium';

  List<ChessPiece> get pieces => _pieces;
  String? get selectedPosition => _selectedPosition;
  PieceColor get currentTurn => _currentTurn;
  bool get gameOver => _gameOver;
  bool get isAutoPlaying => _isAutoPlaying;
  GameMode get gameMode => _gameMode;

  // Add getters for settings
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get difficulty => _difficulty;

  // Add update methods for settings
  Future<void> updateSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
    notifyListeners();
  }

  Future<void> updateVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
    notifyListeners();
  }

  Future<void> updateDifficulty(String value) async {
    _difficulty = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyKey, value);
    notifyListeners();
  }

  Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gameStateJson = prefs.getString(_storageKey);

    if (gameStateJson != null) {
      try {
        final gameState = jsonDecode(gameStateJson);
        _currentTurn = PieceColor.values[gameState['currentTurn']];
        _gameOver = gameState['gameOver'];
        _isAutoPlaying = gameState['isAutoPlaying'] ?? false;

        _pieces = (gameState['pieces'] as List).map((piece) => ChessPiece(
          type: PieceType.values[piece['type']],
          color: PieceColor.values[piece['color']],
          position: piece['position'],
          isCaputured: piece['isCaptured'],
        )).toList();

        notifyListeners();
      } catch (e) {
        _pieces = [];
      }
    } else {
      _pieces = [];
    }
  }

  Future<void> saveGameState() async {
    if (_pieces.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final gameState = {
      'currentTurn': _currentTurn.index,
      'gameOver': _gameOver,
      'gameMode': _gameMode.index,
      'isAutoPlaying': _isAutoPlaying,
      'pieces': _pieces.map((piece) => {
        'type': piece.type.index,
        'color': piece.color.index,
        'position': piece.position,
        'isCaptured': piece.isCaputured,
      }).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(gameState));
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    _difficulty = prefs.getString(_difficultyKey) ?? 'Medium';
    notifyListeners();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _soundManager.dispose();
    super.dispose();
  }

  Future<void> setGameMode(GameMode mode) async {
    _stopAutoPlay();
    _gameMode = mode;

    // Save current state before switching mode
    if (_pieces.isNotEmpty) {
      await saveGameState();
    }

    // Load state for new mode
    await loadGameState();

    // If no saved state exists for this mode, initialize new game
    if (_pieces.isEmpty) {
      initializeGame();
    } else if (_gameMode == GameMode.machineVsMachine) {
      _startAutoPlay();
    } else if (_gameMode == GameMode.playerVsMachine && _currentTurn == PieceColor.black) {
      _makeMachineMove();
    }
  }

  void initializeGame() {
    loadSettings(); // Load settings first
    _pieces = [];
    _setupInitialBoard();
    _selectedPosition = null;
    _currentTurn = PieceColor.white;
    _gameOver = false;
    _stopAutoPlay();
    _isAutoPlaying = false;

    if (_gameMode == GameMode.machineVsMachine) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startAutoPlay();
      });
    }

    notifyListeners();
    saveGameState();
  }

  void toggleAutoPlay() {
    if (_gameMode != GameMode.machineVsMachine) return;

    if (_isAutoPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (_gameMode != GameMode.machineVsMachine || _gameOver) return;

    _isAutoPlaying = true;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameOver) {
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

  Future<void> _playSound(String soundType) async {
    if (!_soundEnabled) return;
    try {
      if (soundType == 'move') {
        await _soundManager.playMoveSound();
      } else if (soundType == 'capture') {
        await _soundManager.playCaptureSound();
      }
    } catch (e) {
      // Silently fail if sound playback fails
    }
  }

  Future<void> _vibrate() async {
    if (!_vibrationEnabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 100);
    }
  }

  void _makeMachineMove() {
    if (_gameOver) return;

    final availablePieces = _pieces.where((p) => p.color == _currentTurn && !p.isCaputured).toList();
    if (availablePieces.isEmpty) {
      _gameOver = true;
      notifyListeners();
      return;
    }

    // Adjust AI behavior based on difficulty
    final thinkingTime = _difficulty == 'Easy' ? 300 :
                        _difficulty == 'Medium' ? 500 : 800;

    Future.delayed(Duration(milliseconds: thinkingTime), () {
      if (_gameOver) return;

      final random = Random();
      int attempts = 0;
      bool moveMade = false;

      // Adjust number of attempts based on difficulty
      final maxAttempts = _difficulty == 'Easy' ? 3 :
                         _difficulty == 'Medium' ? 5 : 10;

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
        _gameOver = true;
        notifyListeners();
      }
    });
  }

  String _getBestMove(List<String> possibleMoves, ChessPiece piece) {
    if (_difficulty == 'Easy') {
      // Choose random move
      return possibleMoves[Random().nextInt(possibleMoves.length)];
    }

    // For Medium and Hard, try to find capturing moves
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
    final List<String> validMoves = [];
    final currentFile = piece.position[0];
    final currentRank = int.parse(piece.position[1]);

    switch (piece.type) {
      case PieceType.pawn:
        final direction = piece.color == PieceColor.white ? 1 : -1;
        final newRank = currentRank + direction;
        if (newRank >= 1 && newRank <= 8) {
          final forwardMove = '$currentFile$newRank';
          if (!_isPositionOccupied(forwardMove)) {
            validMoves.add(forwardMove);
          }
          for (final offset in [-1, 1]) {
            final newFile = String.fromCharCode(currentFile.codeUnitAt(0) + offset);
            if (newFile.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
                newFile.codeUnitAt(0) <= 'h'.codeUnitAt(0)) {
              final diagonalMove = '$newFile$newRank';
              final targetPiece = _getPieceAt(diagonalMove);
              if (targetPiece != null && targetPiece.color != piece.color) {
                validMoves.add(diagonalMove);
              }
            }
          }
        }
        break;

      case PieceType.rook:
        _addStraightMoves(validMoves, currentFile, currentRank, piece.color);
        break;
      case PieceType.bishop:
        _addDiagonalMoves(validMoves, currentFile, currentRank, piece.color);
        break;
      case PieceType.queen:
        _addStraightMoves(validMoves, currentFile, currentRank, piece.color);
        _addDiagonalMoves(validMoves, currentFile, currentRank, piece.color);
        break;
      case PieceType.king:
        for (var fileOffset = -1; fileOffset <= 1; fileOffset++) {
          for (var rankOffset = -1; rankOffset <= 1; rankOffset++) {
            if (fileOffset == 0 && rankOffset == 0) continue;
            final newFile = String.fromCharCode(currentFile.codeUnitAt(0) + fileOffset);
            final newRank = currentRank + rankOffset;
            if (_isValidPosition(newFile, newRank)) {
              final newPos = '$newFile$newRank';
              if (!_isPositionOccupiedByColor(newPos, piece.color)) {
                validMoves.add(newPos);
              }
            }
          }
        }
        break;
      case PieceType.knight:
        final knightMoves = [
          (-2, -1), (-2, 1), (-1, -2), (-1, 2),
          (1, -2), (1, 2), (2, -1), (2, 1)
        ];
        for (final move in knightMoves) {
          final newFile = String.fromCharCode(currentFile.codeUnitAt(0) + move.$1);
          final newRank = currentRank + move.$2;
          if (_isValidPosition(newFile, newRank)) {
            final newPos = '$newFile$newRank';
            if (!_isPositionOccupiedByColor(newPos, piece.color)) {
              validMoves.add(newPos);
            }
          }
        }
        break;
    }
    return validMoves;
  }

  void _addStraightMoves(List<String> moves, String file, int rank, PieceColor color) {
    for (var f = 'a'.codeUnitAt(0); f <= 'h'.codeUnitAt(0); f++) {
      final newFile = String.fromCharCode(f);
      if (newFile != file) {
        final newPos = '$newFile$rank';
        if (!_isPositionOccupiedByColor(newPos, color)) {
          moves.add(newPos);
        }
      }
    }
    for (var r = 1; r <= 8; r++) {
      if (r != rank) {
        final newPos = '$file$r';
        if (!_isPositionOccupiedByColor(newPos, color)) {
          moves.add(newPos);
        }
      }
    }
  }

  void _addDiagonalMoves(List<String> moves, String file, int rank, PieceColor color) {
    for (var direction in [(-1, -1), (-1, 1), (1, -1), (1, 1)]) {
      var currentFile = file.codeUnitAt(0);
      var currentRank = rank;
      while (true) {
        currentFile += direction.$1;
        currentRank += direction.$2;
        if (!_isValidPosition(String.fromCharCode(currentFile), currentRank)) break;
        final newPos = '${String.fromCharCode(currentFile)}$currentRank';
        if (_isPositionOccupiedByColor(newPos, color)) break;
        moves.add(newPos);
        if (_isPositionOccupied(newPos)) break;
      }
    }
  }

  bool _isValidPosition(String file, int rank) {
    return file.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
           file.codeUnitAt(0) <= 'h'.codeUnitAt(0) &&
           rank >= 1 &&
           rank <= 8;
  }

  bool _isPositionOccupied(String position) {
    return _pieces.any((p) => p.position == position && !p.isCaputured);
  }

  bool _isPositionOccupiedByColor(String position, PieceColor color) {
    return _pieces.any((p) =>
      p.position == position &&
      p.color == color &&
      !p.isCaputured
    );
  }

  ChessPiece? _getPieceAt(String position) {
    try {
      return _pieces.firstWhere(
        (p) => p.position == position && !p.isCaputured,
      );
    } catch (e) {
      return null;
    }
  }

  void selectPosition(String position) {
    if (_gameMode == GameMode.machineVsMachine) return;
    if (_gameMode == GameMode.playerVsMachine && _currentTurn == PieceColor.black) return;

    final selectedPiece = _getPieceAt(position);
    if (selectedPiece?.color == _currentTurn) {
      _selectedPosition = position;
      notifyListeners();
    } else if (_selectedPosition != null) {
      movePiece(_selectedPosition!, position);
    }
  }

  void movePiece(String from, String to) {
    final movingPiece = _getPieceAt(from);
    if (movingPiece == null || movingPiece.color != _currentTurn) return;

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
    _selectedPosition = null;
    _currentTurn = _currentTurn == PieceColor.white ? PieceColor.black : PieceColor.white;

    _checkGameOver();

    if (!_gameOver &&
        _gameMode == GameMode.playerVsMachine &&
        _currentTurn == PieceColor.black) {
      _makeMachineMove();
    }

    notifyListeners();
    saveGameState();
  }

  void _checkGameOver() {
    bool canMove = false;
    for (final piece in _pieces.where((p) => p.color == _currentTurn && !p.isCaputured)) {
      if (getValidMoves(piece).isNotEmpty) {
        canMove = true;
        break;
      }
    }
    if (!canMove) {
      _gameOver = true;
    }
  }

  void _setupInitialBoard() {
    _setupPieces(PieceColor.white);
    _setupPieces(PieceColor.black);
  }

  void _setupPieces(PieceColor color) {
    int pawnRow = color == PieceColor.white ? 1 : 6;
    int pieceRow = color == PieceColor.white ? 0 : 7;

    for (int i = 0; i < 8; i++) {
      _pieces.add(ChessPiece(
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
      _pieces.add(ChessPiece(
        type: pieceSetup[i],
        color: color,
        position: '${String.fromCharCode(97 + i)}${pieceRow + 1}',
      ));
    }
  }

  int getPlayerScore(PieceColor color) {
    return _pieces
        .where((p) => p.color == color && !p.isCaputured)
        .fold(0, (sum, piece) => sum + piece.points);
  }

  PieceColor? getWinningPlayer() {
    if (!_gameOver) return null;
    final whiteScore = getPlayerScore(PieceColor.white);
    final blackScore = getPlayerScore(PieceColor.black);
    if (whiteScore == blackScore) return null;
    return whiteScore > blackScore ? PieceColor.white : PieceColor.black;
  }
}
