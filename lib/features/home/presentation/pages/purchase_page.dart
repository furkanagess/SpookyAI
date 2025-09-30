import 'package:flutter/material.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/services/in_app_purchase_service.dart';
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
  });
  final String name;
  final int tokens;
  final String productId; // App Store Product ID
  final String price; // display only
  final String note;
  final String imageAsset;
  final bool whiteTint;
}

class PurchasePage extends StatefulWidget {
  const PurchasePage();

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final List<_Pack> _packs = const [
    _Pack(
      name: '1 Token',
      tokens: 1,
      productId: '1_token_049',
      price: '0.49',
      note: 'Quick pack for a single image',
      imageAsset: 'assets/images/spider.png',
      whiteTint: true,
    ),
    _Pack(
      name: '10 Token',
      tokens: 10,
      productId: '10_token_299',
      price: '2.99',
      note: 'Great for small trials 🎃',
      imageAsset: 'assets/images/pumpkin.png',
    ),
    _Pack(
      name: '25 Token',
      tokens: 25,
      productId: '25_token_599',
      price: '5.99',
      note: 'Most popular choice 👻',
      imageAsset: 'assets/images/haunted-house.png',
    ),
    _Pack(
      name: '60 Token',
      tokens: 60,
      productId: '60_token_1199',
      price: '11.99',
      note: 'For regular creators 🧙',
      imageAsset: 'assets/images/witch-hat.png',
    ),
    _Pack(
      name: '150 Token',
      tokens: 150,
      productId: '150_token_2499',
      price: '24.99',
      note: 'For power users 💀',
      imageAsset: 'assets/images/ghost-face.png',
      whiteTint: true,
    ),
  ];

  int _balance = 0;
  int? _selectedIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await InAppPurchaseService.initialize();
    await _load();
  }

  Future<void> _load() async {
    _balance = await TokenService.getBalance();
    if (mounted) setState(() {});
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
        await _load();

        if (mounted) {
          await showPurchaseSuccessDialog(context, tokensAdded: pack.tokens);
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
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF6A00),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_balance',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 12;
                  final int count = _packs.length;
                  final double totalSpacing = spacing * (count - 1);
                  final double tileHeight =
                      ((constraints.maxHeight - totalSpacing) / count).clamp(
                        64.0,
                        constraints.maxHeight,
                      );

                  return Column(
                    children: List.generate(count, (index) {
                      final pack = _packs[index];
                      final bool isBest = pack.name == 'Haunted Pack';
                      final bool selected = _selectedIndex == index;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == count - 1 ? 0 : spacing,
                        ),
                        child: SizedBox(
                          height: tileHeight,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIndex = index),
                            child: _SelectablePackRow(
                              pack: pack,
                              isBestValue: isBest,
                              selected: selected,
                            ),
                          ),
                        ),
                      );
                    }),
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
                      const SizedBox(height: 6),
                      Text(
                        pack.note,
                        style: const TextStyle(color: Color(0xFF8C7BA6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
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
