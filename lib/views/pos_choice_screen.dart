import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';

class PosChoiceScreen extends StatefulWidget {
  const PosChoiceScreen({super.key});

  @override
  State<PosChoiceScreen> createState() => _PosChoiceScreenState();
}

class _PosChoiceScreenState extends State<PosChoiceScreen> {
  String _type = 'on_site';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Type de commande'),
        leading: const AppBackButton(),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.terraCotta,
              backgroundColor: AppColors.livingCoral.withOpacity(0.14),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              pos.lock();
              Get.offAllNamed('/pos');
            },
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Verrouiller'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.blancPur.withAlpha(214),
                    border: Border.all(
                      color: AppColors.blancPur.withAlpha(140),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choisir le type',
                        style: AppTypography.headline2,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _typeCard(
                            value: 'on_site',
                            icon: Icons.table_restaurant_outlined,
                            label: 'Sur place',
                            description: 'Service en salle',
                          ),
                          _typeCard(
                            value: 'pickup',
                            icon: Icons.takeout_dining_outlined,
                            label: 'À emporter',
                            description: 'Commandes mobile / web à récupérer',
                          ),
                          _typeCard(
                            value: 'delivery',
                            icon: Icons.local_shipping_outlined,
                            label: 'Livraison',
                            description: 'Commandes mobile / web à livrer',
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _type == 'on_site'
                            ? const SizedBox(height: 0)
                            : Padding(
                                key: ValueKey(_type),
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nom client',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Téléphone',
                                      ),
                                    ),
                                    if (_type == 'delivery') ...[
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _addressController,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                          labelText: 'Adresse livraison',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => _continue(pos),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.deepTeal,
                                  AppColors.burntOrange,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Continuer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeCard({
    required String value,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final selected = _type == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        width: 170,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.deepTeal.withAlpha(35),
                    AppColors.livingCoral.withAlpha(35),
                  ],
                )
              : null,
          color: selected ? null : AppColors.blancPur.withAlpha(190),
          border: Border.all(
            color: selected ? AppColors.deepTeal : AppColors.grisLeger,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.deepTeal.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.deepTeal, size: 20),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.bodyLarge),
            const SizedBox(height: 6),
            Text(
              description,
              style: AppTypography.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _continue(PosController pos) {
    if (_type != 'on_site') {
      if (_nameController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        Get.snackbar(
          'Erreur',
          'Nom et téléphone obligatoires',
          snackPosition: SnackPosition.BOTTOM,
          animationDuration: const Duration(milliseconds: 260),
        );
        return;
      }
      if (_type == 'delivery' && _addressController.text.trim().isEmpty) {
        Get.snackbar(
          'Erreur',
          'Adresse obligatoire pour livraison',
          snackPosition: SnackPosition.BOTTOM,
          animationDuration: const Duration(milliseconds: 260),
        );
        return;
      }
    }

    pos.setFulfillmentType(_type);
    pos.setCustomerInfo(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
    );

    if (_type == 'on_site') {
      Get.toNamed('/pos-tables');
    } else {
      Get.toNamed('/pos-order');
    }
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepTeal.withAlpha(20),
            AppColors.offWhite,
            AppColors.livingCoral.withAlpha(24),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _ChoiceBackgroundPainter(
          color: AppColors.deepTeal.withAlpha(24),
        ),
      ),
    );
  }
}

class _ChoiceBackgroundPainter extends CustomPainter {
  _ChoiceBackgroundPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (double y = 30; y < size.height; y += 92) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 22) {
        final wave = math.sin((x / 76) + (y / 88)) * 5;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChoiceBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
