import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    Navigator.pushNamed(context, '/successLogin');
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final smallScreen = screenHeight < 700;

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
                  SizedBox(height: smallScreen ? 8 : 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 34,
                        color: Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 6 : 10),
                  Image.asset(
                    'assets/loginLogo.png',
                    width: screenWidth * 0.42,
                    height: screenHeight * 0.14,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: smallScreen ? 10 : 18),
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: smallScreen ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B2B2B),
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(height: smallScreen ? 24 : 34),
                  _buildTextField(
                    controller: userNameController,
                    hintText: 'User Name',
                    prefixSpace: true,
                    suffixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.black87,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: smallScreen ? 16 : 20),
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixSpace: true,
                    suffixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.black87,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: smallScreen ? 16 : 20),
                  _buildTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: obscurePassword,
                    prefixSpace: true,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 16 : 20),
                  _buildTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: obscureConfirmPassword,
                    prefixSpace: true,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 14 : 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            agreeTerms = !agreeTerms;
                          });
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: const Color(0xFFC62828),
                              width: 2,
                            ),
                          ),
                          child: agreeTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Color(0xFFC62828),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Agree With ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2B2B2B),
                                fontFamily: 'serif',
                              ),
                            ),
                            Text(
                              'Terms & Condition',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF3B50E0),
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 20 : 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleSignUp,
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
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 20 : 28),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialCircleButton(
                        onTap: () {},
                        imagePath: 'assets/google.png',
                        fallbackIcon: Icons.g_mobiledata,
                      ),
                      const SizedBox(width: 28),
                      _socialCircleButton(
                        onTap: () {},
                        imagePath: 'assets/facebook.png',
                        fallbackIcon: Icons.facebook,
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 10 : 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool prefixSpace = false,
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
            color: Colors.grey.shade500,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(
            horizontal: prefixSpace ? 20 : 14,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _socialCircleButton({
    required VoidCallback onTap,
    required String imagePath,
    required IconData fallbackIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        child: Image.asset(
          imagePath,
          width: 42,
          height: 42,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFFEAF6FA),
              child: Icon(
                fallbackIcon,
                size: fallbackIcon == Icons.g_mobiledata ? 36 : 28,
                color: fallbackIcon == Icons.facebook
                    ? const Color(0xFF4267B2)
                    : Colors.black87,
              ),
            );
          },
        ),
      ),
    );
  }
}
