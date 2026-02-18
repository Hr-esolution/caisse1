import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import '../controllers/category_controller.dart';
import '../controllers/pos_controller.dart';
import '../data/app_constants.dart';
import '../models/product_model.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../theme/app_theme.dart';
import '../utils/image_resolver_shared.dart';
import '../utils/image_resolver.dart';
import '../services/database_service.dart';
import '../utils/pos_ticket_printer.dart';
import '../widgets/app_back_button.dart';
import '../services/image_cache_service.dart';
import '../services/app_settings_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.title});
  final String title;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.imageBuilder,
  });

  final Product product;
  final VoidCallback onTap;
  final Widget Function(String? path) imageBuilder;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.blancPur.withAlpha(215),
            border: Border.all(
              color: _hovered ? AppColors.deepTeal : AppColors.grisLeger,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: _hovered ? 12 : 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(14),
              splashColor: AppColors.terraCotta.withAlpha(77),
              highlightColor: AppColors.deepTeal.withAlpha(25),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.imageBuilder(product.image),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      product.name,
                      style: AppTypography.headline2.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppSettingsService.instance.formatAmount(
                            product.price,
                          ),
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.deepTeal.withAlpha(35),
                                AppColors.livingCoral.withAlpha(35),
                              ],
                            ),
                          ),
                          child: const Text(
                            'Disponible',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepTeal,
                            ),
                          ),
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
}

class _GradientSpinner extends StatefulWidget {
  const _GradientSpinner({required this.size, required this.strokeWidth});

  final double size;
  final double strokeWidth;

  @override
  State<_GradientSpinner> createState() => _GradientSpinnerState();
}

class _GradientSpinnerState extends State<_GradientSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepTeal, AppColors.livingCoral],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcIn,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: widget.strokeWidth,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PulseSkeleton extends StatefulWidget {
  const _PulseSkeleton({required this.borderRadius});

  final double borderRadius;

