import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/machine_vs_machine_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/chess_piece.dart';

class MachineVsMachineScreen extends StatelessWidget {
  const MachineVsMachineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MachineVsMachineProvider()..loadState(),
      child: PopScope(
        canPop: false,
        child: const MachineVsMachineView(),
      ),
    );
  }
}

class MachineVsMachineView extends StatefulWidget {
  const MachineVsMachineView({super.key});

  @override
  State<MachineVsMachineView> createState() => _MachineVsMachineViewState();
}

class _MachineVsMachineViewState extends State<MachineVsMachineView> {
  bool _gameOverDialogShown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MachineVsMachineProvider>(
        builder: (context, provider, child) {
          // Check for game over and show dialog only once
          if (provider.gameOver && provider.winner != null && !_gameOverDialogShown) {
            _gameOverDialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showGameOverDialog(context, provider.winner!);
            });
          }

          // Reset the flag when game is not over (new game started)
          if (!provider.gameOver) {
            _gameOverDialogShown = false;
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF009688), // Teal
                  const Color(0xFFE53935), // Red
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const Expanded(
                    child: ChessBoard(),
                  ),
                  _buildControls(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, PieceColor winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Game Over!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.trophy,
                size: 48,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                '${winner == PieceColor.white ? 'White' : 'Black'} Machine Wins!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The opposing machine has no valid moves remaining.',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog first
                final provider = context.read<MachineVsMachineProvider>();
                provider.initializeGame();
                setState(() {
                  _gameOverDialogShown = false; // Reset flag
                });
              },
              child: const Text('New Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog first
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Back to Menu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<MachineVsMachineProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  provider.saveState();
                  Navigator.of(context).pop();
                },
              ),
              Text(
                provider.isAutoPlaying ? 'Auto-Playing' : 'Machine vs Machine',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  provider.isAutoPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () => provider.toggleAutoPlay(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return Consumer<MachineVsMachineProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerInfo(
                    context,
                    'AI White',
                    Colors.white,
                    provider.currentTurn == PieceColor.white,
                    FontAwesomeIcons.robot,
                  ),
                  _buildPlayerInfo(
                    context,
                    'AI Black',
                    Colors.black,
                    provider.currentTurn == PieceColor.black,
                    FontAwesomeIcons.robot,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!provider.isAutoPlaying && !provider.gameOver)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(25),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => provider.startAutoPlay(),
                  child: const Text('Start Auto-Play'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerInfo(
    BuildContext context,
    String name,
    Color color,
    bool isCurrentTurn,
    IconData icon,
  ) {
    return Consumer<MachineVsMachineProvider>(
      builder: (context, provider, _) {
        final score = provider.getPlayerScore(color == Colors.white ? PieceColor.white : PieceColor.black);
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: isCurrentTurn
                ? Border.all(color: Colors.yellow.withAlpha(179), width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$name${isCurrentTurn ? "'s Turn" : ""}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $score',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final col = index % 8;
              final isDark = (row + col) % 2 == 1;
              final position = '${String.fromCharCode(97 + col)}${8 - row}';
              return ChessTile(
                isDark: isDark,
                position: position,
              );
            },
          ),
        ),
      ),
    );
  }
}

class ChessTile extends StatelessWidget {
  final bool isDark;
  final String position;

  const ChessTile({
    super.key,
    required this.isDark,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MachineVsMachineProvider>(
      builder: (context, provider, _) {
        final piece = provider.pieces.firstWhereOrNull(
          (p) => p.position == position && !p.isCaputured,
        );

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF3E2723) // Dark brown/metallic
                : const Color(0xFF8D6E63), // Light brown/metallic
          ),
          child: piece != null ? _buildPieceIcon(piece) : null,
        );
      },
    );
  }

  Widget _buildPieceIcon(ChessPiece piece) {
    final IconData icon;
    switch (piece.type) {
      case PieceType.pawn:
        icon = FontAwesomeIcons.chessPawn;
        break;
      case PieceType.rook:
        icon = FontAwesomeIcons.chessRook;
        break;
      case PieceType.knight:
        icon = FontAwesomeIcons.chessKnight;
        break;
      case PieceType.bishop:
        icon = FontAwesomeIcons.chessBishop;
        break;
      case PieceType.queen:
        icon = FontAwesomeIcons.chessQueen;
        break;
      case PieceType.king:
        icon = FontAwesomeIcons.chessKing;
        break;
    }

    return Center(
      child: Container(
        decoration: piece.color == PieceColor.white 
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              )
            : null,
        child: FaIcon(
          icon,
          color: piece.color == PieceColor.white ? Colors.white : Colors.black,
          size: 32,
        ),
      ),
    );
  }
}
