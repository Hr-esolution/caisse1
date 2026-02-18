import 'package:caisse_1/api/api_client.dart';
import 'package:caisse_1/services/auth_session_service.dart';
import 'package:get/get.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/product_model.dart';
import '../models/pos_table.dart';
import '../models/user.dart';
import '../services/api_order_pull_service.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});

  double get lineTotal => product.price * quantity;
}

class PosController extends GetxController {
  User? _activeStaff;
  User? get activeStaff => _activeStaff;
  int? _activeStaffId;
  int? _restaurantId;
  String? _restaurantName;
  int? get activeStaffId => _activeStaffId;
  int? get restaurantId => _restaurantId;
  String get restaurantName => _restaurantName ?? '';
  String get restaurantLabel {
    if (_restaurantName != null && _restaurantName!.trim().isNotEmpty) {
      return _restaurantName!;
    }
    if (_restaurantId != null) {
      return 'Restaurant ${_restaurantId!}';
    }
    return 'Restaurant -';
  }

  String _fulfillmentType = 'on_site';
  String get fulfillmentType => _fulfillmentType;

  String? _tableNumber;
  String? get tableNumber => _tableNumber;

  String? _customerName;
  String? get customerName => _customerName;
  String? _customerPhone;
  String? get customerPhone => _customerPhone;
  String? _deliveryAddress;
  String? get deliveryAddress => _deliveryAddress;
  String? _note;
  String? get note => _note;

  String? _paymentMethod;
  String? get paymentMethod => _paymentMethod;

  final List<CartItem> _cart = [];
  List<CartItem> get cart => List<CartItem>.unmodifiable(_cart);

  final List<PosOrder> _ordersToday = [];
  List<PosOrder> get ordersToday => List<PosOrder>.unmodifiable(_ordersToday);

  // Filters
  String _ordersFilter =
      'all'; // all | pending | paid | cancelled | preparing | ready
  String get ordersFilter => _ordersFilter;

  String _ordersChannelFilter =
      'all'; // all | pos | remote (mobile/web/api/kiosk)
  String get ordersChannelFilter => _ordersChannelFilter;

  final List<PosTable> _tables = [];
  List<PosTable> get tables => List<PosTable>.unmodifiable(_tables);

  int? _editingOrderId;
  int? get editingOrderId => _editingOrderId;

  String? _error;
  String? get error => _error;

  bool _isCreatingOrder = false;
  bool get isCreatingOrder => _isCreatingOrder;

  bool get isLocked => _activeStaff == null;
  bool get canEditOrders =>
      _activeStaff != null &&
      (_activeStaff!.role == 'staff' ||
          _activeStaff!.role == 'admin' ||
          _activeStaff!.role == 'superadmin');
  bool get canModifyOrders =>
      _activeStaff != null &&
      (_activeStaff!.role == 'admin' || _activeStaff!.role == 'superadmin');

  Future<void> _enqueueOrderSyncById(int orderId) async {
    final order = await DatabaseService.getPosOrderById(orderId);
    if (order == null) return;
    final items = await DatabaseService.getPosOrderItems(orderId);
    await SyncQueueService.instance.enqueueOrderUpsert(order, items);
  }

  Future<bool> unlockWithPin(String pin) async {
    _error = null;
    final normalized = pin.trim();
    if (normalized.length < 4 ||
        normalized.length > 6 ||
        !RegExp(r'^\d+$').hasMatch(normalized)) {
      _error = 'Code PIN invalide';
      update();
      return false;
    }
    final staff = await DatabaseService.getStaffByPin(normalized);
    if (staff == null) {
      _error = 'Code PIN invalide';
      update();
      return false;
    }
    _activeStaff = staff;
    _activeStaffId = staff.id;
    _restaurantId = staff.restaurantId;
    await _loadRestaurantName();
    await ensureTables();
    await loadOrdersToday();
    // Tentative de login Sanctum via PIN pour activer la sync
    try {
      final token = await _authLoginPin(normalized);
      if (token != null && token.isNotEmpty) {
        SyncQueueService.instance.updateAuthToken(token);
        ApiOrderPullService.instance.updateAuthToken(token);
        await AuthSessionService.instance.saveSession(
          token: token,
          email: staff.email,
        );
      }
    } catch (_) {
      // reste offline si échec
    }
    update();
    return true;
  }

