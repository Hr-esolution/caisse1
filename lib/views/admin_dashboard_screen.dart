import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/sushi_design.dart';
import '../utils/pos_window.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final Future<_DashboardStats> _statsFuture = _loadStats();

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Tableau de bord admin',
      activeRoute: '/admin-dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<_DashboardStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final loading = !snapshot.hasData;
              final stats = snapshot.data;
              return Row(
                children: [
                  _statCard(
                    label: 'Commandes tables',
                    value: loading ? '…' : '${stats!.tableOrders}',
                    accent: SushiColors.red,
                  ),
                  const SizedBox(width: SushiSpace.lg),
                  _statCard(
                    label: 'Commandes web/mobile',
                    value: loading ? '…' : '${stats!.remoteOrders}',
                    accent: SushiColors.teal,
                  ),
                  const SizedBox(width: SushiSpace.lg),
                  _statCard(
                    label: 'CA total serveurs',
                    value: loading ? '…' : _money(stats!.totalCA),
                    accent: SushiColors.green,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: SushiSpace.lg),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: SushiSpace.lg,
              mainAxisSpacing: SushiSpace.lg,
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

  Future<_DashboardStats> _loadStats() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final orders = await DatabaseService.getPosOrdersByDateRange(start, end);

    int tableOrders = 0;
    int remoteOrders = 0;
    double totalCA = 0;

    for (final o in orders) {
      totalCA += o.totalPrice;
      if ((o.tableNumber ?? '').trim().isNotEmpty) {
        tableOrders += 1;
      }
      final ch = o.channel.toLowerCase();
      if (ch == 'web' || ch == 'api' || ch == 'mobile' || ch == 'kiosk') {
        remoteOrders += 1;
      }
    }

    return _DashboardStats(
      tableOrders: tableOrders,
      remoteOrders: remoteOrders,
      totalCA: totalCA,
    );
  }

  String _money(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(SushiSpace.lg),
        decoration: SushiDeco.card(selected: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: SushiTypo.caption),
            const SizedBox(height: SushiSpace.xs),
            Text(value, style: SushiTypo.h1.copyWith(color: accent)),
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
        decoration: SushiDeco.card(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: SushiColors.red),
            const SizedBox(height: SushiSpace.sm),
            Text(title, style: SushiTypo.bodyMd),
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
          title: const Text('Vider stockage local', style: SushiTypo.h3),
          content: const SizedBox(
            width: 520,
            child: Text(
              'Cette action supprime les données locales (restaurants, catégories, produits, tables et commandes). '
              'Les utilisateurs sont conservés pour permettre la reconnexion.',
              style: SushiTypo.bodyMd,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler', style: SushiTypo.bodySm),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ButtonStyle(
                foregroundColor:
                    const WidgetStatePropertyAll(SushiColors.red),
              ),
              child: const Text('Supprimer', style: SushiTypo.bodySm),
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

class _DashboardStats {
  _DashboardStats({
    required this.tableOrders,
    required this.remoteOrders,
    required this.totalCA,
  });
  final int tableOrders;
  final int remoteOrders;
  final double totalCA;
}
