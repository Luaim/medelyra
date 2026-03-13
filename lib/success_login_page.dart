import 'package:flutter/material.dart';

class SuccessLoginPage extends StatelessWidget {
  const SuccessLoginPage({super.key});

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
                children: [
                  SizedBox(height: smallScreen ? 25 : 40),
                  Image.asset(
                    'assets/wellcome.png',
                    width: screenWidth * 0.5,
                    height: screenHeight * 0.32,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: smallScreen ? 24 : 34),
                  Text(
                    'Welcome to MedMinder!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: smallScreen ? 20 : 24,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB35A5A),
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(height: smallScreen ? 10 : 14),
                  Text(
                    'Your account has been created\nsuccessfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: smallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                      fontFamily: 'serif',
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: smallScreen ? 80 : 120),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                        'Continue',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 14 : 18),
                  Text(
                    'Explore, Manage, Stay Healthy!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: smallScreen ? 18 : 20,
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
    );
  }
}
