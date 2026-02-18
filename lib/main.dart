import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tipsy_text/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  Initialize Google Mobile Ads
  await MobileAds.instance.initialize();

  runApp(const TipsyTextApp());
}

class TipsyTextApp extends StatelessWidget {
  const TipsyTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white, size: 26),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