  Future<String?> _authLoginPin(String pin) async {
    final client = Get.find<ApiClient>();
    final response = await client.postData('/api/login-pin', {'pin_code': pin});
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    if (response.body is! Map) return null;
    final map = response.body as Map;
    final token = (map['token'] ?? '').toString().trim();
    return token.isNotEmpty ? token : null;
  }

  void lock() {
    _activeStaff = null;
    _activeStaffId = null;
    _restaurantId = null;
    _restaurantName = null;
    _cart.clear();
    _tableNumber = null;
    _customerName = null;
    _customerPhone = null;
    _deliveryAddress = null;
    _note = null;
    _paymentMethod = null;
    _editingOrderId = null;
    _ordersToday.clear();
    _tables.clear();
    _error = null;
    update();
  }

  Future<void> _loadRestaurantName() async {
    final id = _restaurantId;
    if (id == null) {
      _restaurantName = null;
      return;
    }
    final restaurant = await DatabaseService.getRestaurantById(id);
    _restaurantName = restaurant?.name;
  }

  Future<void> refreshRestaurantContext() async {
    await _loadRestaurantName();
    update();
  }

  void setFulfillmentType(String value) {
    _fulfillmentType = value;
    if (_fulfillmentType != 'on_site') {
      _tableNumber = null;
    }
    update();
  }

  void setTableNumber(String value) {
    _tableNumber = value.trim();
    update();
  }

  void setCustomerInfo({String? name, String? phone, String? address}) {
    _customerName = name?.trim().isEmpty == true ? null : name?.trim();
    _customerPhone = phone?.trim().isEmpty == true ? null : phone?.trim();
    _deliveryAddress = address?.trim().isEmpty == true ? null : address?.trim();
    update();
  }

  void setNote(String? value) {
    _note = value?.trim().isEmpty == true ? null : value?.trim();
    update();
  }

  void setPaymentMethod(String? value) {
    _paymentMethod = value;
    update();
  }

  void addToCart(Product product) {
    final index = _cart.indexWhere((c) => c.product.id == product.id);
    if (index == -1) {
      _cart.add(CartItem(product: product, quantity: 1));
    } else {
      _cart[index].quantity += 1;
    }
    update();
  }

  void removeFromCart(Product product) {
    final index = _cart.indexWhere((c) => c.product.id == product.id);
    if (index == -1) return;
    if (_cart[index].quantity > 1) {
      _cart[index].quantity -= 1;
    } else {
      _cart.removeAt(index);
    }
    update();
  }

