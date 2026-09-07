import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable profile form fields
/// Reduces code duplication across profile creation/edit screens
class ProfileFormFields {
  /// Name input field
  static Widget nameField({
    required TextEditingController controller,
    String? hintText,
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: hintText ?? 'Enter full name',
        prefixIcon: const Icon(Icons.person_outline),
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofocus: autofocus,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  /// Date of birth picker field
  static Widget dateOfBirthField({
    required BuildContext context,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    bool isOptional = false,
    TextEditingController? controller,
  }) {
    // Format date for display
    String displayText = '';
    if (selectedDate != null) {
      displayText =
          '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    }

    // If using Material theme variant (with controller)
    if (controller != null) {
      return TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: isOptional ? 'Date of Birth (Optional)' : 'Date of Birth',
          hintText: 'Select date',
          prefixIcon: const Icon(Icons.cake_outlined),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                  },
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        onTap: onTap,
      );
    }

    // AppTheme variant (without controller)
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isOptional ? 'Date of Birth (Optional)' : 'Date of Birth',
          hintText: 'Select date',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          displayText.isNotEmpty ? displayText : (isOptional ? 'Not set' : ''),
          style: displayText.isNotEmpty
              ? AppTheme.bodyLarge
              : AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textTertiary,
                ),
        ),
      ),
    );
  }

  /// Gender dropdown field
  static Widget genderField({
    required String? selectedGender,
    required ValueChanged<String?> onChanged,
    bool isOptional = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: selectedGender,
      decoration: InputDecoration(
        labelText: isOptional ? 'Gender (Optional)' : 'Gender',
        hintText: 'Select gender',
        prefixIcon: const Icon(Icons.wc_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: onChanged,
    );
  }

  /// Standard date picker dialog
  static Future<DateTime?> showDatePickerDialog(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
  }

  /// Format date for display (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Profile form data class to hold form state
class ProfileFormData {
  String name;
  DateTime? dateOfBirth;
  String? gender;

  ProfileFormData({
    this.name = '',
    this.dateOfBirth,
    this.gender,
  });

  bool get isValid => name.trim().isNotEmpty && name.trim().length >= 2;

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
    };
  }
}
