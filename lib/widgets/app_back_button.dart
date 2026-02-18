import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.arrow_back, size: 20),
      color: iconColor ?? AppColors.charbon,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
