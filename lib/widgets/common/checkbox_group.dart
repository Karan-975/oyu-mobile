import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CheckboxGroup extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const CheckboxGroup({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: options.map((option) {
              final checked = selectedValue == option;
              return CheckboxListTile(
                dense: true,
                activeColor: AppColors.primary,
                title: Text(option, style: const TextStyle(fontSize: 14)),
                value: checked,
                onChanged: (_) => onChanged(checked ? null : option),
              );
            }).toList(),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
