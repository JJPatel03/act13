// lib/screens/signup_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'success_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // UI state
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedAvatar; // emoji string

  // Progress / milestones
  double _progress = 0.0; // 0.0 - 1.0
  String? _milestoneMessage;
  Timer? _milestoneTimer;
  final ConfettiController _milestoneConfetti =
      ConfettiController(duration: const Duration(seconds: 2));

  // Shake animation for form-level error
  late AnimationController _formShakeController;
  late Animation<double> _formShakeAnimation;

  @override
  void initState() {
    super.initState();
    // attach listeners to update progress in real-time
    _nameController.addListener(_updateProgress);
    _emailController.addListener(_updateProgress);
    _passwordController.addListener(_updateProgress);
    _dobController.addListener(_updateProgress);

    _formShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _formShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_formShakeController);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _milestoneConfetti.dispose();
    _milestoneTimer?.cancel();
    _formShakeController.dispose();
    super.dispose();
  }

  // --- Avatar Options (emoji so no assets required) ---
  final List<String> _avatars = ['🦊', '🐼', '🦄', '🐵', '🐱'];

  // --- Date Picker ---
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      _updateProgress();
    }
  }

  // --- Password Strength ---
  double _passwordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double score = 0;
    if (password.length >= 8) score += 0.35;
    else if (password.length >= 6) score += 0.2;
    else score += 0.05;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.2;
    if (password.contains(RegExp(r'\d'))) score += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.25;
    if (score > 1.0) score = 1.0;
    return score;
  }

  Color _strengthColor(double strength) {
    if (strength < 0.25) return Colors.red;
    if (strength < 0.5) return Colors.orange;
    if (strength < 0.75) return Colors.amber;
    return Colors.green;
  }

  String _strengthLabel(double strength) {
    if (strength < 0.25) return 'Very Weak';
    if (strength < 0.5) return 'Weak';
    if (strength < 0.75) return 'Good';
    return 'Strong';
  }

  // --- Progress Bar ---
  void _updateProgress() {
    int completed = 0;
    if (_nameController.text.trim().isNotEmpty) completed++;
    if (_isValidEmail(_emailController.text.trim())) completed++;
    if (_dobController.text.trim().isNotEmpty) completed++;
    if (_passwordController.text.trim().isNotEmpty) completed++;

    double newProgress = (completed / 4.0);

    final milestoneSteps = [0.25, 0.5, 0.75, 1.0];
    for (var m in milestoneSteps) {
      if (_progress < m && newProgress >= m) {
        _onMilestoneReached(m);
        break;
      }
    }

    setState(() {
      _progress = newProgress;
    });
  }

  void _onMilestoneReached(double milestone) {
    String message;
    switch (milestone) {
      case 0.25:
        message = 'Nice start! You\'re 25% into your adventure 🚀';
        break;
      case 0.5:
        message = 'Awesome — 50% done! Keep it up ✨';
        break;
      case 0.75:
        message = 'So close! 75% — nearly there 🏁';
        break;
      case 1.0:
        message = 'Complete! 100% — prepare for launch! 🎉';
        break;
      default:
        message = 'Progress!';
    }

    _milestoneTimer?.cancel();
    setState(() {
      _milestoneMessage = message;
    });

    _milestoneConfetti.play();

    _milestoneTimer = Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _milestoneMessage = null;
      });
    });
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  // --- Submit ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _milestoneConfetti.stop();

        final double strength = _passwordStrength(_passwordController.text);
        final bool strongPassword = strength >= 0.75;
        final DateTime now = DateTime.now();
        final bool earlyBird = now.hour < 12;
        final bool profileCompleter = _nameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _dobController.text.trim().isNotEmpty &&
            _passwordController.text.trim().isNotEmpty &&
            (_selectedAvatar != null);

        final List<String> badges = [];
        if (strongPassword) badges.add('Strong Password Master');
        if (earlyBird) badges.add('The Early Bird Special');
        if (profileCompleter) badges.add('Profile Completer');

        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              userName: _nameController.text.trim(),
              avatarEmoji: _selectedAvatar,
              badges: badges,
            ),
          ),
        );
      });
    } else {
      _formShakeController.forward(from: 0); // Shake form
      _updateProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pwdStrength = _passwordStrength(_passwordController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account 🎉'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _milestoneConfetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.02,
              numberOfParticles: 12,
              maxBlastForce: 20,
              minBlastForce: 5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _formShakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_formShakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tips_and_updates,
                                color: Colors.deepPurple[800]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Complete your adventure profile!',
                                style: TextStyle(
                                  color: Colors.deepPurple[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(_progress * 100).round()}% complete',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      if (_milestoneMessage != null) ...[
                        const SizedBox(height: 12),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _milestoneMessage != null ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.deepPurple.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.celebration,
                                    color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _milestoneMessage ?? '',
                                    style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Name
                      _AnimatedField(
                        controller: _nameController,
                        label: 'Adventure Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'What should we call you on this adventure?';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _AnimatedField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'We need your email for adventure updates!';
                          }
                          if (!_isValidEmail(value.trim())) {
                            return 'Oops! That doesn\'t look like a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // DOB
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: const Icon(Icons.calendar_today,
                              color: Colors.deepPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: _selectDate,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'When did your adventure begin?';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password + strength
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        onChanged: (_) => _updateProgress(),
                        decoration: InputDecoration(
                          labelText: 'Secret Password',
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.deepPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_passwordController.text.isNotEmpty &&
                                  _passwordStrength(
                                          _passwordController.text) >=
                                      0.75)
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                              IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Every adventurer needs a secret password!';
                          }
                          if (value.length < 6) {
                            return 'Make it stronger! At least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: pwdStrength,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _strengthColor(pwdStrength)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _strengthLabel(pwdStrength),
                            style: TextStyle(
                                color: _strengthColor(pwdStrength),
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Avatar
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose your avatar',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.deepPurple[800],
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: _avatars.map((emoji) {
                          final bool selected = _selectedAvatar == emoji;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatar = emoji;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: selected
                                        ? Colors.deepPurple
                                        : Colors.transparent,
                                    width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: selected
                                    ? Colors.deepPurple[50]
                                    : Colors.white,
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isLoading ? 60 : double.infinity,
                        height: 60,
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.deepPurple),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  elevation: 5,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Start My Adventure',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.rocket_launch,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Badges: Complete profile + strong password + sign up before 12 PM.',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ Animated Field ------------------
class _AnimatedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;

  const _AnimatedField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
  });

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  bool _valid = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final result = widget.validator(value);
    if (result != null) {
      _errorText = result;
      _valid = false;
      _controller.forward(from: 0);
    } else {
      _errorText = null;
      if (!_valid) {
        _valid = true;
        _controller.forward(from: 0);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double bounce = _valid ? 1 + 0.1 * (_controller.value) : 1.0;
        double offsetX = _errorText != null ? _shakeAnimation.value : 0.0;
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: Transform.scale(
            scale: bounce,
            child: TextFormField(
              controller: widget.controller,
              onChanged: _validate,
              decoration: InputDecoration(
                labelText: widget.label,
                prefixIcon: Icon(widget.icon, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                errorText: _errorText,
                suffixIcon: _valid
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              validator: widget.validator,
            ),
          ),
        );
      },
    );
  }
}
