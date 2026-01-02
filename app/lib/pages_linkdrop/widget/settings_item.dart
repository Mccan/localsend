import 'package:flutter/material.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const SettingsItem({
    required this.icon,
    required this.title,
    required this.isDark,
    this.value,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? LinkDropColors.zinc200 : LinkDropColors.zinc900,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 14,
                  color: LinkDropColors.zinc500,
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