  @override
  State<_PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<_PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final color = Color.lerp(
          AppColors.grisLeger.withAlpha(190),
          AppColors.grisPale.withAlpha(245),
          t,
        );
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class _SushiPatternPainter extends CustomPainter {
  _SushiPatternPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (double y = 40; y < size.height; y += 110) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        final wave = math.sin((x / 60) + (y / 90)) * 5;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()..color = lineColor.withAlpha(85);
    for (double x = 36; x < size.width; x += 140) {
      for (double y = 28; y < size.height; y += 140) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SushiPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _PosScreenState extends State<PosScreen> {
  final categoryController = Get.find<CategoryController>();
  final posController = Get.find<PosController>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _tableController = TextEditingController();

  String _money(double amount) =>
      AppSettingsService.instance.formatAmount(amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.charbon,
        elevation: 0,
        leading: const AppBackButton(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xD6F5F3F0), Color(0xC9E8E6E1)],
            ),
            border: Border(
              bottom: BorderSide(color: AppColors.grisLeger, width: 1),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Get.offAllNamed('/home'),
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: const Text('Quitter'),
            style: TextButton.styleFrom(foregroundColor: AppColors.terraCotta),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildPosBackground()),
          Positioned.fill(
            child: GetBuilder<PosController>(
              builder: (pos) {
                if (pos.isLocked) {
                  return _buildLockScreen(pos);
                }
                return GetBuilder<CategoryController>(
                  builder: (category) {
                    if (!category.isLoaded.value) {
                      return const Center(
                        child: _GradientSpinner(size: 38, strokeWidth: 3),
                      );
                    }

                    var selectedCategory = category.selectedCategory.value;
                    if (selectedCategory == null &&
                        category.categories.isNotEmpty) {
                      selectedCategory = category.categories.first;
                    }

                    var products = selectedCategory != null
                        ? category.products
                        : <Product>[];

                    // Filtre recherche live
                    products = pos.filterProductsBySearch(products);

                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 16,
                            child: Column(
                              children: [
                                _topMenu(
                                  title:
                                      'POS - ${pos.activeStaff?.name ?? 'Serveur'}',
                                  subTitle:
                                      '${DateTime.now().toString().split(' ')[0]} • ${_labelForFulfillment(pos.fulfillmentType)}',
                                  action: _topRightStats(pos),
                                ),
                                _orderInfoBar(pos),
                                Container(
                                  height: 72,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: TextField(
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            hintText:
                                                'Rechercher un produit...',
                                            filled: true,
                                            fillColor: AppColors.blancPur,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.md,
                                                  vertical: AppSpacing.sm,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.grisLeger,
                                              ),
                                            ),
                                          ),
                                          onChanged: pos.setSearchTerm,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        flex: 6,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: category.categories.length,
                                          itemBuilder: (context, index) {
                                            final cat =
                                                category.categories[index];
                                            if (cat.isDeleted) {
                                              return const SizedBox.shrink();
                                            }
                                            final isActive =
                                                category
                                                    .selectedCategory
                                                    .value
                                                    ?.id ==
                                                cat.id;
                                            return GestureDetector(
                                              onTap: () =>
                                                  category.selectCategory(cat),
                                              child: _itemTab(
                                                icon:
                                                    Icons.lunch_dining_outlined,
                                                title: cat.name,
                                                isActive: isActive,
                                                imagePath: cat.image,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        const crossAxisCount = 5;
                                        return GridView.builder(
                                          itemCount: products.length,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                childAspectRatio: 1.1,
                                                crossAxisSpacing: AppSpacing.md,
                                                mainAxisSpacing: AppSpacing.md,
                                              ),
                                          itemBuilder: (context, index) {
                                            final product = products[index];
                                            return TweenAnimationBuilder<
                                              double
                                            >(
                                              tween: Tween(begin: 0, end: 1),
                                              duration: Duration(
                                                milliseconds:
                                                    220 + (index % 8) * 50,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              builder: (context, value, child) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    (1 - value) * 12,
                                                  ),
                                                  child: Opacity(
                                                    opacity: value.clamp(0, 1),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: _dynamicItem(
                                                product: product,
                                                onTap: () =>
                                                    pos.addToCart(product),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: AppColors.blancPur.withAlpha(180),
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
                                    children: [
                                      _topMenu(
                                        title: 'Commande',
                                        subTitle: pos.tableNumber == null
                                            ? 'Table : -'
                                            : 'Table : ${pos.tableNumber}',
                                        action: _orderActions(pos),
                                      ),
                                      if (pos.error != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                          ),
                                          child: Text(
                                            pos.error!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: AppSpacing.md),
                                      Expanded(child: _cartList(pos)),
                                      _summaryPanel(pos),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  Widget _buildLockScreen(PosController pos) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.blancPur.withAlpha(170),
              border: Border.all(
                color: AppColors.blancPur.withAlpha(135),
                width: 1.2,
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
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepTeal.withAlpha(200),
                        AppColors.terraCotta.withAlpha(200),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.lock, size: 28, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Entrer le code PIN',
                  style: AppTypography.headline2,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (pos.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(pos.error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: AppSpacing.md),
                _actionButton(
                  icon: Icons.lock_open,
                  label: 'Déverrouiller',
                  onPressed: () async {
                    final pin = _pinController.text.trim();
                    await pos.unlockWithPin(pin);
                    _pinController.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepTeal.withAlpha(20),
            AppColors.offWhite,
            AppColors.livingCoral.withAlpha(30),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SushiPatternPainter(
                lineColor: AppColors.deepTeal.withAlpha(24),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: _backgroundGlow(AppColors.deepTeal.withAlpha(25), 260),
          ),
          Positioned(
            right: -70,
            bottom: -90,
            child: _backgroundGlow(AppColors.livingCoral.withAlpha(30), 240),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 24),
          ],
        ),
      ),
    );
  }

  Widget _dynamicItem({required Product product, required VoidCallback onTap}) {
    return _ProductCard(
      product: product,
      onTap: onTap,
      imageBuilder: _buildProductImage,
    );
  }

  Widget _cartList(PosController pos) {
    if (pos.cart.isEmpty) {
      return const Center(
        child: Text('Panier vide', style: AppTypography.bodyLarge),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: pos.cart.length,
      itemBuilder: (context, index) {
        final item = pos.cart[index];
        return Dismissible(
          key: ValueKey('cart-${item.product.id}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _promptQuantity(pos, item);
              return false;
            }
            pos.setCartItemQuantity(item.product, 0);
            return true;
          },
          background: _swipeAction(
            icon: Icons.edit_outlined,
            label: 'Modifier',
            color: AppColors.deepTeal,
            alignLeft: true,
          ),
          secondaryBackground: _swipeAction(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: AppColors.terraCotta,
            alignLeft: false,
          ),
          child: _cartLineItem(pos, item),
        );
      },
    );
  }

  Widget _summaryPanel(PosController pos) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.offWhite.withAlpha(242),
            AppColors.deepTeal.withAlpha(12),
          ],
        ),
        border: Border.all(color: AppColors.grisLeger),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryRow(label: 'Sous-total', value: _money(pos.total)),
          const SizedBox(height: AppSpacing.sm),
          _summaryRow(label: 'Paiement', value: pos.paymentMethod ?? '-'),
          const SizedBox(height: AppSpacing.lg),
          _actionButton(
            icon: Icons.check,
            label: pos.editingOrderId == null
                ? 'Enregistrer la commande'
                : 'Modifier la commande',
            onPressed: () async {
              if (pos.isCreatingOrder) return;
              if (pos.fulfillmentType == 'on_site' &&
                  (pos.tableNumber == null || pos.tableNumber!.isEmpty)) {
                await _promptTableNumber(pos);
                return;
              }
              final orderId = await pos.createOrder();
              if (orderId != null && pos.fulfillmentType == 'on_site') {
                await pos.markTableOccupied(pos.tableNumber!);
              }
              if (orderId != null) {
                await _autoPrintKitchenAndCustomerByOrderId(orderId);
                pos.lock();
                if (mounted) Get.offAllNamed('/pos');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _orderActions(PosController pos) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          TextButton.icon(
            onPressed: () => _selectFulfillment(pos),
            icon: const Icon(Icons.local_dining_outlined, size: 16),
            label: const Text('Type'),
          ),
          if (pos.fulfillmentType == 'on_site')
            TextButton.icon(
              onPressed: () => _promptTableNumber(pos),
              icon: const Icon(Icons.table_restaurant_outlined, size: 16),
              label: const Text('Table'),
            ),
          TextButton.icon(
            onPressed: () => _promptCustomerInfo(pos),
            icon: const Icon(Icons.person_outline, size: 16),
            label: const Text('Client'),
          ),
          TextButton.icon(
            onPressed: () => _selectPaymentMethod(pos),
            icon: const Icon(Icons.payments_outlined, size: 16),
            label: const Text('Paiement'),
          ),
          TextButton.icon(
            onPressed: () => _showOrdersDialog(pos),
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: const Text('Commandes'),
          ),
          TextButton.icon(
            onPressed: () {
              pos.lock();
              Get.offAllNamed('/pos');
            },
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Verrouiller'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFulfillment(PosController pos) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Type de commande'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'on_site'),
              child: const Text('Sur place'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'pickup'),
              child: const Text('À emporter'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'delivery'),
              child: const Text('Livraison'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      pos.setFulfillmentType(selected);
    }
  }

  Future<void> _promptTableNumber(PosController pos) async {
    _tableController.text = pos.tableNumber ?? '';
    final table = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Numéro de table'),
          content: TextField(
            controller: _tableController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(labelText: 'Table'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _tableController.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (table != null && table.isNotEmpty) {
      pos.setTableNumber(table);
    }
  }

  Future<void> _showOrdersDialog(PosController pos) async {
    await pos.loadOrdersToday();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Commandes du jour'),
          content: SizedBox(
            width: 520,
            child: pos.ordersToday.isEmpty
                ? const Text('Aucune commande')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _filterChip(pos, 'all', 'Toutes'),
                          _filterChip(pos, 'pending', 'En attente'),
                          _filterChip(pos, 'preparing', 'Préparation'),
                          _filterChip(pos, 'ready', 'Prête'),
                          _filterChip(pos, 'paid', 'Payée'),
                          _filterChip(pos, 'cancelled', 'Annulée'),
                          ActionChip(
                            label: const Text('Historique'),
                            onPressed: () async {
                              await _showHistoryDialog(pos);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final order in pos.ordersToday)
                        ListTile(
                          title: Text(
                            'Commande #${order.id} • ${_labelForFulfillment(order.fulfillmentType)}',
                          ),
                          subtitle: Text(
                            'Total: ${_money(order.totalPrice)} • Statut: ${order.status}',
                          ),
                          trailing: order.paymentStatus == 'paid'
                              ? const Text('Payée')
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        await _showOrderDetails(pos, order);
                                      },
                                      child: const Text('Détails'),
                                    ),
                                    if (pos.canEditOrders &&
                                        order.status == 'pending')
                                      TextButton(
                                        onPressed: () async {
                                          await _showEditOrderDialog(
                                            pos,
                                            order,
                                          );
                                          if (mounted) Get.back();
                                        },
                                        child: const Text('Edit order'),
                                      ),
                                    if (pos.canEditOrders &&
                                        order.status == 'pending')
                                      TextButton(
                                        onPressed: () async {
                                          await pos.loadOrderForEdit(order);
                                          if (mounted) Get.back();
                                        },
                                        child: const Text('Modifier'),
                                      ),
                                    TextButton(
                                      onPressed: () async {
                                        final ok = await pos.markOrderPaid(
                                          order,
                                        );
                                        if (!ok && mounted) {
                                          Get.snackbar(
                                            'Erreur backend',
                                            pos.error ??
                                                'Commande locale mise à jour, notification backend échouée.',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        }
                                        if (mounted) Get.back();
                                      },
                                      child: const Text('Marquer payée'),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(PosController pos, String value, String label) {
    final selected = pos.ordersFilter == value;
    return FilterChip(
      selected: selected,
      label: Text(label),
      selectedColor: AppColors.deepTeal.withAlpha(40),
      checkmarkColor: AppColors.deepTeal,
      side: BorderSide(
        color: selected ? AppColors.deepTeal : AppColors.grisLeger,
      ),
      onSelected: (_) => pos.setOrdersFilter(value),
    );
  }

  Future<void> _promptQuantity(PosController pos, CartItem item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quantité'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantité'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final qty = int.tryParse(controller.text.trim());
                Navigator.pop(context, qty);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      pos.setCartItemQuantity(item.product, result);
    }
  }

  Future<void> _showOrderDetails(PosController pos, PosOrder order) async {
    final items = await DatabaseService.getPosOrderItems(order.id);
    if (!mounted) return;
    final statusColor = _orderStatusColor(order.status);
    final locationLabel = order.fulfillmentType == 'on_site'
        ? 'Table'
        : 'Adresse';
    final locationValue = order.fulfillmentType == 'on_site'
        ? (order.tableNumber?.trim().isEmpty ?? true
              ? '-'
              : order.tableNumber!.trim())
        : (order.deliveryAddress?.trim().isEmpty ?? true
              ? '-'
              : order.deliveryAddress!.trim());
    final cancelReason = order.cancelReason?.trim().isEmpty ?? true
        ? '-'
        : order.cancelReason!.trim();

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blancPur,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withAlpha(85)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor.withAlpha(34),
                          AppColors.cloudDancer,
                          AppColors.livingCoral.withAlpha(26),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commande #${order.id}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.charbon,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _statusBadge(
                                    Icons.flag_outlined,
                                    _labelForOrderStatus(order.status),
                                  ),
                                  _statusBadge(
                                    Icons.phone_android_outlined,
                                    _labelForChannel(order.channel),
                                  ),
                                  _statusBadge(
                                    Icons.local_shipping_outlined,
                                    _labelForFulfillment(order.fulfillmentType),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blancPur.withAlpha(220),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.deepTeal.withAlpha(72),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grisModerne,
                                ),
                              ),
                              Text(
                                _money(order.totalPrice),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _orderDetailsInfoCard(
                                icon: Icons.person_outline,
                                label: 'Client',
                                value: order.customerName ?? '-',
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.call_outlined,
                                label: 'Téléphone',
                                value: order.customerPhone ?? '-',
                              ),
                              _orderDetailsInfoCard(
                                icon: order.fulfillmentType == 'on_site'
                                    ? Icons.table_bar_outlined
                                    : Icons.location_on_outlined,
                                label: locationLabel,
                                value: locationValue,
                              ),
                              _orderDetailsInfoCard(
                                icon: Icons.event_note_outlined,
                                label: 'Annulation',
                                value: cancelReason,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Articles (${items.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charbon,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (items.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cloudDancer.withAlpha(180),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Aucun article trouvé pour cette commande.',
                                style: AppTypography.bodySmall,
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final it in items)
                                  _orderDetailsItemCard(it),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.cloudDancer.withAlpha(150),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await pos.updateOrderStatus(
                              order,
                              'preparing',
                            );
                            if (_isMobileApi(order)) {
                              final items =
                                  await DatabaseService.getPosOrderItems(
                                    order.id,
                                  );
                              await _printKitchenAndCustomerTickets(
                                order,
                                items,
                              );
                            }
                            if (!ok && mounted) {
                              Get.snackbar(
                                'Erreur backend',
                                pos.error ??
                                    'Commande locale mise à jour, notification backend échouée.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          icon: const Icon(
                            Icons.soup_kitchen_outlined,
                            size: 16,
                          ),
                          label: const Text('Préparation'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await pos.updateOrderStatus(
                              order,
                              'ready',
                            );
                            if (!ok && mounted) {
                              Get.snackbar(
                                'Erreur backend',
                                pos.error ??
                                    'Commande locale mise à jour, notification backend échouée.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Prête'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _showPrintTicket(order, items);
                          },
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                          ),
                          label: const Text('Ticket'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _printTicket(order, items);
                          },
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('Imprimer'),
                        ),
                        if (pos.canEditOrders && order.status == 'pending')
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showEditOrderDialog(pos, order);
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Editer'),
                          ),
                        if (pos.canModifyOrders && order.status == 'pending')
                          OutlinedButton.icon(
                            onPressed: () async {
                              final reason = await _promptCancelReason();
                              if (reason == null) return;
                              final ok = await pos.cancelOrder(
                                order,
                                reason: reason,
                              );
                              if (!ok && mounted) {
                                Get.snackbar(
                                  'Erreur backend',
                                  pos.error ??
                                      'Commande locale mise à jour, notification backend échouée.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Annuler'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                        if (pos.canModifyOrders)
                          OutlinedButton.icon(
                            onPressed: () async {
                              await pos.deleteOrder(order);
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Supprimer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, size: 17),
                          label: const Text('Fermer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPrintTicket(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('=== TICKET CAISSE ===');
    buffer.writeln('Commande #${order.id}');
    buffer.writeln('Type : ${_labelForFulfillment(order.fulfillmentType)}');
    buffer.writeln('Table : ${order.tableNumber ?? '-'}');
    buffer.writeln('Client : ${order.customerName ?? '-'}');
    buffer.writeln('Téléphone : ${order.customerPhone ?? '-'}');
    if (order.deliveryAddress != null) {
      buffer.writeln('Adresse: ${order.deliveryAddress}');
    }
    buffer.writeln('------------------');
    for (final it in items) {
      buffer.writeln(
        '${it.quantity} x ${it.productName} @ ${_money(it.unitPrice)}',
      );
    }
    buffer.writeln('------------------');
    buffer.writeln('Total: ${_money(order.totalPrice)}');

    final ticketText = buffer.toString();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ticket (local)'),
          content: SizedBox(width: 520, child: SelectableText(ticketText)),
          actions: [
            TextButton(
              onPressed: () async {
                if (!mounted) return;
                await Clipboard.setData(ClipboardData(text: ticketText));
                if (!mounted) return;
                Get.back();
              },
              child: const Text('Copier'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printTicket(PosOrder order, List<PosOrderItem> items) async {
    await Printing.layoutPdf(
      onLayout: (format) => buildTicketPdf(order, items, format: format),
    );
  }

  Future<void> _autoPrintKitchenAndCustomerByOrderId(int orderId) async {
    final order = await DatabaseService.getPosOrderById(orderId);
    if (order == null) return;
    final items = await DatabaseService.getPosOrderItems(orderId);
    if (items.isEmpty) return;
    await _printKitchenAndCustomerTickets(order, items);
  }

  Future<void> _printKitchenAndCustomerTickets(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) =>
            buildKitchenAndCustomerTicketsPdf(order, items, format: format),
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Impression',
        'Impossible d\'imprimer les tickets: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool _isMobileApi(PosOrder order) {
    return order.channel.trim().toLowerCase() == 'api';
  }

  Future<String?> _promptCancelReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Motif annulation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Motif'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return null;
    return reason;
  }

  Future<void> _showEditOrderDialog(PosController pos, PosOrder order) async {
    String selectedType = order.fulfillmentType;
    final tableController = TextEditingController(
      text: order.tableNumber ?? '',
    );
    final nameController = TextEditingController(
      text: order.customerName ?? '',
    );
    final phoneController = TextEditingController(
      text: order.customerPhone ?? '',
    );
    final addressController = TextEditingController(
      text: order.deliveryAddress ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text('Edit order #${order.id}'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'on_site',
                            child: Text('Sur place'),
                          ),
                          DropdownMenuItem(
                            value: 'pickup',
                            child: Text('A emporter'),
                          ),
                          DropdownMenuItem(
                            value: 'delivery',
                            child: Text('Livraison'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedType = value);
                        },
                      ),
                      if (selectedType == 'on_site')
                        TextField(
                          controller: tableController,
                          decoration: const InputDecoration(labelText: 'Table'),
                        ),
                      if (selectedType == 'pickup' ||
                          selectedType == 'delivery')
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom client',
                          ),
                        ),
                      if (selectedType == 'pickup' ||
                          selectedType == 'delivery')
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telephone',
                          ),
                        ),
                      if (selectedType == 'delivery')
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse livraison',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await pos.editOrderDetails(
                      order,
                      fulfillmentType: selectedType,
                      tableNumber: tableController.text,
                      customerName: nameController.text,
                      customerPhone: phoneController.text,
                      deliveryAddress: addressController.text,
                    );
                    if (!mounted) return;
                    if (!ok) {
                      Get.snackbar(
                        'Erreur',
                        pos.error ?? 'Modification impossible',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    if (!mounted) return;
                    Get.back();
                    Get.snackbar(
                      'Succes',
                      'Commande mise a jour',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showHistoryDialog(PosController pos) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final start = DateTime(picked.year, picked.month, picked.day);
    final end = start.add(const Duration(days: 1));
    final orders = await DatabaseService.getPosOrdersByDateRange(start, end);
    if (!mounted) return;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Historique ${picked.toString().split(' ')[0]}'),
          content: SizedBox(
            width: 520,
            child: orders.isEmpty
                ? const Text('Aucune commande')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final order in orders)
                        ListTile(
                          title: Text('Commande #${order.id}'),
                          subtitle: Text(
                            'Total: ${_money(order.totalPrice)} • Statut: ${order.status}',
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              await _showOrderDetails(pos, order);
                            },
                            child: const Text('Détails'),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _orderDetailsInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cloudDancer.withAlpha(170),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grisLeger.withAlpha(180)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.deepTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charbon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderDetailsItemCard(PosOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.blancPur.withAlpha(235),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grisLeger.withAlpha(170)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.productName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charbon,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.quantity} x ${_money(item.unitPrice)}',
            style: const TextStyle(fontSize: 12, color: AppColors.grisModerne),
          ),
          const SizedBox(width: 10),
          Text(
            _money(item.quantity * item.unitPrice),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.deepTeal,
            ),
          ),
        ],
      ),
    );
  }

  String _labelForOrderStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'preparing':
        return 'Préparation';
      case 'ready':
        return 'Prête';
      case 'paid':
        return 'Payée';
      case 'cancelled':
        return 'Annulée';
      default:
        return value;
    }
  }

  Color _orderStatusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'preparing':
        return Colors.blue.shade700;
      case 'ready':
        return Colors.green.shade700;
      case 'paid':
        return Colors.teal.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return AppColors.deepTeal;
    }
  }

  String _labelForChannel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'api':
        return 'Mobile API';
      case 'web':
        return 'Web';
      case 'kiosk':
        return 'Kiosk';
      case 'pos':
      default:
        return 'POS';
    }
  }

  Widget _topRightStats(PosController pos) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusBadge(
          Icons.point_of_sale_outlined,
          'CA ${_money(pos.ordersToday.fold<double>(0.0, (s, o) => s + o.totalPrice))}',
        ),
        const SizedBox(width: AppSpacing.md),
        TextButton.icon(
          onPressed: () {
            pos.lock();
            Get.offAllNamed('/pos');
          },
          icon: const Icon(Icons.lock, size: 16),
          label: const Text('Verrouiller'),
        ),
      ],
    );
  }

  Widget _orderInfoBar(PosController pos) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.blancPur.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grisLeger),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _statusBadge(
            Icons.receipt_outlined,
            _labelForFulfillment(pos.fulfillmentType),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Table : ${pos.tableNumber ?? '-'}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Client : ${pos.customerName ?? '-'}',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            AppColors.deepTeal.withAlpha(42),
            AppColors.livingCoral.withAlpha(32),
          ],
        ),
        border: Border.all(color: AppColors.deepTeal.withAlpha(36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.deepTeal),
          const SizedBox(width: AppSpacing.xs),
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
    );
  }

  Widget _swipeAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool alignLeft,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withAlpha(46),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisAlignment: alignLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartLineItem(PosController pos, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.blancPur.withAlpha(220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grisLeger),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.product.name}\n${_money(item.product.price)}',
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => pos.removeFromCart(item.product),
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => pos.addToCart(item.product),
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _money(item.lineTotal),
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptCustomerInfo(PosController pos) async {
    final nameController = TextEditingController(text: pos.customerName ?? '');
    final phoneController = TextEditingController(
      text: pos.customerPhone ?? '',
    );
    final addressController = TextEditingController(
      text: pos.deliveryAddress ?? '',
    );
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Infos client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                if (pos.fulfillmentType == 'delivery')
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                pos.setCustomerInfo(
                  name: nameController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectPaymentMethod(PosController pos) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Mode de paiement'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'cash'),
              child: const Text('Espèces'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'card'),
              child: const Text('Carte'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'other'),
              child: const Text('Autre'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      pos.setPaymentMethod(selected);
    }
  }

  String _labelForFulfillment(String value) {
    switch (value) {
      case 'delivery':
        return 'Livraison';
      case 'pickup':
        return 'À emporter';
      case 'on_site':
      default:
        return 'Sur place';
    }
  }

  Widget _itemTab({
    required IconData icon,
    required String title,
    required bool isActive,
    String? imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive
            ? AppColors.deepTeal.withAlpha(24)
            : AppColors.blancPur.withAlpha(170),
        border: Border.all(
          color: isActive ? AppColors.deepTeal : AppColors.grisLeger,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (imagePath != null && imagePath.isNotEmpty)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.cloudDancer,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildCategoryImage(imagePath, icon),
              ),
            )
          else
            Icon(
              icon,
              color: isActive ? AppColors.deepTeal : AppColors.grisModerne,
              size: 20,
            ),
          const SizedBox(width: AppSpacing.md),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.deepTeal : AppColors.grisModerne,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    return _imageFromPath(
      imagePath,
      placeholder: _imagePlaceholder(),
      loadingWidget: _imageSkeleton(),
    );
  }

  Widget _buildCategoryImage(String imagePath, IconData fallbackIcon) {
    return _imageFromPath(
      imagePath,
      placeholder: Icon(fallbackIcon, color: AppColors.terraCotta, size: 36),
      errorWidget: Icon(fallbackIcon, color: AppColors.terraCotta, size: 36),
      loadingWidget: _imageSkeleton(),
    );
  }

  String? _networkUrl(String? path) {
    final normalized = normalizeImagePath(path, baseUrl: AppConstant.baseUrl);
    if (normalized == null) return null;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return null;
  }

  Widget _imageFromPath(
    String? path, {
    required Widget placeholder,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    final url = _networkUrl(path);
    if (url != null) {
      final cachedPath = ImageCacheService.instance.cachedFilePathForUrlSync(
        url,
      );
      if (cachedPath != null) {
        return Image.file(
          File(cachedPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? placeholder;
          },
        );
      }
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, progress) => loadingWidget ?? _imageLoader(),
        errorWidget: (context, error, stackTrace) => errorWidget ?? placeholder,
      );
    }

    final imageProvider = resolveImageProvider(
      path,
      baseUrl: AppConstant.baseUrl,
    );
    if (imageProvider == null) {
      return placeholder;
    }
    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? placeholder;
      },
    );
  }

  Widget _imageLoader() {
    return const Center(child: _GradientSpinner(size: 24, strokeWidth: 2));
  }

  Widget _imageSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xs),
      child: _PulseSkeleton(borderRadius: 10),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloudDancer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.grisModerne.withAlpha(180),
        size: 40,
      ),
    );
  }

  Widget _topMenu({
    required String title,
    required String subTitle,
    required Widget action,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blancPur.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grisLeger),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline1),
                const SizedBox(height: AppSpacing.xs),
                Text(subTitle, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(child: action),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charbon,
                  fontSize: 14,
                )
              : AppTypography.bodyLarge,
        ),
        Text(
          value,
          style: isTotal
              ? const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.terraCotta,
                  fontSize: 16,
                )
              : const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.charbon,
                  fontSize: 14,
                ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final pos = Get.find<PosController>();
    final busy = pos.isCreatingOrder;
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.deepTeal, AppColors.burntOrange],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.terraCotta.withAlpha(77),
            highlightColor: AppColors.deepTeal.withAlpha(45),
            onTap: busy ? null : onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Enregistrement...',
                    style: AppTypography.button,
                    maxLines: 1,
                  ),
                ] else ...[
                  Icon(icon, size: 17, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.button,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
