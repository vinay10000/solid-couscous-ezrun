import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls visibility of global UI chrome like bottom navigation.
final bottomNavVisibleProvider = StateProvider<bool>((ref) => true);
