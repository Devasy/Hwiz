import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Profile avatar widget with initials and colored background
class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.showBorder = false,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  Color _getColorFromName(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? _getColorFromName(context, name);
    final initials = _getInitials(name);
    final isDarkBg = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final textColor = isDarkBg ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              )
            : null,
        boxShadow: showBorder ? AppTheme.shadowSmall : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
