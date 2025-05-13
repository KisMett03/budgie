import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/routes.dart';
import '../widgets/auth_button.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _panelAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // start off‐screen below
      end: Offset.zero, // slide into place
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Column(
        children: [
          // Top half with the hero logo
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'logo',
                    child: ClipRRect(
                      child: Container(
                        width: size.width * 0.3,
                        height: size.width * 0.37,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/budgie_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom half—the login panel—slides up on entry
          SizedBox(
            height: size.height * 0.5,
            child: SlideTransition(
              position: _panelAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBFCF8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Apple Sign-in
                    AuthButton(
                      label: 'Sign in with Apple',
                      leadingIcon: Image.asset(
                        'assets/icons/apple_logo.png',
                        width: 24,
                        height: 24,
                      ),
                      backgroundColor: Colors.black,
                      onPressed: () {
                        // TODO: implement Apple auth
                      },
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-in
                    AuthButton(
                      label: 'Sign in with Google',
                      leadingIcon: Image.asset(
                        'assets/icons/google_logo.png',
                        width: 24,
                        height: 24,
                      ),
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      onPressed: () async {
                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Simple approach - just call Google sign-in
                          await viewModel.signInWithGoogle();

                          // Close the loading dialog
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          // Check authentication state
                          if (viewModel.isAuthenticated) {
                            debugPrint(
                                'Login success, navigating to home screen');
                            if (mounted) {
                              Navigator.of(context)
                                  .pushReplacementNamed(Routes.home);
                            }
                          } else {
                            // Failed to authenticate
                            final errorMessage = viewModel.error ??
                                'Login failed: Unable to authenticate';
                            debugPrint('Login failed: $errorMessage');

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                  action: SnackBarAction(
                                    label: 'Retry',
                                    textColor: Colors.white,
                                    onPressed: () =>
                                        _retrySignIn(context, viewModel),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Close the loading dialog
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          final errorMsg = e.toString();
                          debugPrint('Login exception: $errorMsg');

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Login failed: ${_formatErrorMessage(errorMsg)}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Retry',
                                  textColor: Colors.white,
                                  onPressed: () =>
                                      _retrySignIn(context, viewModel),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const Spacer(),

                    TextButton(
                      onPressed: () {
                        // TODO: contact us action
                      },
                      child: const Text(
                        'Contact us',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
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

  // Simple retry method
  void _retrySignIn(BuildContext context, AuthViewModel viewModel) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Try sign-in again
      await viewModel.signInWithGoogle();

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate if successful
      if (viewModel.isAuthenticated && mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      } else if (mounted) {
        final error = viewModel.error ?? 'Authentication failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Authentication failed: ${_formatErrorMessage(e.toString())}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper to format error messages
  String _formatErrorMessage(String error) {
    if (error.contains('network')) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (error.contains('cancel')) {
      return 'Sign-in was cancelled';
    } else if (error.contains('credential')) {
      return 'Authentication failed';
    } else if (error.length > 100) {
      return '${error.substring(0, 100)}...';
    }
    return error;
  }
}
