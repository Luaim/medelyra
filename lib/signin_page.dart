import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isPressed = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  children: [
                    /// 🔥 LOGO (BIGGER + HIGHER)
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Image.asset(
                        'assets/loginLogo.png',
                        width: w * 0.42,
                        height: h * 0.14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2B2B),
                        fontFamily: 'serif',
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// EMAIL
                    _buildLabel('Email'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Enter your Email',
                      prefixIcon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 16),

                    /// PASSWORD
                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: passwordController,
                      hintText: '••••••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// 🔧 FIXED FORGOT PASSWORD (NO BIG SPLASH)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// 🔥 SIGN IN BUTTON WITH PRESS EFFECT
                    GestureDetector(
                      onTapDown: (_) => setState(() => isPressed = true),
                      onTapUp: (_) => setState(() => isPressed = false),
                      onTapCancel: () => setState(() => isPressed = false),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: AnimatedScale(
                        scale: isPressed ? 0.97 : 1,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D84A8),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// DIVIDER
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "OR Continue with",
                            style: TextStyle(
                              color: Color.fromARGB(255, 116, 115, 115),
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// SOCIAL BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: _socialButton(
                            text: 'Google',
                            imagePath: 'assets/google.png',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _socialButton(
                            text: 'Facebook',
                            imagePath: 'assets/facebook.png',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// SIGN UP (PRESS EFFECT)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
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
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF2F7),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String text,
    required String imagePath,
  }) {
    bool pressed = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => pressed = true),
          onTapUp: (_) => setState(() => pressed = false),
          onTapCancel: () => setState(() => pressed = false),
          onTap: () {},
          child: AnimatedScale(
            scale: pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 100),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color.fromARGB(181, 169, 240, 250),
                border:
                    Border.all(color: const Color.fromARGB(170, 71, 71, 71)),
                borderRadius: BorderRadius.circular(26),
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
                  Image.asset(imagePath, width: 24),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
