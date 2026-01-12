import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widget/MainNavigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  Future<void> handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final success = await AuthService().registerWithEmail(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text,
    );

    setState(() => loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 0),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration failed'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green.shade100.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.green.shade200.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),

                              // App Logo/Icon
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade800.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadiusGeometry.circular(60),
                                  child: Image.asset(
                                    'assets/shoplogo.png',
                                    fit: BoxFit.fitHeight,
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Welcome Text
                              Text(
                                'Join',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey.shade700,
                                  letterSpacing: 1.2,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // App Name
                              Text(
                                'BMT 99',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  letterSpacing: 2.0,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Tagline
                              Text(
                                'Fresh Grocery Market',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.green.shade600,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Description Text
                              Text(
                                'Create an account to start shopping fresh groceries',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 40),

                              /// REGISTRATION FORM
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Name Field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade200,
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _nameController,
                                        validator: (v) =>
                                        v!.isEmpty ? 'Full name is required' : null,
                                        decoration: InputDecoration(
                                          hintText: 'Full Name',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                            color: Colors.green.shade600,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 16,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Phone Field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade200,
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        validator: (v) =>
                                        v!.length < 10 ? 'Enter valid phone number' : null,
                                        decoration: InputDecoration(
                                          hintText: 'Phone Number',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.phone_outlined,
                                            color: Colors.green.shade600,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 16,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Email Field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade200,
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (v) =>
                                        !v!.contains('@') ? 'Enter valid email' : null,
                                        decoration: InputDecoration(
                                          hintText: 'Email Address',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: Colors.green.shade600,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 16,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Password Field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade200,
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        validator: (v) =>
                                        v!.length < 6 ? 'Minimum 6 characters' : null,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          hintText: 'Password',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color: Colors.green.shade600,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.green.shade600,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 16,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Confirm Password Field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade200,
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        validator: (v) => v != _passwordController.text
                                            ? 'Passwords do not match'
                                            : null,
                                        obscureText: _obscureConfirmPassword,
                                        decoration: InputDecoration(
                                          hintText: 'Confirm Password',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color: Colors.green.shade600,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.green.shade600,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword = !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 16,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              /// REGISTER BUTTON
                              if (loading)
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.green.shade600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        'Creating Account...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: Colors.green.shade800.withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    minimumSize: const Size(double.infinity, 56),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 30),

                              // Additional Info
                              Text(
                                'By creating an account, you agree to our Terms of Service and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Bottom decorative element
                              Container(
                                width: 60,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}