// lib/screens/success_screen.dart
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';

class SuccessScreen extends StatefulWidget {
  final String userName;
  final String? avatarEmoji;
  final List<String> badges;

  const SuccessScreen({
    super.key,
    required this.userName,
    this.avatarEmoji,
    this.badges = const [],
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildBadgeTile(String badge) {
    IconData icon;
    Color bg;
    switch (badge) {
      case 'Strong Password Master':
        icon = Icons.shield;
        bg = Colors.green;
        break;
      case 'The Early Bird Special':
        icon = Icons.wb_sunny;
        bg = Colors.orange;
        break;
      case 'Profile Completer':
        icon = Icons.check_circle;
        bg = Colors.deepPurple;
        break;
      default:
        icon = Icons.star;
        bg = Colors.grey;
    }

    return Chip(
      avatar: CircleAvatar(
        backgroundColor: bg,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      label: Text(badge),
      backgroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = widget.avatarEmoji != null;

    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.deepPurple,
                Colors.purple,
                Colors.blue,
                Colors.green,
                Colors.orange,
              ],
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar display
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: hasAvatar
                          ? Text(
                              widget.avatarEmoji!,
                              style: const TextStyle(fontSize: 64),
                            )
                          : const Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 80,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome text
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Welcome, ${widget.userName}! 🎉',
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your adventure begins now!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Badges preview
                  if (widget.badges.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple[800],
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.badges.map(_buildBadgeTile).toList(),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      'No badges yet — complete your profile to earn achievements!',
                      style: TextStyle(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],

                  ElevatedButton(
                    onPressed: () {
                      _confettiController.play();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'More Celebration!',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
