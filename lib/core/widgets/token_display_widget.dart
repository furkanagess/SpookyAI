import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/token_provider.dart';

class TokenDisplayWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showAddIcon;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;

  const TokenDisplayWidget({
    super.key,
    this.onTap,
    this.showAddIcon = true,
    this.iconSize = 20,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TokenProvider>(
      builder: (context, tokenProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: const Color(0xFF1D162B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF6A00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  if (tokenProvider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6A00),
                      ),
                    )
                  else
                    Text(
                      tokenProvider.balance ==
                              tokenProvider.balance.roundToDouble()
                          ? tokenProvider.balance.round().toString()
                          : tokenProvider.balance.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                        color: Colors.white,
                      ),
                    ),
                  if (showAddIcon) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFFF6A00),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TokenBalanceIndicator extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;

  const TokenBalanceIndicator({
    super.key,
    this.iconSize = 16,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TokenProvider>(
      builder: (context, tokenProvider, child) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: padding,
          decoration: BoxDecoration(
            color: tokenProvider.balance > 0
                ? const Color(0xFFB25AFF)
                : Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tokenProvider.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Icon(
                  tokenProvider.balance > 0 ? Icons.token : Icons.warning,
                  size: iconSize,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '${tokenProvider.balance}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
