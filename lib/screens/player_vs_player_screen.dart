import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/player_vs_player_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/chess_piece.dart';

class PlayerVsPlayerScreen extends StatelessWidget {
  const PlayerVsPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerVsPlayerProvider()..loadState(),
      child: PopScope(
        canPop: false,
        child: const PlayerVsPlayerView(),
      ),
    );
  }
}

class PlayerVsPlayerView extends StatelessWidget {
  const PlayerVsPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.read<PlayerVsPlayerProvider>().saveState();
              Navigator.of(context).pop();
            },
          ),
          Text(
            'Player vs Player',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<PlayerVsPlayerProvider>().initializeGame();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Consumer<PlayerVsPlayerProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerInfo(
                context,
                'White',
                Colors.white,
                provider.currentTurn == PieceColor.white,
              ),
              _buildPlayerInfo(
                context,
                'Black',
                Colors.black,
                provider.currentTurn == PieceColor.black,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentTurn
            ? Border.all(color: Colors.yellow.withAlpha(179), width: 2)
            : null,
      ),
      child: Text(
        '$name${isCurrentTurn ? "'s Turn" : ""}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
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
    return Consumer<PlayerVsPlayerProvider>(
      builder: (context, provider, _) {
        final piece = provider.pieces.firstWhereOrNull(
          (p) => p.position == position && !p.isCaputured,
        );

        final isSelected = provider.selectedPosition == position;
        final selectedPiece = provider.selectedPosition != null
            ? provider.pieces.firstWhereOrNull(
                (p) => p.position == provider.selectedPosition && !p.isCaputured)
            : null;
        final isValidMove = selectedPiece != null &&
            provider.getValidMoves(selectedPiece).contains(position);

        return GestureDetector(
          onTap: () => provider.selectPosition(position),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF769656)
                  : const Color(0xFFEEEED2),
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 3)
                  : isValidMove
                      ? Border.all(color: Colors.yellow.withOpacity(0.7), width: 3)
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

    return Center(
      child: FaIcon(
        icon,
        color: piece.color == PieceColor.white ? Colors.white : Colors.black,
        size: 32,
      ),
    );
  }
}

