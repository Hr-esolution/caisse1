import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/sync_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../utils/pos_window.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.activeRoute,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final String? activeRoute;
  final Widget? floatingActionButton;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantController = Get.find<RestaurantController>();
      final restaurants = restaurantController.getActiveRestaurants();
      if (restaurantController.selectedRestaurantId == null &&
          restaurants.isNotEmpty) {
        restaurantController.setSelectedRestaurantId(restaurants.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final restaurantController = Get.find<RestaurantController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            _sidebar(),
            Expanded(
              child: Column(
                children: [
                  _header(auth, restaurantController),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    AuthController auth,
    RestaurantController restaurantController,
  ) {
    final syncController = Get.find<SyncController>();
    final canPop = Navigator.of(context).canPop();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: GlassColors.glassWhite.withAlpha(210),
        border: Border(
          bottom: BorderSide(color: GlassColors.sushi.withAlpha(80), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: GlassColors.redAccent.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (canPop)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            Text(widget.title, style: AppTypography.headline2),
            const SizedBox(width: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GetBuilder<RestaurantController>(
                  builder: (controller) {
                    final restaurants = controller.getActiveRestaurants();
                    if (restaurants.isEmpty) {
                      return const Text(
                        'Aucun restaurant',
                        style: AppTypography.caption,
                      );
                    }
                    final userRestId =
                        auth.currentUser?.restaurantId ?? restaurants.first.id;
                    final restaurant = restaurants.firstWhere(
                      (r) => r.id == userRestId,
                      orElse: () => restaurants.first,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GlassColors.glassWhite.withAlpha(180),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GlassColors.sushi.withAlpha(120),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_mall_directory, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            restaurant.name,
                            style: AppTypography.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GlassColors.glassWhite.withAlpha(170),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: GlassColors.sushi.withAlpha(120)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: GlassColors.glassText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    auth.currentUser?.name ?? 'Admin',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (syncController.canManualSync) ...[
              Obx(
                () => OutlinedButton.icon(
                  onPressed: syncController.isSyncing
                      ? null
                      : () async => syncController.manualSync(),
                  icon: Icon(
                    syncController.isOnline
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    size: 16,
                  ),
                  label: Text(
                    syncController.isSyncing ? 'Sync...' : 'Synchroniser',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            TextButton.icon(
              onPressed: () async {
                await auth.logout();
                Get.offAllNamed('/login');
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() {
    final width = _collapsed ? 72.0 : 220.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: GlassColors.glassWhite.withAlpha(220),
        border: Border(
          right: BorderSide(color: GlassColors.sushi.withAlpha(90), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: GlassColors.redAccent.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                GetBuilder<SettingsController>(
                  builder: (settingsCtrl) {
                    final logoPath = settingsCtrl.settings.appLogoPath;
                    if (logoPath != null &&
                        logoPath.trim().isNotEmpty &&
                        File(logoPath).existsSync()) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(logoPath),
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Icon(
                      Icons.point_of_sale,
                      size: 20,
                      color: GlassColors.redAccent,
                    );
                  },
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 8),
                  const Text('Caisse', style: AppTypography.headline2),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _collapsed ? Icons.chevron_right : Icons.chevron_left,
                  ),
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _navItem(
            Icons.dashboard_outlined,
            'Tableau de bord',
            '/admin-dashboard',
          ),
          _navItem(Icons.store_outlined, 'Restaurants', '/restaurants'),
          _navItem(Icons.people_outline, 'Utilisateurs', '/users'),
          _navItem(Icons.bar_chart, 'Comptabilité', '/admin-accounting'),
          _navItem(Icons.point_of_sale, 'POS', '/pos'),
          _navItem(Icons.inventory_2_outlined, 'Catalogue', '/catalog'),
          _navItem(Icons.table_bar, 'Tables', '/tables'),
          _navItem(Icons.sync, 'Importer', '/import-data'),
          _navItem(Icons.settings, 'Settings', '/settings'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String route) {
    final isActive = widget.activeRoute == route || Get.currentRoute == route;
    return InkWell(
      onTap: () {
        if (route == '/pos') {
          PosWindow.open();
          return;
        }
        if (Get.currentRoute != route) {
          Get.toNamed(route);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.terraCotta.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.terraCotta.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.terraCotta : AppColors.grisModerne,
            ),
            if (!_collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive
                        ? AppColors.terraCotta
                        : AppColors.grisModerne,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
