import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String username;
  final String? profileColor; // Hex string e.g. "#FF0000"
  final double radius;
  final double? borderSize;
  final Color? borderColor;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.username,
    this.profileColor,
    this.radius = 20,
    this.borderSize,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the profile color hex string to a Color object
    final backgroundColor = _parseColor(profileColor) ?? AppColors.primary;

    // Determine content (Image or Initials)
    Widget content;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        placeholder: (context, url) => Container(
          color: AppColors.glassMedium,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textMuted),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitials(backgroundColor),
      );
    } else {
      content = _buildInitials(backgroundColor);
    }

    // Apply border if requested
    Widget avatar = ClipOval(child: content);

    if (borderSize != null && borderSize! > 0) {
      avatar = Container(
        padding: EdgeInsets.all(borderSize!),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.glassBorderLight,
            width: borderSize!,
          ),
        ),
        child: avatar,
      );
    } else {
      // Even without a specific border size, we might want a simple container
      // to ensure the clip is perfect and maybe add a shadow if we wanted to later
      // But keeping it simple for now.
      // Just ensuring strict sizing.
      avatar = SizedBox(width: radius * 2, height: radius * 2, child: avatar);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildInitials(Color backgroundColor) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        _getInitials(username),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8, // Scale font with radius
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final nameParts = name.trim().split(RegExp(r'\s+'));

    if (nameParts.isEmpty) return '?';

    String initials = '';

    // First letter of first name
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials += nameParts[0][0].toUpperCase();
    }

    // First letter of last name (if exists)
    if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
      initials += nameParts[1][0].toUpperCase();
    } else if (nameParts[0].length > 1) {
      // If only one name but longer than 1 char, use first two letters?
      // Or just 1 letter. existing prominent apps usually do 1 letter if single name.
      // Let's stick strictly to Name parts.
    }

    if (initials.isEmpty) return name[0].toUpperCase();

    return initials;
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;

    try {
      var hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
