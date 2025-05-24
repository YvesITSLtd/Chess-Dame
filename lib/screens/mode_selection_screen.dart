import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'settings_screen.dart';
import 'player_vs_player_screen.dart';
import 'player_vs_machine_screen.dart';
import 'machine_vs_machine_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
            child: Center(
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'Chess Dame',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by ITS Ltd',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withAlpha(179),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildModeButton(
                    context,
                    'Player vs Player',
                    'Challenge a friend',
                    Icons.people,
                    const PlayerVsPlayerScreen(),
                  ),
                  const SizedBox(height: 20),
                  _buildModeButton(
                    context,
                    'Player vs Machine',
                    'Challenge the computer',
                    Icons.smart_toy,
                    const PlayerVsMachineScreen(),
                  ),
                  const SizedBox(height: 20),
                  _buildModeButton(
                    context,
                    'Machine vs Machine',
                    'Watch AI play',
                    Icons.auto_awesome,
                    const MachineVsMachineScreen(),
                  ),
                  const Spacer(),
                  _buildBottomButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularButton(
          context,
          Icons.settings,
          'Settings',
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          ),
        ),
        const SizedBox(width: 32),
        _buildCircularButton(
          context,
          Icons.share,
          'Share',
              () => Share.share(
            'Check out Chess Dame - An awesome chess game! Play with friends or challenge the AI.',
            subject: 'Chess Dame Game',
          ),
        ),
      ],
    );
  }

  Widget _buildCircularButton(
      BuildContext context,
      IconData icon,
      String tooltip,
      VoidCallback onPressed,
      ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(25),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Widget screen,
      ) {
    return Container(
      width: 280,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: Colors.white.withAlpha(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withAlpha(179),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
