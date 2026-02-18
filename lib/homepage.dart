import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:tipsy_text/flirt_generator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'services/api_service.dart';
import 'services/ad_service.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'saved_messages_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  int remaining = 0;
  String tier = "Free";

  // detect unlimited plans
  bool isUnlimited = false;

  // ================= ADS =================
  late BannerAd _bannerAd;
  bool _isBannerLoaded = false;
  // ======================================

  @override
  void initState() {
    super.initState();
    loadHomeData();

    // Load Banner Ad
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Future<void> loadHomeData() async {
    try {
      final stats = await ApiService.getUserStats();
      if (!mounted) return;

      setState(() {
        remaining = stats["daily_generations_remaining"] ?? 0;
        tier = stats["tier"] ?? "Free";
        isUnlimited = tier.toLowerCase() != "free";
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: Column(
                children: [
                  _buildStatusHeader(),

                  // ================= RESPONSIVE CENTER =================
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double orbSize = constraints.maxWidth < 360
                            ? constraints.maxWidth * 0.82
                            : constraints.maxWidth * 0.90;

                        return Center(child: _buildMassiveOrb(orbSize));
                      },
                    ),
                  ),

                  // Banner below Generate
                  if (_isBannerLoaded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: _bannerAd.size.width.toDouble(),
                      height: _bannerAd.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd),
                    ),

                
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildActionGrid(),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        "TIPSY TEXT",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.only(right: 20),
          icon: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.05),
            radius: 20,
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 22,
            ),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$tier Plan".toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlimited
                      ? "Unlimited Generations"
                      : "$remaining Generations Left",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlimited || remaining > 0
                    ? const Color(0xFFB4F8C8)
                    : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMassiveOrb(double size) {
    bool isLimitReached = !isUnlimited && remaining <= 0;

    return GestureDetector(
      onTap: () async {
        if (isLimitReached) {
          HapticFeedback.vibrate();
          return;
        }

        final bool? didGenerate = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FlirtGeneratorScreen(canGenerate: isUnlimited || remaining > 0),
          ),
        );

        if (didGenerate == true) {
          AdService.showInterstitial(); // generation ke baad ad
          loadHomeData();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Opacity(
              opacity: isLimitReached ? 0.2 : 1.0,
              child: Lottie.asset("assets/generate.json", fit: BoxFit.contain),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLimitReached ? "LIMIT" : "GENERATE",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLimitReached ? "DAILY CAP REACHED" : "FLIRTY MESSAGES",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 380;

        return SizedBox(
          height: isSmall ? 170 : 190,
          child: Row(
            children: [
              Expanded(
                child: _gridItem(
                  label: "RECENT\nHISTORY",
                  icon: Icons.history_rounded,
                  color: const Color(0xFFFDF0A0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _gridItem(
                        label: "SAVED",
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFFFC0D9),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedMessagesScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _gridItem(
                        label: "STATS",
                        icon: Icons.auto_graph_rounded,
                        color: const Color(0xFFB4F8C8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gridItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.black, size: 28),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.black26,
                  size: 18,
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
