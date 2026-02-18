import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/restaurant_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_shell.dart';

// Pantone Sushi Food Colors
class SushiColors {
  static const Color primaryGreen = Color(0xFF2D5016);
  static const Color accentGreen = Color(0xFF5FA834);
  static const Color coral = Color(0xFFE8886F);
  static const Color gingerOrange = Color(0xFFC1673D);
  static const Color cream = Color(0xFFFBF8F3);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color lightBorder = Color(0xFFE5DDD0);
}

class RestaurantManagementScreen extends StatelessWidget {
  const RestaurantManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurantController = Get.find<RestaurantController>();

    return AdminShell(
      title: 'Restaurants',
      activeRoute: '/restaurants',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, restaurantController),
        backgroundColor: SushiColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: Obx(
        () => restaurantController.restaurants.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 64,
                      color: SushiColors.accentGreen.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun restaurant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: constraints.maxWidth < 900
                          ? 440
                          : 380,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: restaurantController.restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant =
                          restaurantController.restaurants[index];
                      return _buildRestaurantCard(
                        context,
                        restaurant,
                        restaurantController,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    dynamic restaurant,
    RestaurantController controller,
  ) {
    return Card(
      elevation: 3,
      shadowColor: SushiColors.primaryGreen.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, SushiColors.cream],
          ),
          border: Border.all(color: SushiColors.lightBorder, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEditDialog(context, controller, restaurant),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SushiColors.accentGreen,
                          SushiColors.primaryGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: SushiColors.accentGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      restaurant.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: SushiColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: SushiColors.coral.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                restaurant.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SushiColors.darkText.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: SushiColors.gingerOrange.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                restaurant.address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SushiColors.darkText.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          restaurant.isActive
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: restaurant.isActive
                              ? SushiColors.accentGreen
                              : SushiColors.coral,
                          size: 24,
                        ),
                        onPressed: () async {
                          try {
                            await controller.toggleRestaurantActivation(
                              restaurant.id,
                            );
                            if (context.mounted) {
                              Get.snackbar(
                                'Succès',
                                'Statut mis à jour',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: SushiColors.accentGreen,
                                colorText: Colors.white,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Get.snackbar(
                                'Erreur',
                                e.toString(),
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: SushiColors.coral,
                                colorText: Colors.white,
                              );
                            }
                          }
                        },
                      ),
                      _buildPopupMenu(context, controller, restaurant),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    RestaurantController controller,
    dynamic restaurant,
  ) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        if (value == 'edit') {
          _showEditDialog(context, controller, restaurant);
        } else if (value == 'delete') {
          _showDeleteDialog(context, controller, restaurant);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: SushiColors.accentGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Modifier'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: SushiColors.coral, size: 18),
              const SizedBox(width: 8),
              const Text('Supprimer'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    RestaurantController controller,
  ) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SushiColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SushiColors.accentGreen, SushiColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nouveau restaurant',
                style: TextStyle(
                  color: SushiColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: nameController,
                  label: 'Nom du restaurant',
                  icon: Icons.restaurant_menu_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: addressController,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: SushiColors.darkText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final address = addressController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || address.isEmpty || phone.isEmpty) {
                  Get.snackbar(
                    'Erreur',
                    'Tous les champs sont obligatoires',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: SushiColors.coral,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
                  await controller.createRestaurant(
                    name: name,
                    address: address,
                    phone: phone,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.coral,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    RestaurantController controller,
    dynamic restaurant,
  ) async {
    final nameController = TextEditingController(text: restaurant.name);
    final addressController = TextEditingController(text: restaurant.address);
    final phoneController = TextEditingController(text: restaurant.phone);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SushiColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SushiColors.accentGreen, SushiColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Modifier restaurant',
                style: TextStyle(
                  color: SushiColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: nameController,
                  label: 'Nom du restaurant',
                  icon: Icons.restaurant_menu_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: addressController,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: SushiColors.darkText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final address = addressController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || address.isEmpty || phone.isEmpty) {
                  Get.snackbar(
                    'Erreur',
                    'Tous les champs sont obligatoires',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: SushiColors.coral,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
                  await controller.updateRestaurant(
                    restaurantId: restaurant.id,
                    name: name,
                    address: address,
                    phone: phone,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.coral,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    RestaurantController controller,
    dynamic restaurant,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SushiColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SushiColors.coral.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: SushiColors.coral,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Supprimer restaurant',
                style: TextStyle(
                  color: SushiColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${restaurant.name} ?',
            style: const TextStyle(color: SushiColors.darkText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: SushiColors.darkText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await controller.deleteRestaurant(restaurant.id);
                  if (context.mounted) {
                    Get.snackbar(
                      'Succès',
                      'Restaurant supprimé',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.accentGreen,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: SushiColors.coral,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SushiColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: SushiColors.darkText),
        prefixIcon: Icon(icon, color: SushiColors.accentGreen, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SushiColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SushiColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: SushiColors.primaryGreen,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: SushiColors.darkText),
    );
  }
}
