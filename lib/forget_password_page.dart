// import 'package:acex/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:acex/services.dart';

// class ForgotPasswordPage extends StatefulWidget {
//   const ForgotPasswordPage({super.key});

//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }

// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _codeController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   final AuthService _authService = AuthService();

//   static final RegExp _emailRegExp = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");

//   String? _emailError;
//   String? _codeError;
//   String? _passwordError;
//   String? _confirmPasswordError;
//   bool _isCodeSent = false;
//   bool _isLoading = false;

//   Future<void> _sendCode() async {
//     setState(() {
//       _emailError = null;
//       _isLoading = true;
//     });

//     final email = _emailController.text.trim();
//     if (email.isEmpty) {
//       setState(() {
//         _emailError = 'Please enter your email';
//         _isLoading = false;
//       });
//       return;
//     } else if (!_emailRegExp.hasMatch(email)) {
//       setState(() {
//         _emailError = 'Please enter a valid email';
//         _isLoading = false;
//       });
//       return;
//     }

//     try {
//       final bool sent = await _authService.sendVerificationCode(
//         email: email,
//         context: context,
//       );
//       if (sent) {
//         setState(() {
//           _isCodeSent = true;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _emailError = 'Failed to send verification code';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _emailError = e is String ? e : 'Error sending code';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _resetPassword() async {
//     setState(() {
//       _codeError = null;
//       _passwordError = null;
//       _confirmPasswordError = null;
//       _isLoading = true;
//     });

//     final code = _codeController.text.trim();
//     final newPass = _passwordController.text;
//     final confirmPass = _confirmPasswordController.text;
//     final email = _emailController.text.trim();

//     if (code.isEmpty) {
//       setState(() {
//         _codeError = 'Please enter the verification code';
//         _isLoading = false;
//       });
//       return;
//     }

//     if (newPass.isEmpty) {
//       setState(() {
//         _passwordError = 'Please enter a new password';
//         _isLoading = false;
//       });
//       return;
//     } else if (newPass.length < 6) {
//       setState(() {
//         _passwordError = 'Password must be at least 6 characters';
//         _isLoading = false;
//       });
//       return;
//     }

//     if (confirmPass.isEmpty) {
//       setState(() {
//         _confirmPasswordError = 'Please confirm your password';
//         _isLoading = false;
//       });
//       return;
//     } else if (newPass != confirmPass) {
//       setState(() {
//         _confirmPasswordError = 'Passwords do not match';
//         _isLoading = false;
//       });
//       return;
//     }

//     try {
//       final bool reset = await _authService.resetPassword(
//         email: email,
//         verificationCode: code,
//         newPassword: newPass,
//         context: context,
//       );
//       if (reset) {
//         setState(() {
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _codeError = 'Failed to reset password';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _codeError = e is String ? e : 'Reset failed';
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         title: const Text('Forgot Password', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 24),
//                 _buildTextField(
//                   controller: _emailController,
//                   label: 'Email',
//                   icon: Icons.email_outlined,
//                   errorText: _emailError,
//                 ),
//                 if (_isCodeSent) ...[
//                   const SizedBox(height: 24),
//                   _buildTextField(
//                     controller: _codeController,
//                     label: 'Verification Code',
//                     icon: Icons.lock_outline,
//                     errorText: _codeError,
//                   ),
//                   const SizedBox(height: 24),
//                   _buildTextField(
//                     controller: _passwordController,
//                     label: 'New Password',
//                     icon: Icons.lock_reset,
//                     errorText: _passwordError,
//                     obscureText: true,
//                   ),
//                   const SizedBox(height: 24),
//                   _buildTextField(
//                     controller: _confirmPasswordController,
//                     label: 'Confirm Password',
//                     icon: Icons.lock_reset,
//                     errorText: _confirmPasswordError,
//                     obscureText: true,
//                   ),
//                 ],
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: _isLoading
//                         ? null
//                         : (_isCodeSent ? _resetPassword : _sendCode),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF7ED957),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         if (!_isLoading)
//                           Text(
//                             _isCodeSent ? 'Reset' : 'Verify',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         if (_isLoading)
//                           const SizedBox(
//                             height: 24,
//                             width: 24,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     String? errorText,
//     bool obscureText = false,
//   }) {
//     return Theme(
//       data: Theme.of(context).copyWith(
//         textSelectionTheme: TextSelectionThemeData(
//           cursorColor: Colors.white,
//           selectionColor: Colors.white.withOpacity(0.5),
//           selectionHandleColor: Colors.white,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: errorText != null
//                     ? Colors.red[400]!.withOpacity(0.5)
//                     : Colors.white.withOpacity(0.7),
//                 width: 1,
//               ),
//             ),
//             child: TextField(
//               controller: controller,
//               obscureText: obscureText,
//               style: const TextStyle(
//                 color: Colors.white,
//                 decoration: TextDecoration.none,
//                 decorationThickness: 0,
//               ),
//               decoration: InputDecoration(
//                 hintText: label,
//                 hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//                 prefixIcon: Icon(
//                   icon,
//                   color: errorText != null
//                       ? Colors.red[400]
//                       : Colors.white.withOpacity(0.7),
//                   size: 20,
//                 ),
//                 border: InputBorder.none,
//                 focusedBorder: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 16,
//                 ),
//               ),
//             ),
//           ),
//           if (errorText != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 16, top: 8),
//               child: Text(
//                 errorText,
//                 style: TextStyle(
//                   color: Colors.red[400],
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }