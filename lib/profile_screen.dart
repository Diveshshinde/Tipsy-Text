import 'package:flutter/material.dart';
import 'package:tipsy_text/loginpage.dart';
import 'services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  Map<String, dynamic>? profile;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final data = await ApiService.getUserProfile();
      if (!mounted) return;
      setState(() {
        profile = data;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  ///  LOGOUT LOGIC
  Future<void> logout() async {
    await _storage.delete(key: "jwt");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // --- PROFILE HEADER ---
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFC0D9), Color(0xFFE2C4FF)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.black,
                            backgroundImage: profile?["picture"] != null
                                ? NetworkImage(profile!["picture"])
                                : null,
                            child: profile?["picture"] == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white24,
                                  )
                                : null,
                          ),
                        ),
                        if (profile?["emailVerified"] == true)
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.verified,
                              color: Color(0xFFB4F8C8),
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile?["name"] ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?["email"] ?? "",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- BENTO TILES ---
                  Row(
                    children: [
                      Expanded(
                        child: _bentoInfoTile(
                          icon: Icons.shield_moon_rounded,
                          label: "STATUS",
                          value: profile?["emailVerified"] == true
                              ? "Verified"
                              : "Basic",
                          color: const Color(0xFFB4F8C8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bentoInfoTile(
                          icon: Icons.fingerprint_rounded,
                          label: "ID TAG",
                          value:
                              "#${profile?["id"]?.toString().substring(0, 5).toUpperCase() ?? "000"}",
                          color: const Color(0xFFFDF0A0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- LOGOUT BUTTON ---
                  _settingsTile(
                    icon: Icons.logout_rounded,
                    title: "Log out",
                    onTap: logout,
                    isDestructive: false,
                  ),

                  const SizedBox(height: 40),
                  Text(
                    "TIPSY TEXT V1.0.4",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.15),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _bentoInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDestructive,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
