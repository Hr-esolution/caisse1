import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/pos_order.dart';
import '../models/user.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/sushi_design.dart';
import '../widgets/admin_shell.dart';

class AdminAccountingScreen extends StatefulWidget {
  const AdminAccountingScreen({super.key});

  @override
  State<AdminAccountingScreen> createState() => _AdminAccountingScreenState();
}

class _AdminAccountingScreenState extends State<AdminAccountingScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<_StaffSummary> _summaries = [];
  Map<int, List<PosOrder>> _ordersByStaff = {};
  double _totalRevenue = 0.0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final end = start.add(const Duration(days: 1));
      final orders = await DatabaseService.getPosOrdersByDateRange(start, end);
      final userById = await _loadUsersByStaffIds(
        orders.map((o) => o.staffId).toSet(),
      );

      final Map<int, _StaffSummary> byStaff = {};
      final Map<int, List<PosOrder>> ordersByStaff = {};
      double totalRevenue = 0.0;
      int totalOrders = 0;

      for (final order in orders) {
        int staffId;
        double amount;
        try {
          staffId = order.staffId;
          amount = order.totalPrice;
        } catch (_) {
          continue;
        }
        totalRevenue += amount;
        totalOrders += 1;

        final user = userById[staffId];
        final name = user?.name ?? 'Inconnu';
        final role = _roleLabel(user?.role);
        final key = staffId;

        if (!byStaff.containsKey(key)) {
          byStaff[key] = _StaffSummary(
            staffId: staffId,
            staffName: name,
            staffRole: role,
            ordersCount: 0,
            revenue: 0.0,
          );
        }
        byStaff[key]!.ordersCount += 1;
        byStaff[key]!.revenue += amount;
        ordersByStaff.putIfAbsent(key, () => <PosOrder>[]).add(order);
      }

      for (final list in ordersByStaff.values) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final summaries = byStaff.values.toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      setState(() {
        _summaries = summaries;
        _ordersByStaff = ordersByStaff;
        _totalRevenue = totalRevenue;
        _totalOrders = totalOrders;
      });
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Map<int, User?>> _loadUsersByStaffIds(Set<int> staffIds) async {
    final result = <int, User?>{};
    for (final staffId in staffIds) {
      try {
        result[staffId] = await DatabaseService.getUserById(staffId);
      } catch (_) {
        result[staffId] = null;
      }
    }
    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return AdminShell(
      title: 'Comptabilité',
      activeRoute: '/admin-accounting',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _summaryHeader()),
              TextButton(
                onPressed: _pickDate,
                child: Text(dateLabel, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _summaries.isEmpty
                ? const Center(child: Text('Aucune commande'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 1220
                          ? 4
                          : width >= 920
                          ? 3
                          : width >= 620
                          ? 2
                          : 1;
                      final ratio = crossAxisCount == 1 ? 2.2 : 1.45;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: ratio,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _summaries.length,
                        itemBuilder: (context, index) {
                          final s = _summaries[index];
                          return _staffCard(s);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryHeader() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryTile(
          'Commandes',
          _totalOrders.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        _summaryTile(
          'CA',
          _formatAmount(_totalRevenue),
          icon: Icons.payments_outlined,
          highlight: true,
        ),
      ],
    );
  }

  Widget _summaryTile(
    String label,
    String value, {
    required IconData icon,
    bool highlight = false,
  }) {
    final base = highlight ? AppColors.deepTeal : AppColors.blancPur;
    final foreground = highlight ? AppColors.blancPur : AppColors.charbon;
    final border = highlight ? AppColors.deepTeal : AppColors.grisLeger;

    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: highlight ? AppColors.blancPur : AppColors.grisModerne,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: SushiTypo.price.copyWith(color: foreground, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _staffCard(_StaffSummary summary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showStaffOrders(summary),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grisLeger),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF2F8F9)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.deepTeal.withAlpha(18),
                    child: Text(
                      summary.staffName.isNotEmpty
                          ? summary.staffName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.staffName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal.withAlpha(16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            summary.staffRole,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.grisModerne,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _metricPill(
                      label: 'Commandes',
                      value: summary.ordersCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricPill(
                      label: 'Montant',
                      value: _formatAmount(summary.revenue),
                      highlighted: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricPill({
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.terraCotta.withAlpha(25)
            : AppColors.grisPale,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? AppColors.terraCotta.withAlpha(70)
              : AppColors.grisLeger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SushiTypo.price.copyWith(
              fontSize: 12,
              color: highlighted ? AppColors.terraCotta : AppColors.charbon,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStaffOrders(_StaffSummary summary) async {
    final orders = _ordersByStaff[summary.staffId] ?? const <PosOrder>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.blancPur,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grisLeger,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.deepTeal.withAlpha(18),
                          child: Text(
                            summary.staffName.isNotEmpty
                                ? summary.staffName
                                      .substring(0, 1)
                                      .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.staffName,
                                style: AppTypography.headline2.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                summary.staffRole,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal.withAlpha(12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatAmount(summary.revenue),
                            style: SushiTypo.price.copyWith(
                              color: AppColors.deepTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.grisLeger),
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(
                            child: Text('Aucune commande pour ce profil'),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _orderTile(order);
                            },
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 8),
                            itemCount: orders.length,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _orderTile(PosOrder order) {
    final orderId = _safeOrderId(order);
    final createdAt = _safeOrderCreatedAt(order);
    final status = _safeOrderStatus(order);
    final paymentStatus = _safeOrderPaymentStatus(order);
    final amount = _safeOrderAmount(order);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grisPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grisLeger),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #$orderId',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatOrderTime(createdAt),
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _statusBadge(_statusLabel(status), status),
                    _paymentBadge(paymentStatus),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatAmount(amount),
            style: SushiTypo.price.copyWith(color: AppColors.terraCotta),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _paymentBadge(String paymentStatus) {
    final paid = paymentStatus.trim().toLowerCase() == 'paid';
    final color = paid ? Colors.green.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        paid ? 'Payée' : 'En attente',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch ((role ?? '').trim().toLowerCase()) {
      case 'livreur':
        return 'Livreur';
      case 'staff':
        return 'Serveur';
      case 'admin':
        return 'Admin';
      case 'superadmin':
        return 'Super Admin';
      default:
        return 'Personnel';
    }
  }

  String _formatAmount(double amount) {
    return AppSettingsService.instance.formatAmount(amount);
  }

  String _formatOrderTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'paid':
        return 'Payée';
      case 'cancelled':
      case 'canceled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'preparing':
        return Colors.blue.shade700;
      case 'ready':
        return Colors.green.shade700;
      case 'paid':
        return AppColors.deepTeal;
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;
      default:
        return AppColors.grisModerne;
    }
  }

  int _safeOrderId(PosOrder order) {
    try {
      return order.id;
    } catch (_) {
      return 0;
    }
  }

  DateTime _safeOrderCreatedAt(PosOrder order) {
    try {
      return order.createdAt;
    } catch (_) {
      return _selectedDate;
    }
  }

  double _safeOrderAmount(PosOrder order) {
    try {
      return order.totalPrice;
    } catch (_) {
      return 0.0;
    }
  }

  String _safeOrderStatus(PosOrder order) {
    try {
      final status = order.status.trim();
      if (status.isEmpty) return 'pending';
      return status;
    } catch (_) {
      return 'pending';
    }
  }

  String _safeOrderPaymentStatus(PosOrder order) {
    try {
      final status = order.paymentStatus.trim();
      if (status.isEmpty) return 'pending';
      return status;
    } catch (_) {
      return 'pending';
    }
  }
}

class _StaffSummary {
  _StaffSummary({
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.ordersCount,
    required this.revenue,
  });

  final int staffId;
  final String staffName;
  final String staffRole;
  int ordersCount;
  double revenue;
}
