import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'homepage.dart';
import 'services/api_service.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        "1029735515530-f525v2ddmjp4o56473tdt7ia4m44vcje.apps.googleusercontent.com",
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      await _googleSignIn.signOut();
      await _storage.deleteAll();

      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication auth = await user.authentication;

     
      debugPrint("AccessToken: ${auth.accessToken}");
      debugPrint("IdToken: ${auth.idToken}");

      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception("Google ID token is null");
      }

      debugPrint("Google ID Token received successfully");

      final response = await ApiService.loginWithGoogle(idToken);

      final String jwt = response["token"];

      //  Save JWT
      await _storage.write(key: "jwt", value: jwt);

      //  Save user email for per-user storage
      await _storage.write(key: "user_email", value: user.email);

      debugPrint(" User email saved: ${user.email}");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //  APP NAME TEXT (NO LOGO)
              const Text(
                "Tipsy Text",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Sign in to continue",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 50),

              //  GOOGLE SIGN IN BUTTON
              GestureDetector(
                onTap: _isLoading ? null : _handleGoogleSignIn,
                child: AnimatedOpacity(
                  opacity: _isLoading ? 0.7 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/google.png", height: 24),
                        const SizedBox(width: 14),
                        Text(
                          _isLoading ? "Signing in..." : "Continue with Google",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "By continuing, you agree to our Terms & Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
