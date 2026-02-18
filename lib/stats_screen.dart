import 'package:flutter/material.dart';
import 'services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool loading = true;
  Map<String, dynamic> stats = {};
  String error = "";

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final s = await ApiService.getUserStats();
      if (!mounted) return;
      setState(() {
        stats = s;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Failed to load stats";
        loading = false;
      });
    }
  }

  //  HELPERS (LOGIC FIX)
  bool get isUnlimited =>
      (stats["tier"] ?? "").toString().toLowerCase() != "free";

  int get remaining => stats["daily_generations_remaining"] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ANALYTICS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 3,
            color: Colors.white24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  ///  CENTRAL PROGRESS RING
                  _buildQuotaCircle(),

                  const SizedBox(height: 50),

                  ///  STAT STRIPES
                  _buildStatStripe(
                    label: "Total Generations",
                    value: isUnlimited ? "∞" : "5",
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFFC0D9),
                  ),
                  const SizedBox(height: 14),
                  _buildStatStripe(
                    label: "Plan Type",
                    value: (stats["tier"] ?? "Free").toString().toUpperCase(),
                    icon: Icons.layers_outlined,
                    color: const Color(0xFFFDF0A0),
                  ),
                  const SizedBox(height: 14),
                  _buildStatStripe(
                    label: "Account Status",
                    value: "ACTIVE",
                    icon: Icons.shield_moon_outlined,
                    color: const Color(0xFFB4F8C8),
                  ),

                  const SizedBox(height: 30),

                  ///  RESET INFO
                  Text(
                    isUnlimited
                        ? "You are on an unlimited plan.\nNo daily limits apply."
                        : "Your daily limit resets automatically\nevery 24 hours at midnight.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ================= QUOTA CIRCLE =================

  Widget _buildQuotaCircle() {
    final double progress = isUnlimited
        ? 1.0
        : (remaining / 20).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        /// Glow
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E54E9).withOpacity(0.1),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
        ),

        /// Progress Ring
        SizedBox(
          width: 210,
          height: 210,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.03),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E54E9)),
            strokeCap: StrokeCap.round,
          ),
        ),

        /// Text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isUnlimited ? "∞" : "$remaining",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 68,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnlimited ? "UNLIMITED" : "GENERATION LEFT",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  

  Widget _buildStatStripe({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
