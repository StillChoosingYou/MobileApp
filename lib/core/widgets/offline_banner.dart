import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';

/// A small, unobtrusive banner that appears at the top of the app when the
/// device goes offline. It auto-hides when connectivity returns.
///
/// Usage: wrap your `MaterialApp.router` (or `MaterialApp`) body with a
/// `Stack` that includes `const OfflineBanner()`, or add it as a persistent
/// overlay entry from `main.dart` if you prefer not to change the app tree.
/// The current scaffold uses the overlay approach in `lib/main.dart`.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        elevation: 4,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 18,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'re offline — showing cached data where available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience overlay entry helper for apps that don't want to modify the
/// widget tree. Call `showOfflineBannerOverlay(context, ref)` once at startup
/// (e.g. in `main.dart` after `runApp`) and it will manage itself.
OverlayEntry? _offlineBannerEntry;

void showOfflineBannerOverlay(BuildContext context, WidgetRef ref) {
  if (_offlineBannerEntry != null) return;

  _offlineBannerEntry = OverlayEntry(
    builder: (context) => const OfflineBanner(),
  );

  Overlay.of(context).insert(_offlineBannerEntry!);

  // Keep the overlay in sync with the connectivity state so it hides when
  // we're back online without a full rebuild of the entry.
  ref.listen(isOnlineProvider, (_, next) {
    if (next) {
      _offlineBannerEntry?.remove();
      _offlineBannerEntry = null;
    } else if (_offlineBannerEntry == null) {
      _offlineBannerEntry = OverlayEntry(builder: (context) => const OfflineBanner());
      Overlay.of(context).insert(_offlineBannerEntry!);
    }
  });
}