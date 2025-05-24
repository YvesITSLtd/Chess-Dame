import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/chess_piece.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
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
                _buildPlayerIcons(context),
                _buildScoreBoard(context),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              final status = gameProvider.gameOver
                  ? 'Game Over!'
                  : gameProvider.isAutoPlaying
                      ? 'Auto-Playing'
                      : 'Chess Dame';
              return Text(
                status,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ).animate()
                .fadeIn()
                .scale();
            },
          ),
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              if (gameProvider.gameMode == GameMode.machineVsMachine) {
                return IconButton(
                  icon: Icon(
                    gameProvider.isAutoPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () => gameProvider.toggleAutoPlay(),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => gameProvider.initializeGame(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIcons(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        IconData whiteIcon = FontAwesomeIcons.user;
        IconData blackIcon = FontAwesomeIcons.user;

        switch (gameProvider.gameMode) {
          case GameMode.playerVsPlayer:
            whiteIcon = FontAwesomeIcons.user;
            blackIcon = FontAwesomeIcons.userGroup;
            break;
          case GameMode.playerVsMachine:
            whiteIcon = FontAwesomeIcons.user;
            blackIcon = FontAwesomeIcons.robot;
            break;
          case GameMode.machineVsMachine:
            whiteIcon = FontAwesomeIcons.robot;
            blackIcon = FontAwesomeIcons.robot;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerIcon(
                context,
                whiteIcon,
                'White',
                Colors.white,
                gameProvider.currentTurn == PieceColor.white,
              ),
              _buildPlayerIcon(
                context,
                blackIcon,
                'Black',
                Colors.black,
                gameProvider.currentTurn == PieceColor.black,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerIcon(
    BuildContext context,
    IconData icon,
    String playerName,
    Color color,
    bool isCurrentTurn,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentTurn
            ? Border.all(
                color: Colors.yellow.withOpacity(0.7),
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            color: color,
            size: 24,
          ).animate(
            onPlay: (controller) => isCurrentTurn ? controller.repeat(reverse: true) : controller.stop(),
          ).scale(
            duration: const Duration(seconds: 1),
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            playerName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          final whiteScore = gameProvider.getPlayerScore(PieceColor.white);
          final blackScore = gameProvider.getPlayerScore(PieceColor.black);
          final winner = gameProvider.getWinningPlayer();

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerScore(
                    context,
                    'White',
                    whiteScore,
                    Colors.white,
                    winner == PieceColor.white,
                  ),
                  _buildPlayerScore(
                    context,
                    'Black',
                    blackScore,
                    Colors.black,
                    winner == PieceColor.black,
                  ),
                ],
              ),
              if (gameProvider.gameOver)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    winner == null
                        ? 'Game Over - It\'s a tie!'
                        : 'Game Over - ${winner == PieceColor.white ? "White" : "Black"} wins!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate()
                    .fadeIn()
                    .scale(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerScore(
    BuildContext context,
    String playerName,
    int score,
    Color color,
    bool isWinner,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isWinner
            ? Border.all(color: Colors.yellow, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.emoji_events,
                color: Colors.yellow,
                size: 20,
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn()
      .scale();
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          return Text(
            '${gameProvider.currentTurn.toString().split('.').last}\'s turn',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ).animate()
            .fadeIn()
            .scale();
        },
      ),
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
              color: Colors.black.withOpacity(0.2),
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
              ).animate()
                .fadeIn(delay: Duration(milliseconds: index * 20))
                .scale(delay: Duration(milliseconds: index * 20));
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
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final piece = gameProvider.pieces
            .where((p) => p.position == position && !p.isCaputured)
            .firstOrNull;

        final isSelected = gameProvider.selectedPosition == position;
        final selectedPiece = gameProvider.selectedPosition != null
            ? gameProvider.pieces
                .where((p) =>
                    p.position == gameProvider.selectedPosition &&
                    !p.isCaputured)
                .firstOrNull
            : null;
        final isValidMove = selectedPiece != null &&
            gameProvider.getValidMoves(selectedPiece).contains(position);

        return GestureDetector(
          onTap: () {
            if (!gameProvider.isAutoPlaying) {
              gameProvider.selectPosition(position);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF769656)
                  : const Color(0xFFEEEED2),
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 3)
                  : isValidMove
                      ? Border.all(
                          color: Colors.yellow.withOpacity(0.7),
                          width: 3,
                        )
                      : null,
            ),
            child: Stack(
              children: [
                if (piece != null)
                  Center(
                    child: _buildPieceIcon(piece),
                  ),
                if (isValidMove && piece != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isValidMove && piece == null)
                  Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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

    return Stack(
      alignment: Alignment.center,
      children: [
        FaIcon(
          icon,
          color: piece.color == PieceColor.white ? Colors.white : Colors.black,
          size: 32,
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scale(
          duration: const Duration(seconds: 1),
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
        ),
        if (piece.points > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: piece.color == PieceColor.white
                    ? Colors.blue.withOpacity(0.7)
                    : Colors.red.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${piece.points}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
