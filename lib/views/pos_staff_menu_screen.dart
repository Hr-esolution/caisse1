import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../theme/sushi_design.dart';
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
          title: const Text('Menu Serveur', style: SushiTypo.h2),
          leading: const AppBackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Serveur', style: SushiTypo.h2),
        leading: const AppBackButton(),
        actions: [
          TextButton(
            onPressed: () {
              pos.lock();
              Get.offAllNamed('/pos');
            },
            child: const Text('Verrouiller', style: SushiTypo.bodySm),
          ),
          const SizedBox(width: SushiSpace.sm),
        ],
      ),
      body: GetBuilder<PosController>(
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SushiSpace.lg,
              vertical: SushiSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(pos),
                const SizedBox(height: SushiSpace.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount =
                          width < 900 ? 1 : width < 1200 ? 2 : 3;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: SushiSpace.md,
                        mainAxisSpacing: SushiSpace.md,
                        childAspectRatio: width < 900 ? 2.2 : 1.7,
                        children: [
                          _MenuActionCard(
                            icon: Icons.point_of_sale_outlined,
                            title: 'Nouvelle Commande',
                            description:
                                'Créer une commande sur place, emporter ou livraison.',
                            emojiIcon: Icons.local_dining_outlined,
                            emojiLabel: 'POS',
                            onTap: () => Get.toNamed('/pos-choice'),
                          ),
                          _MenuActionCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Mes Commandes',
                            description:
                                'Consulter, éditer et encaisser les commandes du jour.',
                            emojiIcon: Icons.receipt_long_outlined,
                            emojiLabel: 'Jour',
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
                            description:
                                'Traiter les commandes reçues en ligne.',
                            emojiIcon: Icons.wifi_tethering_outlined,
                            emojiLabel: 'Remote',
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
    );
  }

  Widget _headerCard(PosController pos) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.xl,
        vertical: SushiSpace.md,
      ),
      child: Wrap(
        spacing: SushiSpace.sm,
        runSpacing: SushiSpace.xs,
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
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.sm,
        vertical: SushiSpace.xs,
      ),
      decoration: SushiDeco.badge(bg: SushiColors.redPale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SushiColors.red),
          const SizedBox(width: SushiSpace.xs),
          Text(text, style: SushiTypo.tag.copyWith(color: SushiColors.ink)),
        ],
      ),
    );
  }

}

class _MenuActionCard extends StatefulWidget {
  const _MenuActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.emojiIcon,
    required this.emojiLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final IconData emojiIcon;
  final String emojiLabel;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: SushiDeco.card(selected: _hovered),
          child: Material(
            color: SushiColors.white,
            borderRadius: BorderRadius.circular(SushiRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(SushiRadius.xl),
              splashColor: SushiColors.redPale,
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(SushiSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconBadge(widget.icon),
                    const SizedBox(height: SushiSpace.sm),
                    Text(
                      widget.title,
                      style: SushiTypo.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SushiSpace.xs),
                    Text(
                      widget.description,
                      style: SushiTypo.bodySm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SushiSpace.md),
                    Row(
                      children: [
                        Icon(widget.emojiIcon, color: SushiColors.red, size: 18),
                        const SizedBox(width: SushiSpace.sm),
                        Text(widget.emojiLabel, style: SushiTypo.bodySm),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: SushiColors.inkMid,
                        ),
                      ],
                    ),
                  ],
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
      alignment: Alignment.center,
      decoration: SushiDeco.badge(bg: SushiColors.redSurface),
      child: Icon(icon, color: SushiColors.red, size: 18),
    );
  }
}
