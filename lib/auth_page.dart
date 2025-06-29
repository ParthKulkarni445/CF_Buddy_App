import 'package:acex/forget_password_page.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:acex/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _handleController = TextEditingController();
  final _verificationCodeController = TextEditingController(); // New controller for verification code
  bool _isLoading = false;
  bool _isVerifying = false; // Track verification state
  bool _codeSent = false; // Track if verification code has been sent
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Error states
  String? _emailError;
  String? _handleError;
  String? _verificationCodeError; // New error state for verification code

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _handleController.dispose();
    _verificationCodeController.dispose(); // Dispose new controller
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() async {
    await _animationController.forward();
    setState(() {
      isLogin = !isLogin;
      _emailController.clear();
      _handleController.clear();
      _verificationCodeController.clear(); // Clear verification code
      _codeSent = false; // Reset code sent status
      // Clear errors
      _emailError = null;
      _handleError = null;
      _verificationCodeError = null;
    });
    await _animationController.reverse();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      // Reset errors
      _emailError = null;
      _handleError = null;
      _verificationCodeError = null;

      // Validate email if signing up
      if (!isLogin) {
        if (_emailController.text.isEmpty) {
          _emailError = 'Please enter your email';
          isValid = false;
        } else if (!_emailController.text.contains('@')) {
          _emailError = 'Please enter a valid email';
          isValid = false;
        }
        
        // Validate verification code if signing up and code has been sent
        if (_codeSent && _verificationCodeController.text.isEmpty) {
          _verificationCodeError = 'Please enter verification code';
          isValid = false;
        }
      }

      // Validate handle
      if (_handleController.text.isEmpty) {
        _handleError = 'Please enter your handle';
        isValid = false;
      }
    });
    return isValid;
  }

  void loginUser() {
    if (!_validateInputs()) return;
    setState(() {
      _isLoading = true;
    });
    print("Login");
    _authService.signInUser(
      context: context,
      handle: _handleController.text.trim(),
      onSuccess: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  // New method to send verification code
  void sendVerificationCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }
    
    setState(() {
      _isVerifying = true;
    });
    
    bool success = await _authService.sendVerificationCode(
      email: _emailController.text,
      context: context,
    );
    
    setState(() {
      _isVerifying = false;
      _codeSent = success;
    });
  }

  Future<bool> validateAuthCode() async {
  setState(() {
    _isVerifying = true;
    _verificationCodeError = null;
  });
  final res = await _authService.validateAuthCode(
    email: _emailController.text,
    code: _verificationCodeController.text,
    context: context,
  );
  setState(() {
    _isVerifying = false;
  });
  if (!res) {
    setState(() {
      _verificationCodeError = 'Invalid or expired verification code';
    });
  }
  return res;
}

  Future<void> signUpUser() async {
    if (!_validateInputs()) return;
    
    // Check if verification code has been sent
    if (!_codeSent) {
      sendVerificationCode();
      return;
    }

    if (!await validateAuthCode()) return;
    
    setState(() {
      _isLoading = true;
    });
    print("Sign Up");
    
    // Here you would typically verify the code first, but since there's no
    // verification method in the provided code, we'll just proceed with signup
    // In a real implementation, you would verify the code before creating the account
    
    _authService.signUpUser(
      context: context,
      email: _emailController.text.trim(),
      handle: _handleController.text.trim(),
      onSuccess: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Logo section
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/namelogo2.png',
                height: 150,
              ),
            ),
            
            // Bottom sheet style auth container
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSheetAuth(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetAuth() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom sheet handle indicator
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          
          // Auth content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isLogin ? 'Welcome Back!' : 'Create your account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isLogin) ...[
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 16),
                      
                      // Verification code field (only shown when in signup mode and after code is sent)
                      if (_codeSent) ...[
                        _buildTextField(
                          controller: _verificationCodeController,
                          label: 'Verification Code',
                          icon: Icons.lock_outline,
                          errorText: _verificationCodeError,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    _buildTextField(
                      controller: _handleController,
                      label: 'Codeforces Handle',
                      icon: Icons.person_outline,
                      errorText: _handleError,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLogin ? loginUser : signUpUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7ED957),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading || _isVerifying
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isLogin 
                                  ? 'Sign In' 
                                  : (_codeSent ? 'Create Account' : 'Send Verification Code'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _toggleAuthMode,
                          style: TextButton.styleFrom(
                            overlayColor: Colors.grey.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                          ),
                          child: Text(
                            isLogin ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              color: Color(0xFF7ED957),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.white.withOpacity(0.5),
          selectionHandleColor: Colors.white,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? Colors.red[400]!.withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(
                color: Colors.white,
                decoration: TextDecoration.none,
                decorationThickness: 0,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(
                  icon,
                  color: errorText != null
                      ? Colors.red[400]
                      : Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                errorText,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}