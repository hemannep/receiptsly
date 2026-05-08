import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sudokugame/Ads/ad_unit_ids.dart' show AdUnitIds;

class RewardedAdHelper {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  /// Load rewarded ad
  static Future<void> loadRewardedAd() async {
    if (_isLoading || _rewardedAd != null) {
      return; // Already loading or ad is available
    }

    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: AdUnitIds.rewardedAdId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            debugPrint('Rewarded ad loaded');
          },
          onAdFailedToLoad: (err) {
            debugPrint('Failed to load rewarded ad: ${err.message}');
            _isLoading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _isLoading = false;
    }
  }

  /// Show rewarded ad
  static Future<bool> showRewardedAd({required Function onRewardEarned}) async {
    if (_rewardedAd != null) {
      try {
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            debugPrint('Rewarded ad showed full screen content');
          },
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('Rewarded ad dismissed');
            ad.dispose();
            _rewardedAd = null;
            // Load next ad
            loadRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, err) {
            debugPrint('Failed to show rewarded ad: ${err.message}');
            ad.dispose();
            _rewardedAd = null;
            loadRewardedAd();
          },
        );

        await _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            debugPrint('Reward earned: ${reward.amount} ${reward.type}');
            onRewardEarned();
          },
        );
        return true;
      } catch (e) {
        debugPrint('Error showing rewarded ad: $e');
        _rewardedAd?.dispose();
        _rewardedAd = null;
        return false;
      }
    } else {
      debugPrint('Rewarded ad not ready yet');
      return false;
    }
  }

  /// Check if ad is ready
  static bool isRewardedAdReady() {
    return _rewardedAd != null;
  }

  /// Dispose ad if needed
  static void disposeAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
