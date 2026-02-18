import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tipsy_text/loginpage.dart';
import 'package:tipsy_text/homepage.dart';

//  ADD THIS IMPORT
import 'package:tipsy_text/services/ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    //  LOAD ADS ON APP OPEN
    AdService.loadAppOpenAd();
    AdService.loadInterstitial();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    Timer(const Duration(seconds: 4), () async {
      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: "jwt");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              jwt == null ? const Loginpage() : const HomePage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- CENTERED GLOW ---
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E54E9).withOpacity(0.15),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            // --- MAIN CONTENT ---
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// 🔥 AI ANIMATION
                  ScaleTransition(
                    scale: _fadeAnimation,
                    child: Lottie.asset(
                      'assets/ai.json',
                      width: MediaQuery.of(context).size.width * 0.8,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 📝 BRANDING
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "TIPSY TEXT",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Love starts with a spark ✨",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  ///  LOADER
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      alignment: Alignment.center,
                      width: 50,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFC0D9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
