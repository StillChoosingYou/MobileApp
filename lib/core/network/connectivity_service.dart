import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps `connectivity_plus` so the app can observe online/offline state
/// without importing the plugin everywhere.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Emits the list of active network interfaces whenever connectivity changes.
  Stream<List<ConnectivityResult>> get stream => _connectivity.onConnectivityChanged;

  Future<List<ConnectivityResult>> check() => _connectivity.checkConnectivity();

  /// True if any network interface is up (i.e. the list is non-empty and not
  /// just [ConnectivityResult.none]).
  static bool isOnline(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.contains(ConnectivityResult.none);
}

/// Riverpod stream provider so any widget can `ref.watch(connectivityProvider)`
/// and react to network changes (e.g. show a banner, switch repositories).
final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return ConnectivityService.instance.stream;
});

/// A simple bool provider: `true` = online, `false` = offline.
final isOnlineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityProvider);
  return result.when(
    data: ConnectivityService.isOnline,
    // Optimistic: assume online until we hear otherwise.
    loading: () => true,
    error: (_, __) => true,
  );
});