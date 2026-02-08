import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';

final _mePublicInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) async {
    final supabase = Supabase.instance.client;
    final me = supabase.auth.currentUser;
    if (me == null) return null;

    final rows = await supabase
        .from('users')
        .select('id, name, email, profile_pic')
        .eq('id', me.id)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.isEmpty ? null : list.first;
  },
);

class MapProfilePill extends ConsumerWidget {
  const MapProfilePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return const SizedBox.shrink();

    final async = ref.watch(_mePublicInfoProvider);
    return async.when(
      data: (user) {
        final name = (user?['name'] as String?)?.trim().isNotEmpty == true
            ? (user?['name'] as String).trim()
            : ((user?['email'] as String?)?.split('@').first ?? 'Runner');
        final pic = (user?['profile_pic'] as String?)?.trim();
        final hasPic = pic != null && pic.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            onTap: () {
              context.pushNamed(
                'publicProfile',
                pathParameters: {'userId': me.id},
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceRaised.withOpacity(0.78),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(color: colors.borderStrong),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowSoft,
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colors.accentPrimary,
                          colors.accentPrimary.withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: colors.borderStrong),
                    ),
                    child: ClipOval(
                      child: hasPic
                          ? CachedNetworkImage(
                              imageUrl: pic,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