  void setCartItemQuantity(Product product, int quantity) {
    final index = _cart.indexWhere((c) => c.product.id == product.id);
    if (index == -1) return;
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].quantity = quantity;
    }
    update();
  }

  double get total => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  // ------- SEARCH PRODUCTS -------
  String _searchTerm = '';
  String get searchTerm => _searchTerm;
  void setSearchTerm(String value) {
    _searchTerm = value.trim().toLowerCase();
    update();
  }

  List<Product> filterProductsBySearch(List<Product> products) {
    if (_searchTerm.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(_searchTerm))
        .toList();
  }

  Future<int?> createOrder({
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? note,
  }) async {
    if (_isCreatingOrder) return null; // évite double clics
    _isCreatingOrder = true;
    update();
    _error = null;
    try {
      if (_activeStaff == null) {
        _error = 'Aucun serveur actif';
        update();
        return null;
      }
      if (_fulfillmentType == 'on_site' &&
          (_tableNumber == null || _tableNumber!.isEmpty)) {
        _error = 'Table obligatoire pour sur place';
        update();
        return null;
      }
      if ((_fulfillmentType == 'pickup' || _fulfillmentType == 'delivery') &&
          ((_customerName == null || _customerName!.isEmpty) ||
              (_customerPhone == null || _customerPhone!.isEmpty))) {
        _error = 'Nom et téléphone obligatoires';
        update();
        return null;
      }
      if (_fulfillmentType == 'delivery' &&
          (_deliveryAddress == null || _deliveryAddress!.isEmpty)) {
        _error = 'Adresse obligatoire pour livraison';
        update();
        return null;
      }
      if (_cart.isEmpty) {
        _error = 'Panier vide';
        update();
        return null;
      }

      final order = PosOrder(
        staffId: _activeStaff!.id,
        restaurantId: _activeStaff!.restaurantId,
        fulfillmentType: _fulfillmentType,
        status: 'pending',
        paymentStatus: 'pending',
        totalPrice: total,
        originalTotal: total,
        discountAmount: 0.0,
        hasDiscount: false,
        paymentMethod: _paymentMethod,
        customerName: _customerName ?? customerName,
        customerPhone: _customerPhone ?? customerPhone,
        deliveryAddress: _deliveryAddress ?? deliveryAddress,
        tableNumber: _tableNumber,
        note: _note ?? note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      int orderId;
      if (_editingOrderId != null) {
        order.id = _editingOrderId!;
        orderId = await DatabaseService.updatePosOrder(order);
        await DatabaseService.deletePosOrderItems(orderId);
      } else {
        orderId = await DatabaseService.createPosOrder(order);
      }
      for (final item in _cart) {
        final orderItem = PosOrderItem(
          orderId: orderId,
          productId: item.product.id,
          productName: item.product.name,
          unitPrice: item.product.price,
          quantity: item.quantity,
          createdAt: DateTime.now(),
        );
        await DatabaseService.createPosOrderItem(orderItem);
      }
      await _enqueueOrderSyncById(orderId);

      _cart.clear();
      _editingOrderId = null;
      await loadOrdersToday();
      update();
      return orderId;
    } finally {
      _isCreatingOrder = false;
      update();
    }
  }

  Future<void> loadOrdersToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final orders = await DatabaseService.getPosOrdersByDateRange(start, end);
    final restId = _restaurantId ?? _activeStaff?.restaurantId;
    final activeStaffId = _activeStaffId;

    final scoped = orders.where((o) {
      // Filtre restaurant si connu
      if (restId != null && restId > 0 && o.restaurantId != null) {
        if (o.restaurantId != restId) return false;
      }
      // Staff : voir ses commandes POS, mais inclure toujours les canaux non-POS (web/api/kiosk)
      if (activeStaffId != null) {
        final channel = o.channel.toLowerCase();
        if (channel == 'pos') {
          return o.staffId == activeStaffId;
        }
        // autres canaux toujours visibles
        return true;
      }
      // si pas de staff actif, rien
      return false;
    }).toList();

    // Filtre par canal : POS uniquement ou commandes distantes (web/mobile/kiosk)
    List<PosOrder> channelScoped = scoped;
    if (_ordersChannelFilter == 'pos') {
      channelScoped = scoped
          .where((o) => o.channel.toLowerCase() == 'pos')
          .toList();
    } else if (_ordersChannelFilter == 'remote') {
      channelScoped = scoped.where((o) {
        final ch = o.channel.toLowerCase();
        return ch == 'api' || ch == 'web' || ch == 'kiosk';
      }).toList();
    }

    final filtered = _ordersFilter == 'all'
        ? channelScoped
        : channelScoped.where((o) => o.status == _ordersFilter).toList();
    _ordersToday
      ..clear()
      ..addAll(filtered);
    update();
  }

  void setOrdersFilter(String value) {
    _ordersFilter = value;
    loadOrdersToday();
  }

  void setOrdersChannelFilter(String value) {
    _ordersChannelFilter = value;
    loadOrdersToday();
  }

  Future<bool> markOrderPaid(PosOrder order) async {
    _error = null;
    order.status = 'paid';
    order.paymentStatus = 'paid';
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);
    await _enqueueOrderSyncById(order.id);
    final synced = await _syncApiOrderStatusIfNeeded(order);
    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }
    await loadOrdersToday();
    if (!synced) {
      update();
    }
    return synced;
  }

  Future<bool> updateOrderStatus(PosOrder order, String status) async {
    _error = null;
    order.status = status;
    if (status == 'paid') {
      order.paymentStatus = 'paid';
    }
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);
    await _enqueueOrderSyncById(order.id);
    final synced = await _syncApiOrderStatusIfNeeded(order);
    await loadOrdersToday();
    if (!synced) {
      update();
    }
    return synced;
  }

  Future<bool> cancelOrder(PosOrder order, {String? reason}) async {
    if (!canModifyOrders) {
      _error = 'Annulation réservée aux admins';
      update();
      return false;
    }
    _error = null;
    order.status = 'cancelled';
    order.cancelReason = reason;
    order.updatedAt = DateTime.now();
    await DatabaseService.updatePosOrder(order);
    await _enqueueOrderSyncById(order.id);
    final synced = await _syncApiOrderStatusIfNeeded(
      order,
      cancelReason: reason,
    );
    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }
    await loadOrdersToday();
    if (!synced) {
      update();
    }
    return synced;
  }

  Future<void> deleteOrder(PosOrder order) async {
    if (!canModifyOrders) {
      _error = 'Suppression réservée aux admins';
      update();
      return;
    }
    await SyncQueueService.instance.enqueueOrderDelete(order.id);
    await DatabaseService.deletePosOrder(order.id);
    if (order.tableNumber != null) {
      await markTableFree(order.tableNumber!);
    }
    await loadOrdersToday();
  }

  Future<bool> _syncApiOrderStatusIfNeeded(
    PosOrder order, {
    String? cancelReason,
  }) async {
    if (order.channel.trim().toLowerCase() != 'api') {
      return true;
    }

    final ok = await ApiOrderPullService.instance
        .pushRemoteOrderStatusByLocalId(
          localOrderId: order.id,
          status: order.status,
          paymentStatus: order.paymentStatus,
          cancelReason: cancelReason ?? order.cancelReason,
        );
    if (!ok) {
      _error =
          'Statut local mis à jour, mais impossible de notifier le backend.';
    }
    return ok;
  }

  Future<void> ensureTables() async {
    final restaurantId = _restaurantId;
    final existing = restaurantId == null
        ? await DatabaseService.getPosTables()
        : await DatabaseService.getPosTablesByRestaurant(restaurantId);
    if (existing.isEmpty) {
      final gridPositions = <int, String>{
        1: '1 / 1 / 2 / 2',
        2: '1 / 2 / 2 / 3',
        3: '1 / 3 / 2 / 4',
        4: '1 / 4 / 2 / 5',
        5: '1 / 5 / 2 / 6',
        6: '1 / 6 / 2 / 7',
        7: '1 / 7 / 2 / 8',
        8: '1 / 8 / 2 / 9',
        9: '2 / 1 / 3 / 2',
        10: '2 / 2 / 3 / 3',
        11: '2 / 3 / 3 / 4',
        12: '2 / 4 / 3 / 5',
        13: '2 / 5 / 3 / 6',
        14: '2 / 6 / 3 / 7',
        15: '2 / 7 / 3 / 8',
        16: '2 / 8 / 3 / 9',
        17: '5 / 1 / 6 / 2',
        18: '5 / 2 / 6 / 3',
        19: '5 / 3 / 6 / 4',
        20: '5 / 4 / 6 / 5',
        21: '5 / 5 / 6 / 6',
        22: '5 / 6 / 6 / 7',
        23: '5 / 7 / 6 / 8',
        24: '5 / 8 / 6 / 9',
        25: '6 / 1 / 7 / 2',
        26: '6 / 2 / 7 / 3',
        27: '6 / 3 / 7 / 4',
        28: '6 / 4 / 7 / 5',
        29: '6 / 5 / 7 / 6',
        30: '6 / 6 / 7 / 7',
        31: '1 / 10 / 2 / 11',
        32: '2 / 10 / 3 / 11',
        33: '3 / 10 / 4 / 11',
        34: '4 / 10 / 5 / 11',
        35: '5 / 10 / 6 / 11',
        36: '6 / 10 / 7 / 11',
        37: '1 / 11 / 2 / 12',
        38: '2 / 11 / 3 / 12',
        39: '3 / 11 / 4 / 12',
        40: '4 / 11 / 5 / 12',
        41: '5 / 11 / 6 / 12',
        42: '6 / 11 / 7 / 12',
      };

      for (final entry in gridPositions.entries) {
        final number = entry.key;
        final area = entry.value.replaceAll(' ', '');
        final parts = area.split('/');
        final rowStart = int.parse(parts[0]);
        final colStart = int.parse(parts[1]);
        final rowEnd = int.parse(parts[2]);
        final colEnd = int.parse(parts[3]);
        await DatabaseService.createPosTable(
          PosTable(
            number: 'T$number',
            status: 'available',
            restaurantId: restaurantId,
            gridColumnStart: colStart,
            gridColumnEnd: colEnd,
            gridRowStart: rowStart,
            gridRowEnd: rowEnd,
          ),
        );
      }
    }
    final tables = restaurantId == null
        ? await DatabaseService.getPosTables()
        : await DatabaseService.getPosTablesByRestaurant(restaurantId);
    _tables
      ..clear()
      ..addAll(tables);
    update();
  }

  Future<void> markTableOccupied(String tableNumber) async {
    PosTable? table;
    for (final t in _tables) {
      if (t.number == tableNumber) {
        table = t;
        break;
      }
    }
    if (table == null) return;
    table.status = 'occupied';
    await DatabaseService.updatePosTable(table);
    await ensureTables();
  }

  Future<void> markTableFree(String tableNumber) async {
    PosTable? table;
    for (final t in _tables) {
      if (t.number == tableNumber) {
        table = t;
        break;
      }
    }
    if (table == null) return;
    table.status = 'available';
    await DatabaseService.updatePosTable(table);
    await ensureTables();
  }

  Future<void> loadOrderForEdit(PosOrder order) async {
    if (!canEditOrders) {
      _error = 'Modification non autorisée';
      update();
      return;
    }
    final now = DateTime.now();
    final sameDay =
        order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
    if (order.status != 'pending' || !sameDay) {
      _error = 'Commande non modifiable';
      update();
      return;
    }
    _editingOrderId = order.id;
    _fulfillmentType = order.fulfillmentType;
    _tableNumber = order.tableNumber;
    _customerName = order.customerName;
    _customerPhone = order.customerPhone;
    _deliveryAddress = order.deliveryAddress;
    _note = order.note;
    _paymentMethod = order.paymentMethod;

    _cart.clear();
    final items = await DatabaseService.getPosOrderItems(order.id);
    for (final item in items) {
      final product = await DatabaseService.getProductById(item.productId);
      if (product != null) {
        _cart.add(CartItem(product: product, quantity: item.quantity));
      }
    }
    update();
  }

  Future<bool> editOrderDetails(
    PosOrder order, {
    required String fulfillmentType,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
  }) async {
    _error = null;
    if (!canEditOrders) {
      _error = 'Modification non autorisee';
      update();
      return false;
    }

    final now = DateTime.now();
    final sameDay =
        order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
    if (order.status != 'pending' || !sameDay) {
      _error = 'Commande non modifiable';
      update();
      return false;
    }

    final normalizedTable = tableNumber?.trim();
    final normalizedName = customerName?.trim();
    final normalizedPhone = customerPhone?.trim();
    final normalizedAddress = deliveryAddress?.trim();

    if (fulfillmentType == 'on_site' &&
        (normalizedTable == null || normalizedTable.isEmpty)) {
      _error = 'Table obligatoire pour sur place';
      update();
      return false;
    }
    if ((fulfillmentType == 'pickup' || fulfillmentType == 'delivery') &&
        ((normalizedName == null || normalizedName.isEmpty) ||
            (normalizedPhone == null || normalizedPhone.isEmpty))) {
      _error = 'Nom et telephone obligatoires';
      update();
      return false;
    }
    if (fulfillmentType == 'delivery' &&
        (normalizedAddress == null || normalizedAddress.isEmpty)) {
      _error = 'Adresse obligatoire pour livraison';
      update();
      return false;
    }

    final oldTable = order.tableNumber;
    final oldType = order.fulfillmentType;
    final newTable = fulfillmentType == 'on_site' ? normalizedTable : null;

    order.fulfillmentType = fulfillmentType;
    order.tableNumber = (newTable == null || newTable.isEmpty)
        ? null
        : newTable;
    order.customerName = (normalizedName == null || normalizedName.isEmpty)
        ? null
        : normalizedName;
    order.customerPhone = (normalizedPhone == null || normalizedPhone.isEmpty)
        ? null
        : normalizedPhone;
    order.deliveryAddress =
        fulfillmentType == 'delivery' &&
            normalizedAddress != null &&
            normalizedAddress.isNotEmpty
        ? normalizedAddress
        : null;
    order.updatedAt = DateTime.now();

    await DatabaseService.updatePosOrder(order);
    await _enqueueOrderSyncById(order.id);

    if (oldType == 'on_site' &&
        oldTable != null &&
        oldTable.isNotEmpty &&
        (fulfillmentType != 'on_site' || oldTable != order.tableNumber)) {
      await markTableFree(oldTable);
    }
    if (fulfillmentType == 'on_site' &&
        order.tableNumber != null &&
        order.tableNumber!.isNotEmpty &&
        (oldType != 'on_site' || oldTable != order.tableNumber)) {
      await markTableOccupied(order.tableNumber!);
    }

    await loadOrdersToday();
    update();
    return true;
  }
}
