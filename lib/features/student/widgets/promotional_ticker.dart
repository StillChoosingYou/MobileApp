import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/campus_models.dart';
import '../../../providers/feature_providers.dart';

/// A scrolling marquee-style promotional announcement ticker.
/// Displays active promotional announcements in a horizontal scrolling banner.
class PromotionalTicker extends ConsumerWidget {
  const PromotionalTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoAsync = ref.watch(promotionalAnnouncementsProvider);

    return promoAsync.when(
      data: (promos) {
        // Filter only currently active promotions
        final activePromos = promos.where((p) => p.isCurrentlyActive).toList();

        // Sort by priority (highest first)
        activePromos.sort((a, b) => b.priority.compareTo(a.priority));

        if (activePromos.isEmpty) {
          return const SizedBox.shrink();
        }

        return _TickerView(promotions: activePromos);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// The actual scrolling ticker view
class _TickerView extends StatefulWidget {
  final List<PromotionalAnnouncement> promotions;

  const _TickerView({required this.promotions});

  @override
  State<_TickerView> createState() => _TickerViewState();
}

class _TickerViewState extends State<_TickerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final double _itemWidth = 400; // Approximate width per item
  double _totalWidth = 0;

  @override
  void initState() {
    super.initState();
    _totalWidth = _itemWidth * widget.promotions.length;
    _controller = AnimationController(
      duration: Duration(seconds: 8 + widget.promotions.length * 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: _totalWidth).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default colors if not specified
    const defaultBgColor = Color(0xFF102A6D);
    const defaultTextColor = Colors.white;

    return SizedBox(
      height: 48,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-_animation.value, 0),
              child: Row(
                children: [
                  // Original set
                  ...widget.promotions.map((promo) => _PromoItem(
                        promo: promo,
                        width: _itemWidth,
                        defaultBgColor: defaultBgColor,
                        defaultTextColor: defaultTextColor,
                      )),
                  // Duplicate set for seamless looping
                  ...widget.promotions.map((promo) => _PromoItem(
                        promo: promo,
                        width: _itemWidth,
                        defaultBgColor: defaultBgColor,
                        defaultTextColor: defaultTextColor,
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Individual promotional item in the ticker
class _PromoItem extends StatelessWidget {
  final PromotionalAnnouncement promo;
  final double width;
  final Color defaultBgColor;
  final Color defaultTextColor;

  const _PromoItem({
    required this.promo,
    required this.width,
    required this.defaultBgColor,
    required this.defaultTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: promo.backgroundColor ?? defaultBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (promo.icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: promo.textColor ?? defaultTextColor,
                size: 18,
              ),
              child: promo.icon!,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              promo.title,
              style: TextStyle(
                color: promo.textColor ?? defaultTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (promo.actionLabel != null && promo.actionUrl != null) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _handleAction(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  promo.actionLabel!,
                  style: TextStyle(
                    color: promo.textColor ?? defaultTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleAction(BuildContext context) {
    // For now, show a snackbar. In a real app, navigate based on actionUrl
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to: ${promo.actionUrl}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}