import 'package:flutter/material.dart';
import '../constants/strings.dart';

class DishcoveryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLanguageChanged;
  final VoidCallback? onProfileTapped;

  const DishcoveryAppBar({
    super.key,
    this.onLanguageChanged,
    this.onProfileTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        Strings.appName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        // Language Toggle
        TextButton(
          onPressed: onLanguageChanged,
          child: const Text(Strings.buttonChangeLanguage),
        ),
        // Profile Icon
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: onProfileTapped,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
