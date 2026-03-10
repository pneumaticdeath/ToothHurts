import 'package:flutter/material.dart';

import 'game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98E4FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildTitle(),
              const Spacer(flex: 1),
              _buildBabyEmoji(),
              const Spacer(flex: 1),
              _buildTagline(),
              const Spacer(flex: 2),
              _buildPlayButton(context),
              const SizedBox(height: 24),
              _buildHowToPlay(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          '🦷 ToothHurts',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Count the baby\'s teeth!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBabyEmoji() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 3),
      ),
      child: const Center(
        child: Text('👶', style: TextStyle(fontSize: 88)),
      ),
    );
  }

  Widget _buildTagline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Watch out for biting,\nthe wiggly tongue, and the squirming!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white.withOpacity(0.9),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _startGame(context),
      child: Container(
        width: 220,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B8A),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B8A).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '🎮  PLAY',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlay() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _HintRow(icon: '👆', text: 'Tap each tooth to count it'),
          SizedBox(height: 8),
          _HintRow(icon: '😬', text: 'Hold too long → OUCH!'),
          SizedBox(height: 8),
          _HintRow(icon: '👅', text: 'Wait for the tongue to move'),
          SizedBox(height: 8),
          _HintRow(icon: '🤸', text: 'Keep up with the squirming!'),
        ],
      ),
    );
  }

  void _startGame(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

class _HintRow extends StatelessWidget {
  final String icon;
  final String text;

  const _HintRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }
}
