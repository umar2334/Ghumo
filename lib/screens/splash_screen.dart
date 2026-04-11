import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)));

    _scale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.elasticOut)));

    _btnFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.55, 1, curve: Curves.easeOut)));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Radial gradient with dark-slate tones
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.3,
                colors: [AppColors.darkSlate, AppColors.background],
              ),
            ),
          ),

          // Subtle grid overlay
          CustomPaint(painter: _GridPainter(), size: Size.infinite),

          // Logo & title
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => FadeTransition(
                opacity: _fade,
                child: ScaleTransition(scale: _scale, child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo box
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.darkSlate,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.terrain_rounded,
                            color: AppColors.primary, size: 46),
                        Positioned(
                          bottom: 14,
                          right: 14,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.darkSlate, width: 2),
                            ),
                            child: const Icon(Icons.explore_rounded,
                                color: Colors.black, size: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'GHUMO',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Explore the Unexplored',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) =>
                  FadeTransition(opacity: _btnFade, child: child),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _navigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Let's Explore",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, fontSize: 17)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MADE IN PAKISTAN  🇵🇰',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
