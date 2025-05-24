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

  // Getters
  List<ChessPiece> get pieces => _state.pieces;
  String? get selectedPosition => _state.selectedPosition;
  PieceColor get currentTurn => _state.currentTurn;
  bool get gameOver => _state.gameOver;

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
    // Implementation of valid moves calculation
    // This would be moved to a shared game logic utility class
    return [];
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
