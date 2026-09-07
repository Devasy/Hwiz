import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/profile.dart';

/// A card widget to display profile information
class ProfileCard extends StatelessWidget {
  final Profile profile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    this.isSelected = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Hero(
                tag: 'profile_avatar_${profile.id}',
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: _getAvatarColor(context),
                  backgroundImage: _hasValidPhoto(profile.photoPath)
                      ? FileImage(File(profile.photoPath!))
                      : null,
                  child: !_hasValidPhoto(profile.photoPath)
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (profile.gender != null) ...[
                          Icon(
                            profile.gender?.toLowerCase() == 'male'
                                ? Icons.male
                                : profile.gender?.toLowerCase() == 'female'
                                    ? Icons.female
                                    : Icons.person,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.gender!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                        if (profile.dateOfBirth != null &&
                            profile.gender != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (profile.dateOfBirth != null)
                          Text(
                            _getAgeText(profile.dateOfBirth!),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            size: 20,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 12),
                        Text('Delete',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(BuildContext context) {
    // Generate color based on name hash using Material You color palette
    final hash = profile.name.hashCode;
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getAgeText(String dateOfBirth) {
    try {
      final dob = DateTime.parse(dateOfBirth);
      final today = DateTime.now();
      int age = today.year - dob.year;

      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      if (age < 2) {
        final months = (today.year - dob.year) * 12 + today.month - dob.month;
        return '$months ${months == 1 ? 'month' : 'months'}';
      }

      return '$age years';
    } catch (e) {
      return dateOfBirth;
    }
  }

  bool _hasValidPhoto(String? path) {
    if (path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
