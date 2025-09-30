import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/ghostface_inspiration.dart';

class InspirationCard extends StatelessWidget {
  const InspirationCard({super.key, required this.item});

  final GhostfaceInspiration item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [
                    AppTheme.cardGradientStart,
                    AppTheme.cardGradientEnd,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.18),
              colorBlendMode: BlendMode.darken,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const _LoadingPlaceholder();
              },
              errorBuilder: (context, error, stackTrace) {
                return const _LoadingPlaceholder();
              },
            ),
          ),
          const Positioned(
            top: 12,
            left: 12,
            child: _GhostfaceBadge(),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _CardFooter(item: item),
          ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.item});

  final GhostfaceInspiration item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.caption,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(
                Icons.face_retouching_natural,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '@${item.creator}',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  item.likes,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostfaceBadge extends StatelessWidget {
  const _GhostfaceBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_people_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Ghostface',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B1F3A), Color(0xFF141021)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}
