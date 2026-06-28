import 'package:flutter/material.dart';
import '../widgets/global_overlay.dart';
import 'main_shell.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Subtle scale animation for the logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _scaleController.forward();

    _initializeAppLifecycle();
  }

  Future<void> _initializeAppLifecycle() async {
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GlobalOverlay(child: MainShell()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container with gradient shadow
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1F1F1F), Color(0xFF111111)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF111111).withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF111111).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎙️', style: TextStyle(fontSize: 44)),
                ),
                const SizedBox(height: 28),

                // App name
                const Text(
                  'Voice Notepad',
                  style: TextStyle(
                    fontFamily: 'Bricolage',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your thoughts, spoken and captured.',
                  style: TextStyle(
                    fontFamily: 'Bricolage',
                    fontSize: 15,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      color: const Color(0xFF111111),
                      backgroundColor: Colors.grey.shade100,
                      minHeight: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
