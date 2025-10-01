import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/in_app_purchase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/premium_service.dart';
import '../widgets/purchase_success_dialog.dart';
import '../widgets/purchase_failed_dialog.dart';

class _Pack {
  const _Pack({
    required this.name,
    required this.tokens,
    required this.productId,
    required this.price,
    required this.note,
    required this.imageAsset,
    this.whiteTint = false,
    this.isPremium = false,
    this.features = const [],
  });
  final String name;
  final int tokens;
  final String productId; // App Store Product ID
  final String price; // display only
  final String note;
  final String imageAsset;
  final bool whiteTint;
  final bool isPremium;
  final List<String> features;
}

class PurchasePage extends StatefulWidget {
  const PurchasePage();

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  late List<_Pack> _packs;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadPremiumStatus();
    _packs = [
      // Premium Subscription Package (at the top)
      const _Pack(
        name: 'SpookyAI Premium',
        tokens: 20,
        productId: 'spookyai_premium',
        price: '4.99',
        note: 'Monthly subscription with exclusive benefits',
        imageAsset: 'assets/images/ghost-face.png',
        whiteTint: true,
        isPremium: true,
        features: [
          '20 tokens per month',
          'Access to all prompts',
          'Daily token spin wheel',
          'Higher token rewards',
          'Exclusive premium themes',
          'Priority AI processing',
          'Ad-free experience',
          'Advanced customization options',
        ],
      ),
      // Token Packs
      const _Pack(
        name: '1 Token',
        tokens: 1,
        productId: '1_token_049',
        price: '0.49',
        note: 'Quick pack for a single image',
        imageAsset: 'assets/images/spider.png',
        whiteTint: true,
      ),
      const _Pack(
        name: '10 Token',
        tokens: 10,
        productId: '10_token_299',
        price: '2.99',
        note: 'Great for small trials 🎃',
        imageAsset: 'assets/images/pumpkin.png',
      ),
      const _Pack(
        name: '25 Token',
        tokens: 25,
        productId: '25_token_599',
        price: '5.99',
        note: 'Most popular choice 👻',
        imageAsset: 'assets/images/haunted-house.png',
      ),
      const _Pack(
        name: '60 Token',
        tokens: 60,
        productId: '60_token_1199',
        price: '11.99',
        note: 'For regular creators 🧙',
        imageAsset: 'assets/images/witch-hat.png',
      ),
      const _Pack(
        name: '150 Token',
        tokens: 150,
        productId: '150_token_2499',
        price: '24.99',
        note: 'For power users 💀',
        imageAsset: 'assets/images/ghost-face.png',
        whiteTint: true,
      ),
    ];
  }

  int? _selectedIndex;
  bool _isLoading = false;

  Future<void> _initialize() async {
    await InAppPurchaseService.initialize();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await PremiumService.isPremiumUser();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
      }
    }
  }

  Future<void> _buy(_Pack pack) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await InAppPurchaseService.purchaseProduct(
        pack.productId,
      );

      if (success) {
        // Handle premium subscription differently
        if (pack.isPremium) {
          await PremiumService.activatePremiumSubscription();
          await TokenService.grantMonthlyPremiumTokens();
          await TokenService.markMonthlyTokensClaimed();
        } else {
          // Regular token purchase - refresh token provider
          final tokenProvider = context.read<TokenProvider>();
          await tokenProvider.refreshBalance();
        }

        if (mounted) {
          if (pack.isPremium) {
            await showPurchaseSuccessDialog(
              context,
              tokensAdded: pack.tokens,
              isPremiumSubscription: true,
            );
          } else {
            await showPurchaseSuccessDialog(context, tokensAdded: pack.tokens);
          }
        }
      } else {
        if (mounted) {
          await PurchaseFailedDialog.show(
            context,
            reason:
                'Unable to initiate purchase. Please check your internet connection and try again.',
          );
        }
      }
    } catch (e) {
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
        } else if (e.toString().contains('user')) {
          reason = 'Purchase was cancelled by user.';
        }

        await PurchaseFailedDialog.show(context, reason: reason);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await InAppPurchaseService.restorePurchases();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages'),
        backgroundColor: const Color(0xFF0F0B1A),
        elevation: 0,
        actions: [
          // Restore Purchases Button
          IconButton(
            onPressed: _isLoading ? null : _restorePurchases,
            icon: const Icon(Icons.restore),
            tooltip: 'Restore Purchases',
          ),
          // Token Balance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          if (_isLoading)
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
                itemCount: _packs.length,
                itemBuilder: (context, index) {
                  final pack = _packs[index];
                  final bool selected = _selectedIndex == index;

                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0
                          ? 8
                          : 0, // Reduced padding for first item (premium)
                      bottom: index == _packs.length - 1 ? 0 : 16,
                    ),
                    child: GestureDetector(
                      onTap: pack.isPremium && _isPremium
                          ? null
                          : () => setState(() => _selectedIndex = index),
                      child: pack.isPremium
                          ? SizedBox(
                              height: 280, // Fixed height for premium card
                              child: _PremiumSubscriptionCard(
                                pack: pack,
                                selected: selected,
                                isPremiumUser: _isPremium,
                              ),
                            )
                          : _SelectablePackRow(
                              pack: pack,
                              isBestValue: false,
                              selected: selected,
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
            onPressed: (_selectedIndex == null || _isLoading)
                ? null
                : () async {
                    final pack = _packs[_selectedIndex!];
                    await _buy(pack);
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Purchase Selected Pack'),
          ),
        ),
      ),
    );
  }
}

// Legacy chip removed

String _pricePerToken(_Pack p) {
  final double total = double.tryParse(p.price) ?? 0;
  if (p.tokens == 0) return '-';
  final double per = total / p.tokens;
  return '${per.toStringAsFixed(2)} USD/token';
}

class _SelectablePackRow extends StatelessWidget {
  const _SelectablePackRow({
    required this.pack,
    required this.isBestValue,
    required this.selected,
  });

  final _Pack pack;
  final bool isBestValue;
  final bool selected;

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
                                '\$${pack.price}',
                                style: const TextStyle(
                                  color: Color(0xFFFF6A00),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _pricePerToken(pack),
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

  final _Pack pack;
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
                            isPremiumUser ? 'ACTIVE' : '\$${pack.price}',
                            style: TextStyle(
                              color: isPremiumUser
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6A00),
                              fontWeight: FontWeight.w900,
                              fontSize: isPremiumUser ? 14 : 20,
                            ),
                          ),
                          if (!isPremiumUser)
                            const Text(
                              '/month',
                              style: TextStyle(
                                color: Color(0xFF8C7BA6),
                                fontSize: 10,
                              ),
                            ),
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
