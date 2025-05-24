import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import 'mode_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _difficulty = 'Medium';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.loadSettings();
    if (mounted) {
      setState(() {
        _soundEnabled = gameProvider.soundEnabled;
        _vibrationEnabled = gameProvider.vibrationEnabled;
        _difficulty = gameProvider.difficulty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Set to false to handle pop manually
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF009688), // Teal
                Color(0xFFE53935), // Red
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSettingCard(
                        title: 'Sound Effects',
                        subtitle: 'Enable or disable game sounds',
                        icon: Icons.volume_up,
                        trailing: Switch(
                          value: _soundEnabled,
                          onChanged: (value) {
                            setState(() {
                              _soundEnabled = value;
                            });
                            context.read<GameProvider>().updateSoundEnabled(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingCard(
                        title: 'Vibration',
                        subtitle: 'Enable or disable haptic feedback',
                        icon: Icons.vibration,
                        trailing: Switch(
                          value: _vibrationEnabled,
                          onChanged: (value) {
                            setState(() {
                              _vibrationEnabled = value;
                            });
                            context.read<GameProvider>().updateVibrationEnabled(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingCard(
                        title: 'AI Difficulty',
                        subtitle: 'Set the computer player difficulty',
                        icon: Icons.psychology,
                        trailing: DropdownButton<String>(
                          value: _difficulty,
                          dropdownColor: Theme.of(context).colorScheme.primary,
                          style: const TextStyle(color: Colors.white),
                          items: const ['Easy', 'Medium', 'Hard']
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _difficulty = newValue;
                              });
                              context.read<GameProvider>().updateDifficulty(newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
          ),
        ),
        trailing: trailing,
      ),
    ).animate()
      .fadeIn()
      .scale();
  }
}
