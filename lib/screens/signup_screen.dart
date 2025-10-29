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

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // UI state
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedAvatar; // emoji string, e.g. '🦊'

  // Progress / milestones
  double _progress = 0.0; // 0.0 - 1.0
  String? _milestoneMessage;
  Timer? _milestoneTimer;
  final ConfettiController _milestoneConfetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    // attach listeners to update progress in real-time
    _nameController.addListener(_updateProgress);
    _emailController.addListener(_updateProgress);
    _passwordController.addListener(_updateProgress);
    _dobController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _milestoneConfetti.dispose();
    _milestoneTimer?.cancel();
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
  /// Returns strength 0.0 - 1.0
  double _passwordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double score = 0;

    // length
    if (password.length >= 8) score += 0.35;
    else if (password.length >= 6) score += 0.2;
    else score += 0.05;

    // has uppercase
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.2;

    // has digits
    if (password.contains(RegExp(r'\d'))) score += 0.2;

    // has special chars
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.25;

    if (score > 1.0) score = 1.0;
    return score;
  }

  Color _strengthColor(double strength) {
    // red -> orange -> yellow -> green
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

  // --- Progress Bar (based on the four main form fields) ---
  // The requirement asked for 25/50/75/100 milestones, so we base progress
  // on name, email, dob, and password (4 fields => 25% each).
  void _updateProgress() {
    int completed = 0;
    if (_nameController.text.trim().isNotEmpty) completed++;
    if (_isValidEmail(_emailController.text.trim())) completed++;
    if (_dobController.text.trim().isNotEmpty) completed++;
    if (_passwordController.text.trim().isNotEmpty) completed++;

    double newProgress = (completed / 4.0);
    // If progress increased and reached a milestone, celebrate
    // milestones at 0.25, 0.5, 0.75, 1.0
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

    // trigger confetti
    _milestoneConfetti.play();

    // hide message after 2.5s
    _milestoneTimer = Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _milestoneMessage = null;
      });
    });
  }

  // --- Simple email validator used for progress count ---
  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  // --- Submit + Achievements logic ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // simulate delay / API
      Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
        if (!mounted) return;
        _milestoneConfetti.stop();

        // compute badges
        final double strength = _passwordStrength(_passwordController.text);
        final bool strongPassword = strength >= 0.75;
        final DateTime now = DateTime.now();
        final bool earlyBird = now.hour < 12; // before 12 PM
        final bool profileCompleter = _nameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _dobController.text.trim().isNotEmpty &&
            _passwordController.text.trim().isNotEmpty &&
            (_selectedAvatar != null);

        final List<String> badges = [];
        if (strongPassword) badges.add('Strong Password Master');
        if (earlyBird) badges.add('The Early Bird Special');
        if (profileCompleter) badges.add('Profile Completer');

        setState(() {
          _isLoading = false;
        });

        // Navigate to success screen passing avatar and badges
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
      // still update progress in case validation failed but fields changed
      _updateProgress();
    }
  }

  // --- Widget builders ---
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
          // milestone confetti at top
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

                    // PROGRESS BAR + MILESTONE MESSAGE
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                              )),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Name
                    _buildTextField(
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
                    _buildTextField(
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

                    // Password + Strength meter
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      onChanged: (s) {
                        // update UI for strength and progress
                        setState(() {});
                        _updateProgress();
                      },
                      decoration: InputDecoration(
                        labelText: 'Secret Password',
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        suffixIcon: IconButton(
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
                    // Strength meter row
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: pwdStrength,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_strengthColor(
                              pwdStrength,
                            )),
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

                    // Avatar selection
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
                              backgroundColor:
                                  selected ? Colors.deepPurple[50] : Colors.white,
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

                    // Submit button + loading
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isLoading ? 60 : double.infinity,
                      height: 60,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                  Icon(Icons.rocket_launch, color: Colors.white),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    // Small hint about badge criteria
                    Text(
                      'Badges: Complete profile + strong password + sign up before 12 PM.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => _updateProgress(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
}
