import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/purchase_provider.dart';
import '../../../../core/services/in_app_purchase_service.dart';
import '../../../../core/utils/platform_utils.dart';
import '../widgets/purchase_success_dialog.dart';
import '../widgets/purchase_failed_dialog.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage();

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().initialize();
    });
  }

  Future<void> _buy(Pack pack, PurchaseProvider provider) async {
    if (provider.isLoading) return;

    try {
      debugPrint('PurchasePage: Starting purchase for ${pack.name}');
      final bool success = await provider.buyPack(pack);
      debugPrint('PurchasePage: Purchase result: $success');

      if (!mounted) return;

      if (success) {
        debugPrint('PurchasePage: Showing success dialog for ${pack.name}');
        if (pack.isPremium) {
          await showPurchaseSuccessDialog(
            context,
            tokensAdded: pack.tokens,
            isPremiumSubscription: true,
          );
        } else {
          // Refresh token provider for regular purchases
          final tokenProvider = context.read<TokenProvider>();
          await tokenProvider.refreshBalance();
          await showPurchaseSuccessDialog(context, tokensAdded: pack.tokens);
        }
      } else {
        debugPrint('PurchasePage: Purchase failed for ${pack.name}');

        // Check if this was a user cancellation (don't show error dialog)
        final isUserCancelled =
            InAppPurchaseService.queryProductError?.contains('cancelled') ??
            false;

        if (!isUserCancelled) {
          await PurchaseFailedDialog.show(
            context,
            reason: 'Purchase was not completed. Please try again.',
          );
        } else {
          debugPrint(
            'PurchasePage: User cancelled purchase - not showing error dialog',
          );
        }
      }
    } catch (e) {
      debugPrint('PurchasePage: Exception during purchase: $e');
      if (mounted) {
        String reason = 'An unexpected error occurred during purchase.';

        // Provide more specific error messages based on the error type
        if (e.toString().contains('network')) {
          reason =
              'Network connection failed. Please check your internet and try again.';
        } else if (e.toString().contains('payment')) {
          reason =
              'Payment processing failed. Please verify your payment method.';
        } else if (e.toString().contains('product')) {
          reason = 'Product not available. Please try again later.';
        } else if (e.toString().contains('user') ||
            e.toString().contains('cancelled')) {
          reason = 'Purchase was cancelled by user.';
        }

        await PurchaseFailedDialog.show(context, reason: reason);
      }
    }
  }

  Future<void> _restorePurchases(PurchaseProvider provider) async {
    try {
      await provider.restorePurchases();
      final tokenProvider = context.read<TokenProvider>();
      await tokenProvider.refreshBalance();

      if (mounted) {
        NotificationService.success(
          context,
          message: 'Purchases restored successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        String reason = 'Unable to restore purchases.';

        if (e.toString().contains('network')) {
          reason =
              'Network connection failed. Please check your internet and try again.';
        } else if (e.toString().contains('account')) {
          reason = 'Account verification failed. Please sign in again.';
        } else if (e.toString().contains('no_purchases')) {
          reason = 'No previous purchases found to restore.';
        }

        await PurchaseFailedDialog.show(context, reason: reason);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(children: [const Text('Packages')]),
            backgroundColor: const Color(0xFF0F0B1A),
            elevation: 0,
            actions: [
              // Restore Purchases Button (iOS only)
              if (PlatformUtils.isIOS)
                IconButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _restorePurchases(provider),
                  icon: const Icon(Icons.restore),
                  tooltip: 'Restore Purchases',
                ),
              // // Debug-only: Add test tokens quickly
              // if (kDebugMode)
              //   IconButton(
              //     onPressed: provider.isLoading
              //         ? null
              //         : () async {
              //             final tokenProvider = context.read<TokenProvider>();
              //             await tokenProvider.addTokens(5);
              //             if (mounted) {
              //               NotificationService.success(
              //                 context,
              //                 message: 'Added 5 test tokens',
              //               );
              //             }
              //           },
              //     icon: const Icon(Icons.add_circle_outline),
              //     tooltip: 'Add 5 test tokens',
              //   ),
              // Token Balance
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D162B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Consumer<TokenProvider>(
                    builder: (context, tokenProvider, child) {
                      return Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Color(0xFFFF6A00),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${tokenProvider.balance}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Loading Indicator
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6A00),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Processing...'),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ListView.builder(
                    itemCount: provider.packs.length + 1, // +1 for legal links
                    itemBuilder: (context, index) {
                      // If this is the last item, show legal links
                      if (index == provider.packs.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegalLink(
                                'Terms of Use',
                                'https://github.com/furkanagess/SpookyAI/blob/main/TERMS_OF_USE.md',
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(color: Color(0xFF8C7BA6)),
                              ),
                              _buildLegalLink(
                                'Privacy Policy',
                                'https://github.com/furkanagess/SpookyAI/blob/main/PRIVACY_POLICY.md',
                              ),
                            ],
                          ),
                        );
                      }

                      // Regular pack items
                      final pack = provider.packs[index];
                      final bool selected = provider.selectedIndex == index;

                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0
                              ? 8
                              : 0, // Reduced padding for first item (premium)
                          bottom: 16,
                        ),
                        child: GestureDetector(
                          onTap: !provider.canSelectPack(pack)
                              ? null
                              : () => provider.setSelectedIndex(index),
                          child: pack.isPremium
                              ? SizedBox(
                                  height: 280, // Fixed height for premium card
                                  child: _PremiumSubscriptionCard(
                                    pack: pack,
                                    selected: selected,
                                    isPremiumUser: provider.isPremium,
                                  ),
                                )
                              : _SelectablePackRow(
                                  pack: pack,
                                  isBestValue: false,
                                  selected: selected,
                                  provider: provider,
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    (provider.selectedIndex == null || provider.isLoading)
                    ? null
                    : () async {
                        final pack = provider.packs[provider.selectedIndex!];
                        await _buy(pack, provider);
                      },
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        provider.selectedIndex != null
                            ? 'Purchase ${provider.packs[provider.selectedIndex!].name}'
                            : 'Select a Pack',
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegalLink(String text, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFF6A00), fontSize: 12),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Legacy chip removed

String _pricePerToken(Pack p, PurchaseProvider provider) {
  // Get the real price from Google Play/App Store
  final String displayedPrice = p.realPrice;

  // Extract numeric value from the displayed price
  String numericPrice = displayedPrice;
  // Clean up currency symbols and text
  numericPrice = numericPrice.replaceAll(RegExp(r'[^\d.,]'), '').trim();

  // Parse the numeric value
  final double total = double.tryParse(numericPrice) ?? 0;

  if (p.tokens == 0 || total == 0) return '-';

  final double per = total / p.tokens;
  final String currency = PlatformUtils.isAndroid ? 'TRY' : 'USD';

  return '${per.toStringAsFixed(2)} $currency/token';
}

class _SelectablePackRow extends StatelessWidget {
  const _SelectablePackRow({
    required this.pack,
    required this.isBestValue,
    required this.selected,
    required this.provider,
  });

  final Pack pack;
  final bool isBestValue;
  final bool selected;
  final PurchaseProvider provider;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D162B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFF6A00)
                  : Colors.white.withOpacity(0.08),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x221D162B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ColorFiltered(
                    colorFilter: pack.whiteTint
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                    child: Image.asset(pack.imageAsset, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TokenBadge(tokens: pack.tokens),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                PlatformUtils.isIOS
                                    ? pack.realPrice
                                    : pack.realPrice,
                                style: const TextStyle(
                                  color: Color(0xFFFF6A00),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _pricePerToken(pack, provider),
                                style: const TextStyle(
                                  color: Color(0xFF8C7BA6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pack.note,
                        style: const TextStyle(color: Color(0xFF8C7BA6)),
                      ),
                      // Show premium features if it's a premium pack
                      if (pack.isPremium && pack.features.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Premium Benefits:',
                          style: const TextStyle(
                            color: Color(0xFFFF6A00),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...pack.features
                            .take(3)
                            .map(
                              (feature) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: const TextStyle(
                                          color: Color(0xFF8C7BA6),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (pack.features.length > 3)
                          Text(
                            '+${pack.features.length - 3} more benefits',
                            style: const TextStyle(
                              color: Color(0xFFFF6A00),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selection indicator (bottom right)
        if (selected)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),

        if (isBestValue)
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  pack.isPremium ? 'PREMIUM' : 'BEST VALUE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TokenBadge extends StatelessWidget {
  const _TokenBadge({required this.tokens});
  final int tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x22FF6A00),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.6)),
      ),
      child: Text(
        '$tokens Token',
        style: const TextStyle(
          color: Color(0xFFFF6A00),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// _PackCard deprecated; replaced by _SelectablePackRow list design

class _PremiumSubscriptionCard extends StatelessWidget {
  const _PremiumSubscriptionCard({
    required this.pack,
    required this.selected,
    required this.isPremiumUser,
  });

  final Pack pack;
  final bool selected;
  final bool isPremiumUser;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? (isPremiumUser
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6A00))
                  : (isPremiumUser
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : const Color(0xFFFF6A00).withOpacity(0.3)),
              width: selected ? 3 : 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          (isPremiumUser
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6A00))
                              .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color:
                          (isPremiumUser
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6A00))
                              .withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPremiumUser
                    ? [
                        const Color(0xFF4CAF50).withOpacity(0.1),
                        const Color(0xFF2E7D32).withOpacity(0.1),
                        const Color(0xFF1D162B),
                      ]
                    : [
                        const Color(0xFFFF6A00).withOpacity(0.1),
                        const Color(0xFF9C27B0).withOpacity(0.1),
                        const Color(0xFF1D162B),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with crown icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPremiumUser
                                ? [
                                    const Color(0xFF4CAF50),
                                    const Color(0xFF2E7D32),
                                  ]
                                : [
                                    const Color(0xFFFF6A00),
                                    const Color(0xFFFF8A00),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isPremiumUser
                                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                                  : const Color(0xFFFF6A00).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPremiumUser ? Icons.check_circle : Icons.star,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPremiumUser ? 'Premium Active' : pack.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              isPremiumUser
                                  ? 'You already have premium access'
                                  : pack.note,
                              style: const TextStyle(
                                color: Color(0xFFB9A8D0),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isPremiumUser ? 'ACTIVE' : pack.realPrice,
                            style: TextStyle(
                              color: isPremiumUser
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6A00),
                              fontWeight: FontWeight.w900,
                              fontSize: isPremiumUser ? 14 : 20,
                            ),
                          ),
                          if (!isPremiumUser) ...[
                            const Text(
                              '/month',
                              style: TextStyle(
                                color: Color(0xFF8C7BA6),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Auto-renewable',
                              style: TextStyle(
                                color: Color(0xFF8C7BA6),
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Token badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPremiumUser
                            ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                            : [
                                const Color(0xFFFF6A00),
                                const Color(0xFFFF8A00),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isPremiumUser
                              ? const Color(0xFF4CAF50).withOpacity(0.3)
                              : const Color(0xFFFF6A00).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPremiumUser
                              ? Icons.check_circle
                              : Icons.local_fire_department,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPremiumUser
                              ? 'Premium Active'
                              : '${pack.tokens} Tokens/Month',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Premium benefits
                  Text(
                    isPremiumUser
                        ? 'Your Premium Benefits:'
                        : 'Premium Benefits:',
                    style: TextStyle(
                      color: isPremiumUser
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF6A00),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Benefits grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: pack.features.take(4).map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D162B).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF6A00).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CAF50),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  color: Color(0xFFB9A8D0),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  if (pack.features.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${pack.features.length - 4} more premium features',
                        style: TextStyle(
                          color: isPremiumUser
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF6A00),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Premium badge
        Positioned(
          top: -8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPremiumUser
                    ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                    : [const Color(0xFFFF6A00), const Color(0xFFFF8A00)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isPremiumUser
                      ? const Color(0xFF4CAF50).withOpacity(0.4)
                      : const Color(0xFFFF6A00).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              isPremiumUser ? 'ACTIVE' : 'PREMIUM',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ),
        ),

        // Selection indicator (bottom right inside card)
        if (selected)
          Positioned(
            bottom: 72,
            right: 24,

            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}
