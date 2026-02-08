import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../state/settings_controller.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  // We need to fetch blocked users.
  // Let's assume usage of SettingsRepository directly via FutureBuilder or a new provider.
  // For simplicity, we'll use FutureBuilder calling the repository.

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(settingsRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.fetchBlockedUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final blockedUsers = snapshot.data ?? [];

          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text(
                'No blocked users',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            itemCount: blockedUsers.length,
            padding: const EdgeInsets.all(AppSizes.md),
            itemBuilder: (context, index) {
              final item = blockedUsers[index];
              final user = item['user'] as Map<String, dynamic>;
              final name = user['name'] ?? 'Unknown';
              final id = user['id'];
              final profilePic = user['profile_pic'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePic != null
                      ? NetworkImage(profilePic)
                      : null,
                  backgroundColor: AppColors.primary,
                  child: profilePic == null
                      ? Text(name[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await repository.unblockUser(id);
                    setState(() {}); // Refresh list
                  },
                  child: const Text(
                    'Unblock',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
