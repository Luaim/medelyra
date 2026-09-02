import 'package:flutter/material.dart';

class SuccessLoginPage extends StatefulWidget {
  const SuccessLoginPage({super.key});

  @override
  State<SuccessLoginPage> createState() => _SuccessLoginPageState();
}

class _SuccessLoginPageState extends State<SuccessLoginPage>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  double opacity = 0;

  @override
  void initState() {
    super.initState();

    /// Smooth fade-in
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        opacity = 1;
      });
    });
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
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: opacity,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.07,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    SizedBox(height: smallScreen ? 20 : 30),

                    /// IMAGE (slightly lifted)
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Image.asset(
                        'assets/wellcome.png',
                        width: screenWidth * 0.52,
                        height: screenHeight * 0.30,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: smallScreen ? 18 : 28),

                    /// TITLE
                    Text(
                      'Welcome to Medelyra!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: smallScreen ? 20 : 24,
                        fontWeight: FontWeight.w600, // slightly stronger
                        color: const Color(0xFFB35A5A),
                        fontFamily: 'serif',
                      ),
                    ),

                    SizedBox(height: smallScreen ? 8 : 12),

                    /// SUBTITLE
                    Text(
                      'Your account has been created\nsuccessfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: smallScreen ? 15.5 : 17,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF444444),
                        fontFamily: 'serif',
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: smallScreen ? 70 : 100),

                    /// BUTTON WITH PRESS EFFECT
                    GestureDetector(
                      onTapDown: (_) => setState(() => isPressed = true),
                      onTapUp: (_) => setState(() => isPressed = false),
                      onTapCancel: () => setState(() => isPressed = false),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 120),
                        scale: isPressed ? 0.97 : 1,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D84A8),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'serif',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: smallScreen ? 14 : 18),

                    /// FOOTER TEXT
                    Text(
                      'Explore, Manage, Stay Healthy!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: smallScreen ? 17 : 19,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB35A5A),
                        fontFamily: 'serif',
                      ),
                    ),

                    SizedBox(height: smallScreen ? 10 : 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
