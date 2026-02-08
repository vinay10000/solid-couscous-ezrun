import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../widgets/profile_settings_item.dart';

class DataPrivacySettingsScreen extends ConsumerStatefulWidget {
  const DataPrivacySettingsScreen({super.key});

  @override
  ConsumerState<DataPrivacySettingsScreen> createState() =>
      _DataPrivacySettingsScreenState();
}

class _DataPrivacySettingsScreenState
    extends ConsumerState<DataPrivacySettingsScreen> {
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Fetch runs
      final runs = await Supabase.instance.client
          .from('runs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if ((runs as List).isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No runs to export.')));
        }
        return;
      }

      // Generate CSV
      final buffer = StringBuffer();
      buffer.writeln('Distance(m),Duration(s),Date,AvgPace,Calories');

      for (final run in runs) {
        final dist = run['distance_meters'] ?? 0;
        final dur = run['duration_seconds'] ?? 0;
        final date = run['created_at'] ?? '';
        final pace = run['avg_pace_min_per_km'] ?? 0;
        final cals =
            run['calories'] ??
            0; // Assuming calories exist, if not fetch what available
        buffer.writeln('$dist,$dur,$date,$pace,$cals');
      }

      // Save to file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ezrun_export.csv');
      await file.writeAsString(buffer.toString());

      // Share
      await Share.shareXFiles([XFile(file.path)], text: 'My EZRUN Data Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Data & Privacy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                ProfileSettingsItem(
                  title: 'Export running history',
                  subtitle: 'Download your data as CSV',
                  icon: Icons.download_rounded,
                  onTap: _exportData,
                ),
              ],
            ),
          ),
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
