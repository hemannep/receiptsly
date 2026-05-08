import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sudokugame/Ads/ad_unit_ids.dart' show AdUnitIds;

class InterstitialAdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;

  /// Load interstitial ad
  static Future<void> loadInterstitialAd() async {
    if (_isLoading || _interstitialAd != null) {
      return; // Already loading or ad is available
    }

    _isLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitialAdId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoading = false;
            debugPrint('Interstitial ad loaded');
          },
          onAdFailedToLoad: (err) {
            debugPrint('Failed to load interstitial ad: ${err.message}');
            _isLoading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isLoading = false;
    }
  }

  /// Show interstitial ad
  static Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      try {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            debugPrint('Interstitial ad showed full screen content');
          },
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('Interstitial ad dismissed');
            ad.dispose();
            _interstitialAd = null;
            // Load next ad
            loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, err) {
            debugPrint('Failed to show interstitial ad: ${err.message}');
            ad.dispose();
            _interstitialAd = null;
            loadInterstitialAd();
          },
        );

        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('Error showing interstitial ad: $e');
        _interstitialAd?.dispose();
        _interstitialAd = null;
      }
    } else {
      debugPrint('Interstitial ad not ready yet');
      loadInterstitialAd();
    }
  }

  /// Dispose ad if needed
  static void disposeAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
