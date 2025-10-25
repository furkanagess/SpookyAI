import 'dart:io';
import 'package:flutter/material.dart';
import '../services/admob_service.dart';
import '../services/token_provider.dart';
import 'package:provider/provider.dart';

class RewardedAdWidget extends StatefulWidget {
  final VoidCallback? onAdWatched;
  final String? customMessage;

  const RewardedAdWidget({super.key, this.onAdWatched, this.customMessage});

  @override
  State<RewardedAdWidget> createState() => _RewardedAdWidgetState();
}

class _RewardedAdWidgetState extends State<RewardedAdWidget> {
  bool _isLoading = false;
  int _remainingAds = 0;
  bool _canWatchAd = false;

  @override
  void initState() {
    super.initState();
    _loadAdStats();
    _preloadAd();
  }

  Future<void> _loadAdStats() async {
    final stats = await AdMobService.getDailyAdStats();
    setState(() {
      _remainingAds = stats['remainingAds'] as int;
      _canWatchAd = _remainingAds > 0;
    });
  }

  Future<void> _preloadAd() async {
    await AdMobService.preloadAds();
  }

  Future<void> _watchAd() async {
    if (!_canWatchAd) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AdMobService.showRewardedAd(
        onRewardEarned: (tokens) async {
          // Add tokens to user's balance
          final tokenProvider = context.read<TokenProvider>();
          await tokenProvider.addTokens(tokens);

          // Token earned successfully

          // Callback
          widget.onAdWatched?.call();

          // Refresh stats
          await _loadAdStats();
        },
        onAdFailed: (error) {
          // Ad failed to show
        },
      );

      if (!success && mounted) {
        // Ad was not completed
      }
    } catch (e) {
      // Failed to show ad
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Watch Ad for Tokens',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Earn 0.5 tokens per ad • $_remainingAds ads left today ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom message or default
          if (widget.customMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                widget.customMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 12),

          // Watch Ad Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canWatchAd && !_isLoading ? _watchAd : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isLoading
                    ? 'Loading Ad...'
                    : _canWatchAd
                    ? 'Watch Ad & Earn 0.5 Tokens'
                    : 'Daily Limit Reached',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _canWatchAd && !_isLoading
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                foregroundColor: _canWatchAd && !_isLoading
                    ? const Color(0xFF9C27B0)
                    : Colors.white.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),

          // Progress indicator
          if (_remainingAds > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (5 - _remainingAds) / 5,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${5 - _remainingAds}/5',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
