import 'dart:async';
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
  bool _isAdReady = false;
  int? _timeUntilReset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAdStats();
    _preloadAd();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdStats() async {
    final stats = await AdMobService.getDailyAdStats();
    setState(() {
      _remainingAds = stats['remainingAds'] as int;
      _canWatchAd = stats['canWatchAd'] as bool;
      _isAdReady = stats['isAdReady'] as bool;
      _timeUntilReset = stats['timeUntilReset'] as int?;
    });
  }

  Future<void> _preloadAd() async {
    await AdMobService.preloadAds();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadAdStats();
    });
  }

  Future<void> _watchAd() async {
    if (!_canWatchAd) {
      _showAdUnavailableMessage();
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

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 You earned ${tokens} tokens!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Callback
          widget.onAdWatched?.call();

          // Refresh stats
          await _loadAdStats();
        },
        onAdFailed: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );

      if (!success && mounted) {
        // Ad was not completed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad was not completed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Failed to show ad
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading ad. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAdUnavailableMessage() {
    String message;
    if (_remainingAds <= 0) {
      if (_timeUntilReset != null && _timeUntilReset! > 0) {
        final hours = _timeUntilReset! ~/ 60;
        final minutes = _timeUntilReset! % 60;
        message = 'Daily ad limit reached. Try again in ${hours}h ${minutes}m.';
      } else {
        message = 'Daily ad limit reached. Try again tomorrow.';
      }
    } else if (!_isAdReady) {
      message = 'Ad is not ready. Please try again later.';
    } else {
      message = 'You cannot watch ads right now.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getStatusText() {
    if (_remainingAds <= 0) {
      if (_timeUntilReset != null && _timeUntilReset! > 0) {
        final hours = _timeUntilReset! ~/ 60;
        final minutes = _timeUntilReset! % 60;
        return 'Daily limit reached • Resets in ${hours}h ${minutes}m';
      } else {
        return 'Daily limit reached • Try again tomorrow';
      }
    } else if (!_isAdReady) {
      return 'Ad not ready • Try again later';
    } else {
      return '0.5 tokens per ad • $_remainingAds ads remaining today';
    }
  }

  String _getButtonText() {
    if (_remainingAds <= 0) {
      return 'Daily Limit Reached';
    } else if (!_isAdReady) {
      return 'Ad Not Ready';
    } else {
      return 'Cannot Watch Ad';
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
                      _getStatusText(),
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
                    : _getButtonText(),
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
