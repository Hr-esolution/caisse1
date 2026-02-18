import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_shell.dart';
import '../utils/pos_window.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Tableau de bord admin',
      activeRoute: '/admin-dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              children: [
                _tile(
                  icon: Icons.point_of_sale,
                  title: 'POS',
                  onTap: () => PosWindow.open(),
                ),
                _tile(
                  icon: Icons.people,
                  title: 'Utilisateurs',
                  onTap: () => Get.toNamed('/users'),
                ),
                _tile(
                  icon: Icons.store,
                  title: 'Restaurants',
                  onTap: () => Get.toNamed('/restaurants'),
                ),
                _tile(
                  icon: Icons.category,
                  title: 'Catégories',
                  onTap: () => Get.toNamed('/catalog'),
                ),
                _tile(
                  icon: Icons.inventory,
                  title: 'Produits',
                  onTap: () => Get.toNamed('/catalog'),
                ),
                _tile(
                  icon: Icons.table_bar,
                  title: 'Tables',
                  onTap: () => Get.toNamed('/tables'),
                ),
                _tile(
                  icon: Icons.bar_chart,
                  title: 'Comptabilité',
                  onTap: () => Get.toNamed('/admin-accounting'),
                ),
                _tile(
                  icon: Icons.sync,
                  title: 'Importer',
                  onTap: () => Get.toNamed('/import-data'),
                ),
                if (_canClearLocalData())
                  _tile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Vider stockage local',
                    onTap: () => _confirmClearLocalData(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    return Row(
      children: [
        _statCard('CA du jour', _money(12480.50)),
        const SizedBox(width: AppSpacing.lg),
        _statCard('Transactions', '124'),
        const SizedBox(width: AppSpacing.lg),
        _statCard('Panier moyen', _money(100.65)),
      ],
    );
  }

  String _money(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color.fromARGB(104, 233, 232, 232),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color.fromARGB(255, 246, 10, 10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTypography.mono),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.grisPale,
          border: Border.all(color: AppColors.grisLeger),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.terraCotta),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTypography.bodyLarge),
          ],
        ),
      ),
    );
  }

  bool _canClearLocalData() {
    final auth = Get.find<AuthController>();
    final role = auth.currentRole;
    return role == 'admin' || role == 'superadmin';
  }

  Future<void> _confirmClearLocalData(BuildContext context) async {
    if (!_canClearLocalData()) {
      Get.snackbar(
        'Accès refusé',
        'Action réservée à admin/superadmin',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Vider stockage local'),
          content: const SizedBox(
            width: 520,
            child: Text(
              'Cette action supprime les données locales (restaurants, catégories, produits, tables et commandes). '
              'Les utilisateurs sont conservés pour permettre la reconnexion.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await DatabaseService.clearLocalBusinessData();
      if (Get.isRegistered<RestaurantController>()) {
        await Get.find<RestaurantController>().fetchAllRestaurants();
      }
      if (Get.isRegistered<CategoryController>()) {
        await Get.find<CategoryController>().fetchAllCategories();
      }
      if (Get.isRegistered<ProductController>()) {
        await Get.find<ProductController>().fetchAllProducts();
      }

      Get.snackbar(
        'Succès',
        'Stockage local vidé',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec suppression données locales: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
