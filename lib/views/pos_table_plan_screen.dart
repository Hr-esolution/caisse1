import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/table_plan_layout.dart';
import '../controllers/pos_controller.dart';
import '../models/pos_table.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';

class PosTablePlanScreen extends StatefulWidget {
  const PosTablePlanScreen({super.key});

  @override
  State<PosTablePlanScreen> createState() => _PosTablePlanScreenState();
}

class _PosTablePlanScreenState extends State<PosTablePlanScreen> {
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    final current = normalizeTableName(Get.find<PosController>().tableNumber);
    _selectedTable = kTablePlanSlotsByNumber.containsKey(current)
        ? current
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Plan des Tables'),
        leading: const AppBackButton(iconColor: Colors.white),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => Get.offAllNamed('/pos-choice'),
            child: const Text('Retour'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackdrop()),
          Positioned.fill(
            child: GetBuilder<PosController>(
              builder: (_) {
                if (pos.tables.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mapped = <_MappedTable>[];
                final seenNumbers = <String>{};
                var outOfPlanCount = 0;
                for (final table in pos.tables) {
                  final normalized = normalizeTableName(table.number);
                  final slot = kTablePlanSlotsByNumber[normalized];
                  if (slot == null || seenNumbers.contains(normalized)) {
                    outOfPlanCount += 1;
                    continue;
                  }
                  seenNumbers.add(normalized);
                  mapped.add(_MappedTable(slot: slot, table: table));
                }

                mapped.sort((a, b) {
                  final rowCmp = a.slot.row.compareTo(b.slot.row);
                  if (rowCmp != 0) return rowCmp;
                  return a.slot.col.compareTo(b.slot.col);
                });

                final activeSelection = _resolveSelection(
                  mappedNumbers: seenNumbers,
                  currentFromController: normalizeTableName(pos.tableNumber),
                );

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xC4091237),
                          border: Border.all(
                            color: const Color(0xFF1F2A60).withAlpha(180),
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
                            _header(
                              pos: pos,
                              selectedTable: activeSelection,
                              canContinue: activeSelection != null,
                              outOfPlanCount: outOfPlanCount,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: GlassThemeData.glassContainerLight(
                                  borderWidth: 1.4,
                                  borderColor: GlassColors.sushi.withAlpha(140),
                                  shadows: [
                                    BoxShadow(
                                      color: GlassColors.redAccent.withAlpha(
                                        20,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _FloorGridPainter(
                                              gridColor: const Color(
                                                0xFF213366,
                                              ).withAlpha(72),
                                            ),
                                          ),
                                        ),
                                        ...mapped.map(
                                          (entry) => _positionedTable(
                                            constraints: constraints,
                                            entry: entry,
                                            isSelected:
                                                activeSelection ==
                                                normalizeTableName(
                                                  entry.table.number,
                                                ),
                                            onTap: () =>
                                                _onTableTap(pos, entry.table),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveSelection({
    required Set<String> mappedNumbers,
    required String currentFromController,
  }) {
    if (_selectedTable != null && mappedNumbers.contains(_selectedTable)) {
      return _selectedTable;
    }
    if (mappedNumbers.contains(currentFromController)) {
      _selectedTable = currentFromController;
      return currentFromController;
    }
    return null;
  }

  Widget _buildBackdrop() {
    return const SizedBox.expand(); // Laisse voir l'image de fond globale
  }

  Widget _header({
    required PosController pos,
    required String? selectedTable,
    required bool canContinue,
    required int outOfPlanCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;
        final titleSize = compact ? 32.0 : 42.0;
        final subtitleSize = compact ? 20.0 : 28.0;
        final actionPanel = Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _legend(),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: canContinue
                    ? () {
                        if (selectedTable == null) return;
                        final slot = kTablePlanSlotsByNumber[selectedTable];
                        if (slot == null) return;
                        Get.find<PosController>().setTableNumber(
                          slot.tableNumber,
                        );
                        Get.toNamed('/pos-order');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E1230),
                  disabledForegroundColor: const Color(0xFF68729A),
                  backgroundColor: const Color(0xFFF9D66B),
                  disabledBackgroundColor: const Color(0xAA7A6A46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: const Text(
                  'Suivant',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerText(
                      pos: pos,
                      outOfPlanCount: outOfPlanCount,
                      titleSize: titleSize,
                      subtitleSize: subtitleSize,
                    ),
                    const SizedBox(height: 12),
                    actionPanel,
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _headerText(
                        pos: pos,
                        outOfPlanCount: outOfPlanCount,
                        titleSize: titleSize,
                        subtitleSize: subtitleSize,
                      ),
                    ),
                    actionPanel,
                  ],
                ),
        );
      },
    );
  }

  Widget _headerText({
    required PosController pos,
    required int outOfPlanCount,
    required double titleSize,
    required double subtitleSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan des Tables',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE43657),
            height: 0.95,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pos.restaurantLabel,
          style: TextStyle(
            fontSize: subtitleSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (outOfPlanCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'tables hors plan: $outOfPlanCount',
            style: const TextStyle(
              color: Color(0xB3BBC9F3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x88212A54),
        border: Border.all(color: const Color(0x993A4678)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: Color(0xFF31FF67), label: 'Disponible'),
          SizedBox(width: 14),
          _LegendDot(color: Color(0xFFFFC62A), label: 'Réservée'),
          SizedBox(width: 14),
          _LegendDot(color: Color(0xFFFF2D5E), label: 'Occupée'),
        ],
      ),
    );
  }

  Widget _positionedTable({
    required BoxConstraints constraints,
    required _MappedTable entry,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const colGap = 14.0;
    const rowGap = 16.0;

    final rawCellW =
        (constraints.maxWidth - ((kPlanCols - 1) * colGap)) / kPlanCols;
    final rawCellH =
        (constraints.maxHeight - ((kPlanRows - 1) * rowGap)) / kPlanRows;

    final tileW = rawCellW.clamp(62.0, 124.0).toDouble();
    final tileH = rawCellH.clamp(48.0, 90.0).toDouble();

    final left =
        (entry.slot.col * (rawCellW + colGap)) + ((rawCellW - tileW) / 2);
    final top =
        (entry.slot.row * (rawCellH + rowGap)) + ((rawCellH - tileH) / 2);

    return Positioned(
      left: left,
      top: top,
      width: tileW,
      height: tileH,
      child: _NeonTableTile(
        table: entry.table,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _onTableTap(PosController pos, PosTable table) {
    final status = table.status;
    final isAvailable = status == 'available' || status == 'free';
    if (!isAvailable) {
      final message = status == 'reserved'
          ? 'Cette table est réservée'
          : 'Cette table est occupée';
      final snackBar = SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }

    final normalized = normalizeTableName(table.number);
    setState(() => _selectedTable = normalized);
    pos.setTableNumber(table.number);
    Get.toNamed('/pos-order');
  }
}

class _MappedTable {
  final TablePlanSlot slot;
  final PosTable table;

  const _MappedTable({required this.slot, required this.table});
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withAlpha(180), blurRadius: 12)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE5ECFF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NeonTableTile extends StatefulWidget {
  const _NeonTableTile({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  final PosTable table;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NeonTableTile> createState() => _NeonTableTileState();
}

class _NeonTableTileState extends State<_NeonTableTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.table.status;
    final isFree = status == 'available' || status == 'free';
    final isReserved = status == 'reserved';
    final neon = isFree
        ? const Color(0xFF31FF67)
        : isReserved
        ? const Color(0xFFFFC62A)
        : const Color(0xFFFF2D5E);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: _hovered || widget.isSelected ? 1.02 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: neon.withAlpha(widget.isSelected || _hovered ? 245 : 190),
              width: widget.isSelected ? 2.2 : 1.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                neon.withAlpha(widget.isSelected ? 70 : 38),
                const Color(0xFF1B1E37).withAlpha(130),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: neon.withAlpha(widget.isSelected ? 130 : 90),
                blurRadius: widget.isSelected || _hovered ? 20 : 14,
                offset: const Offset(0, -4),
              ),
              const BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashColor: const Color(0x4DE85D2D),
              highlightColor: neon.withAlpha(36),
              onTap: widget.onTap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final base = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final fontSize = (base * 0.38).clamp(14.0, 28.0).toDouble();
                  return Center(
                    child: Text(
                      widget.table.number,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: neon,
                        shadows: [
                          Shadow(color: neon.withAlpha(180), blurRadius: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloorGridPainter extends CustomPainter {
  _FloorGridPainter({required this.gridColor});

  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int col = 1; col < kPlanCols; col++) {
      final x = (size.width / kPlanCols) * col;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int row = 1; row < kPlanRows; row++) {
      final y = (size.height / kPlanRows) * row;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloorGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor;
  }
}

// ignore: unused_element
class _NeonBackdropPainter extends CustomPainter {
  _NeonBackdropPainter({required this.colorA, required this.colorB});

  final Color colorA;
  final Color colorB;

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = colorA
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double y = 22; y <= size.height; y += 84) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 20) {
        final wave = math.sin((x / 80) + (y / 140)) * 6;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, wavePaint);
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [colorB.withAlpha(130), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.45),
              radius: size.shortestSide * 0.25,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.shortestSide * 0.25,
      glowPaint,
    );

    final sideGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [colorA.withAlpha(95), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.78, size.height * 0.55),
              radius: size.shortestSide * 0.22,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.55),
      size.shortestSide * 0.22,
      sideGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _NeonBackdropPainter oldDelegate) {
    return oldDelegate.colorA != colorA || oldDelegate.colorB != colorB;
  }
}
