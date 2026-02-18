import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // 🔴 ABHI TEST IDS USE KARO
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String appOpenAdUnitId =
      'ca-app-pub-3940256099942544/3419835294';

  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;

  // ================= APP OPEN AD =================
  static void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAd!.show();
        },
        onAdFailedToLoad: (error) {
          // silently fail
        },
      ),
    );
  }

  // ================= INTERSTITIAL =================
  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  static void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      loadInterstitial(); // preload next
    }
  }
}
