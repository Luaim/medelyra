import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final bool smallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.07,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: smallScreen ? 15 : 30),
                  Image.asset(
                    'assets/loginLogo.png',
                    width: screenWidth * 0.42,
                    height: screenHeight * 0.14,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: smallScreen ? 12 : 20),
                  Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: smallScreen ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B2B2B),
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(height: smallScreen ? 28 : 42),
                  _buildLabel('Email'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Enter your Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: smallScreen ? 18 : 22),
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: passwordController,
                    hintText: '••••••••••••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: forgot password page/action
                      },
                      child: const Text(
                        'Forget Password?',
                        style: TextStyle(
                          color: Color(0xFF9B1C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 26),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D84A8),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFD0D0D0),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR Continue with',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFD0D0D0),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 18 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: _socialButton(
                          onTap: () {
                            // TODO: Google sign in
                          },
                          imagePath: 'assets/google.png',
                          fallbackIcon: Icons.g_mobiledata,
                          text: 'Google',
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _socialButton(
                          onTap: () {
                            // TODO: Facebook sign in
                          },
                          imagePath: 'assets/facebook.png',
                          fallbackIcon: Icons.facebook,
                          text: 'Facebook',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 26 : 34),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        "Don’t have account? ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B2B2B),
                          fontFamily: 'serif',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9B1C1C),
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 10 : 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: Color(0xFF3A3A3A),
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF2F7),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6F6F6F),
          width: 0.8,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.black87,
            size: 24,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required VoidCallback onTap,
    required String imagePath,
    required IconData fallbackIcon,
    required String text,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFDDF2F7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  fallbackIcon,
                  size: 28,
                  color: fallbackIcon == Icons.facebook
                      ? const Color(0xFF4267B2)
                      : Colors.black87,
                );
              },
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
