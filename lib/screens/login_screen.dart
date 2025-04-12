import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideUpAnimation;

  @override
  void initState() {
    super.initState();

    // Controller for bottom panel slide animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Slide up from Offset(0, 1) to Offset(0, 0)
    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPanelHeight = MediaQuery.of(context).size.height * 0.38;

    return Scaffold(
      body: Stack(
        children: [
          // Main white background with centered logo
          Container(
            color: Color(0xFF83C5FF),
            alignment: Alignment.lerp(Alignment.topCenter, Alignment.center, 0.7), // Adjust the alignment from top center to center, and with how many percentage of range
            child: Image.asset(
              'assets/image/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),

          // Fixed Bottom Panel with Slide-In Animation
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideUpAnimation,
              child: Container(
                height: bottomPanelHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Gotham',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Google Sign-In button using sign_in_button's built-in logo and a custom pill shape
                    SizedBox(
                      width: screenWidth - 50, // Adjust width as needed
                      child: SignInButton(
                        Buttons.google,
                        text: "Sign in with Google",
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        onPressed: () {
                          // TODO: Handle Google sign-in
                        },
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Apple Sign-In button using built-in logo and custom pill shape
                    SizedBox(
                      width: screenWidth - 50,
                      child: SignInButton(
                        Buttons.apple,
                        text: "Sign in with Apple",
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        onPressed: () {
                          // TODO: Handle Apple sign-in
                        },
                      ),
                    ),
                    const SizedBox(height: 15),

                    // "Contact us" link
                    InkWell(
                      onTap: () {
                        // TODO: Handle contact us action
                      },
                      child: const Text(
                        'Contact us',
                        style: TextStyle(color: Colors.white70, fontFamily: 'Gotham'),
                      ),
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
}
