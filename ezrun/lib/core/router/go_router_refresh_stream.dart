import 'dart:async';

import 'package:flutter/foundation.dart';

/// A tiny helper that tells GoRouter to re-evaluate `redirect` when a stream emits.
///
/// Common use: refresh the router when auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
