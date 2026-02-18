import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tableau de bord serveur'),
        backgroundColor: AppColors.blancPur,
        foregroundColor: AppColors.charbon,
        elevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthController.instance.logout();
              Get.offAllNamed('/login');
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Déconnexion'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          children: [
            _tile(
              icon: Icons.point_of_sale,
              title: 'Nouvelle Commande',
              onTap: () => Get.toNamed('/pos'),
            ),
            _tile(
              icon: Icons.receipt_long,
              title: 'Mes Commandes',
              onTap: () => Get.toNamed('/pos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: GlassThemeData.glassContainerLight(
          borderColor: GlassColors.sushi.withAlpha(140),
          borderWidth: 1.2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: GlassColors.redAccent),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTypography.bodyLarge),
          ],
        ),
      ),
    );
  }
}
