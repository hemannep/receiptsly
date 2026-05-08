import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sudokugame/Ads/ad_unit_ids.dart';

class BannerAdWidget extends StatefulWidget {
  final bool showAd;

  const BannerAdWidget({super.key, this.showAd = true});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAd) {
      _loadBannerAd();
    }
  }

  @override
  void didUpdateWidget(BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Load when toggled on; dispose when toggled off
    if (widget.showAd && !oldWidget.showAd) {
      _loadBannerAd();
    } else if (!widget.showAd && oldWidget.showAd) {
      _disposeAd();
    }
  }

  void _loadBannerAd() {
    if (_isDisposed) return;
    // Don't reload if already loaded or loading
    if (_bannerAd != null) return;

    final ad = BannerAd(
      adUnitId: AdUnitIds.bannerAdId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (_isDisposed) {
            loadedAd.dispose();
            return;
          }
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (failedAd, err) {
          debugPrint('Failed to load banner ad: ${err.message}');
          failedAd.dispose();
          if (mounted && !_isDisposed) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() => _isLoaded = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAd || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
