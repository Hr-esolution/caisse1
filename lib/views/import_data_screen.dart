import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/import_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/glass_card.dart';

class ImportDataScreen extends StatelessWidget {
  const ImportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final importController = Get.find<ImportController>();

    return AdminShell(
      title: 'Importer',
      activeRoute: '/import-data',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Synchroniser les données', style: GlassTypography.headline1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Importez vos restaurants, produits, catégories, utilisateurs et tables en une seule action.',
              style: GlassTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progression',
                        style: GlassTypography.headline2,
                      ),
                      Obx(
                        () => Text(
                          '${(importController.importProgress * 100).round()}%',
                          style: GlassTypography.label.copyWith(
                            color: GlassColors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Obx(
                      () => LinearProgressIndicator(
                        value: importController.importProgress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: GlassColors.glassWhite.withAlpha(60),
                        color: GlassColors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(
                    () => AnimatedOpacity(
                      opacity: importController.importStatus.isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        importController.importStatus.isEmpty
                            ? 'Prêt à importer'
                            : importController.importStatus,
                        style: GlassTypography.bodySmall,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 720;
                  final columns = isCompact ? 2 : 3;
                  final itemWidth =
                      (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                      columns;

                  final buttons = [
                    _actionButton(
                      label: 'Importer tout',
                      primary: true,
                      importController: importController,
                      onTap: () => importController.importAllData(),
                    ),
                    _actionButton(
                      label: 'Restaurants',
                      importController: importController,
                      onTap: () => importController.importRestaurants(),
                    ),
                    _actionButton(
                      label: 'Catégories',
                      importController: importController,
                      onTap: () => importController.importCategories(),
                    ),
                    _actionButton(
                      label: 'Produits',
                      importController: importController,
                      onTap: () => importController.importProducts(),
                    ),
                    _actionButton(
                      label: 'Utilisateurs',
                      importController: importController,
                      onTap: () => importController.importUsers(),
                    ),
                    _actionButton(
                      label: 'Tables',
                      importController: importController,
                      onTap: () => importController.importTables(),
                    ),
                  ];

                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: buttons
                        .map((btn) => SizedBox(width: itemWidth, child: btn))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required ImportController importController,
    required Future<void> Function() onTap,
    bool primary = false,
  }) {
    return Obx(() {
      final isBusy = importController.isImporting;
      return SizedBox(
        height: 46,
        child: ElevatedButton(
          style: primary
              ? GlassButtonStyle.primary()
              : GlassButtonStyle.secondary(),
          onPressed: isBusy
              ? null
              : () async {
                  try {
                    await onTap();
                  } catch (e) {
                    Get.snackbar(
                      'Erreur',
                      'Échec : $e',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
          child: Text(label, style: GlassTypography.button),
        ),
      );
    });
  }
}
