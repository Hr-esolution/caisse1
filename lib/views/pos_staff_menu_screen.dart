import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';

class PosStaffMenuScreen extends StatelessWidget {
  const PosStaffMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();
    if (pos.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != '/pos') {
          Get.offAllNamed('/pos');
        }
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menu Serveur'),
          leading: const AppBackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Serveur'),
        leading: const AppBackButton(),
        actions: [
          TextButton(
            onPressed: () {
              pos.lock();
              Get.offAllNamed('/pos');
            },
            child: const Text('Verrouiller'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(
            child: GetBuilder<PosController>(
              builder: (_) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerCard(pos),
                      const SizedBox(height: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 900
                                ? 1
                                : width < 1200
                                ? 2
                                : 3;
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: width < 900 ? 2.2 : 1.7,
                              children: [
                                _MenuActionCard(
                                  icon: Icons.point_of_sale_outlined,
                                  title: 'Nouvelle Commande',
                                  subtitle:
                                      'Créer une commande sur place, emporter ou livraison.',
                                  onTap: () => Get.toNamed('/pos-choice'),
                                ),
                                _MenuActionCard(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Mes Commandes',
                                  subtitle:
                                      'Consulter, éditer et encaisser les commandes du jour.',
                                  onTap: () {
                                    pos.setOrdersFilter('all');
                                    pos.setOrdersChannelFilter('all');
                                    pos.loadOrdersToday();
                                    Get.toNamed('/pos-orders');
                                  },
                                ),
                                _MenuActionCard(
                                  icon: Icons.phone_iphone_outlined,
                                  title: 'Mobile / Web',
                                  subtitle:
                                      'Traiter les commandes reçues en ligne.',
                                  onTap: () {
                                    pos.setOrdersFilter('all');
                                    pos.setOrdersChannelFilter('remote');
                                    pos.loadOrdersToday();
                                    Get.toNamed('/pos-orders');
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(PosController pos) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: GlassThemeData.glassContainerLight(
            borderColor: GlassColors.sushi.withAlpha(140),
            borderWidth: 1.2,
            shadows: [
              BoxShadow(
                color: GlassColors.redAccent.withAlpha(18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _badge(
                Icons.person_outline,
                pos.activeStaff?.name ?? 'Serveur -',
              ),
              _badge(Icons.storefront_outlined, pos.restaurantLabel),
              _badge(
                Icons.today_outlined,
                DateTime.now().toString().split(' ').first,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: AppColors.deepTeal.withAlpha(40),
            border: Border.all(color: AppColors.deepTeal.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.deepTeal),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(gradient: GlassThemeData.backgroundGradient()),
      child: CustomPaint(
        painter: _MenuBackgroundPainter(
          lineColor: GlassColors.redAccent.withAlpha(12),
        ),
      ),
    );
  }
}

class _MenuActionCard extends StatefulWidget {
  const _MenuActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_MenuActionCard> createState() => _MenuActionCardState();
}

class _MenuActionCardState extends State<_MenuActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        scale: _hovered ? 1.03 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: GlassThemeData.glassCard(
                isHovered: _hovered,
                accentColor: GlassColors.redAccent,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: AppColors.burntOrange.withAlpha(60),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _iconBadge(widget.icon),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: AppTypography.headline2.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            widget.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: widget.onTap,
                              style: GlassButtonStyle.secondary().copyWith(
                                minimumSize: const WidgetStatePropertyAll(
                                  Size(0, 40),
                                ),
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(horizontal: 14),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Ouvrir'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: GlassThemeData.accentGradient(
          startColor: GlassColors.redAccent,
          endColor: GlassColors.sushiDark,
        ),
        boxShadow: [
          BoxShadow(
            color: GlassColors.redAccent.withAlpha(28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _MenuBackgroundPainter extends CustomPainter {
  _MenuBackgroundPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (double y = 30; y <= size.height; y += 100) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        final wave = math.sin((x / 85) + (y / 115)) * 3.5;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBackgroundPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
