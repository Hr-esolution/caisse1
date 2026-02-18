import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/app_constants.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import 'database_service.dart';

class ApiOrderPullService {
  ApiOrderPullService._();
  static final ApiOrderPullService instance = ApiOrderPullService._();

  bool _initialized = false;
  String _baseUrl = AppConstant.baseUrl;
  String _authToken = AppConstant.apiToken;
  File? _stateFile;

  final Map<int, _RemoteOrderSyncState> _remoteState =
      <int, _RemoteOrderSyncState>{};
  final Set<int> _remoteLocalOrderIds = <int>{};

  Future<void> init({String? baseUrl, String? authToken}) async {
    if (_initialized) {
      if (baseUrl != null && baseUrl.trim().isNotEmpty) {
        _baseUrl = baseUrl.trim();
      }
      if (authToken != null) {
        _authToken = authToken.trim();
      }
      return;
    }

    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrl = baseUrl.trim();
    }
    if (authToken != null) {
      _authToken = authToken.trim();
    }

    final dir = await getApplicationDocumentsDirectory();
    _stateFile = File('${dir.path}/api_orders_sync_state.json');
    await _loadState();
    _initialized = true;
  }

  void updateBaseUrl(String baseUrl) {
    if (baseUrl.trim().isEmpty) return;
    _baseUrl = baseUrl.trim();
  }

  void updateAuthToken(String token) {
    _authToken = token.trim();
  }

  bool isRemoteApiLocalOrderIdSync(int localOrderId) {
    return _remoteLocalOrderIds.contains(localOrderId);
  }

  Future<bool> isRemoteApiLocalOrderId(int localOrderId) async {
    await init();
    return _remoteLocalOrderIds.contains(localOrderId);
  }

  int? remoteOrderIdForLocalIdSync(int localOrderId) {
    for (final entry in _remoteState.entries) {
      if (entry.value.localId == localOrderId) {
        return entry.key;
      }
    }
    return null;
  }

  Future<int?> remoteOrderIdForLocalId(int localOrderId) async {
    await init();
    return remoteOrderIdForLocalIdSync(localOrderId);
  }

  Future<bool> pushRemoteOrderStatusByLocalId({
    required int localOrderId,
    required String status,
    String? paymentStatus,
    String? cancelReason,
  }) async {
    await init();
    if (_authToken.isEmpty) return false;

    final remoteOrderId = remoteOrderIdForLocalIdSync(localOrderId);
    if (remoteOrderId == null || remoteOrderId <= 0) {
      return false;
    }

    var success = false;
    for (final backendStatus in _backendStatusCandidates(status)) {
      final normalizedPayment = _normalizePaymentStatusForBackend(
        paymentStatus,
        fallbackStatus: backendStatus,
      );
      final payload = <String, dynamic>{
        'status': backendStatus,
        'order_status': backendStatus,
        'payment_status': normalizedPayment,
        'channel': 'api',
        'source': 'desktop_pos',
        if (cancelReason != null && cancelReason.trim().isNotEmpty)
          'cancel_reason': cancelReason.trim(),
      };

      success = await _pushRemoteOrderStatus(
        remoteOrderId: remoteOrderId,
        backendStatus: backendStatus,
        payload: payload,
      );
      if (success) break;
    }
    if (!success) return false;

    final existing = _remoteState[remoteOrderId];
    if (existing == null) return true;
    _remoteState[remoteOrderId] = _RemoteOrderSyncState(
      localId: existing.localId,
      updatedAt: DateTime.now().toIso8601String(),
      restaurantId: existing.restaurantId,
    );
    await _saveState();
    return true;
  }

  Future<ApiOrderSyncResult> syncApiOrdersForRestaurant({
    required int restaurantId,
    int? fallbackStaffId,
  }) async {
    await init();
    await DatabaseService.init();
    if (restaurantId <= 0 || _authToken.isEmpty) {
      return const ApiOrderSyncResult();
    }

    final orders = await _fetchOrders(restaurantId: restaurantId);
    if (orders.isEmpty) {
      return const ApiOrderSyncResult();
    }

    var changedCount = 0;
    var newOrdersCount = 0;
    var updatedOrdersCount = 0;
    var shouldPersistState = false;

    for (final raw in orders) {
      final channel = _asTrimmedString(raw['channel']).toLowerCase();
      final normalizedFulfillment = _normalizeFulfillment(
        raw['fulfillment_type'],
      );

      // Les commandes mobiles (channel=api) ne devraient pas être "sur place".
      if (channel == 'api' && normalizedFulfillment == 'on_site') {
        continue;
      }

      final orderRestaurantId = _extractRestaurantId(raw);
      if (orderRestaurantId == null || orderRestaurantId != restaurantId) {
        continue;
      }

      final remoteOrderId = _asInt(raw['id']);
      if (remoteOrderId == null || remoteOrderId <= 0) continue;

      final updatedAtIso = _asDate(
        raw['updated_at'] ?? raw['created_at'],
      ).toIso8601String();
      final previous = _remoteState[remoteOrderId];

      if (previous != null && previous.updatedAt == updatedAtIso) {
        final existing = await DatabaseService.getPosOrderById(
          previous.localId,
        );
        if (existing != null) {
          _remoteLocalOrderIds.add(existing.id);
          continue;
        }
      }

      final localOrderId = await _upsertRemoteOrder(
        raw: raw,
        restaurantId: restaurantId,
        fallbackStaffId: fallbackStaffId,
        localIdHint: previous?.localId,
      );
      if (localOrderId == null || localOrderId.localId <= 0) {
        continue;
      }

      _remoteState[remoteOrderId] = _RemoteOrderSyncState(
        localId: localOrderId.localId,
        updatedAt: updatedAtIso,
        restaurantId: restaurantId,
      );
      _remoteLocalOrderIds.add(localOrderId.localId);
      changedCount += 1;
      if (localOrderId.created) {
        newOrdersCount += 1;
      } else {
        updatedOrdersCount += 1;
      }
      shouldPersistState = true;
    }

    if (shouldPersistState) {
      await _saveState();
    }
    return ApiOrderSyncResult(
      changedCount: changedCount,
      newOrdersCount: newOrdersCount,
      updatedOrdersCount: updatedOrdersCount,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOrders({
    required int restaurantId,
  }) async {
    final collected = <Map<String, dynamic>>[];
    final seenUrls = <String>{};
    var currentUri = Uri.parse('$_baseUrl/api/orders').replace(
      queryParameters: {
        'restaurant_id': restaurantId.toString(),
        'per_page': '100',
      },
    );

    for (var page = 0; page < 8; page++) {
      final currentUrl = currentUri.toString();
      if (!seenUrls.add(currentUrl)) {
        break;
      }

      http.Response response;
      try {
        response = await http.get(currentUri, headers: _headers);
      } catch (_) {
        break;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        break;
      }

      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (_) {
        break;
      }

      final pageOrders = _extractOrderList(decoded);
      if (pageOrders.isNotEmpty) {
        collected.addAll(pageOrders);
      }

      final next = _extractNextPageUri(decoded);
      if (next == null) break;
      currentUri = next;
    }

    return collected;
  }

  Future<_UpsertRemoteOrderResult?> _upsertRemoteOrder({
    required Map<String, dynamic> raw,
    required int restaurantId,
    required int? fallbackStaffId,
    required int? localIdHint,
  }) async {
    PosOrder? existingOrder;
    if (localIdHint != null && localIdHint > 0) {
      existingOrder = await DatabaseService.getPosOrderById(localIdHint);
    }

    final rawStatus = _firstNonEmptyString([
      _asTrimmedString(raw['order_status']),
      _asTrimmedString(raw['orderStatus']),
      _asTrimmedString(raw['status']),
      _asTrimmedString(raw['state']),
    ]);
    final normalizedStatus = _normalizeStatus(rawStatus);
    final rawPaymentStatus = _firstNonEmptyString([
      _asTrimmedString(raw['payment_status']),
      _asTrimmedString(raw['paymentStatus']),
    ]);
    final normalizedFulfillment = _normalizeFulfillment(
      raw['fulfillment_type'],
    );
    final totalPrice = _resolveTotalPrice(raw);
    final discountAmount = _asDouble(raw['discount_amount']);
    final originalTotal = _resolveOriginalTotal(
      raw: raw,
      totalPrice: totalPrice,
      discountAmount: discountAmount,
    );

    final userMap = _extractMap(raw['user']);
    final customerName = _firstNonEmptyString([
      _asTrimmedString(raw['customer_name']),
      _asTrimmedString(userMap['name']),
    ]);
    final customerPhone = _firstNonEmptyString([
      _asTrimmedString(raw['customer_phone']),
      _asTrimmedString(userMap['phone']),
    ]);
    final staffId = _resolveStaffId(raw, fallbackStaffId: fallbackStaffId);
    final createdAt = _asDate(raw['created_at']);
    final updatedAt = _asDate(raw['updated_at'] ?? raw['created_at']);
    final remoteTableNumber = _asNullableString(raw['table_number']);

    // Déduplication : si une commande locale POS avec mêmes signature existe,
    // on relie simplement le remoteId sans recréer.
    if (existingOrder == null) {
      existingOrder = await DatabaseService.findSimilarLocalPosOrder(
        createdAt: createdAt,
        totalPrice: totalPrice,
        tableNumber: remoteTableNumber,
        fulfillmentType: normalizedFulfillment,
      );
      if (existingOrder != null) {
        return _UpsertRemoteOrderResult(
          localId: existingOrder.id,
          created: false,
        );
      }
    }

    final order =
        existingOrder ??
        PosOrder(
          staffId: staffId,
          restaurantId: restaurantId,
          channel: _asTrimmedString(raw['channel']).isEmpty
              ? 'api'
              : _asTrimmedString(raw['channel']).toLowerCase(),
          fulfillmentType: normalizedFulfillment,
          status: normalizedStatus,
          totalPrice: totalPrice,
          originalTotal: originalTotal,
          discountAmount: discountAmount,
          hasDiscount: discountAmount > 0,
          paymentMethod: _asNullableString(raw['payment_method']),
          paymentStatus: _normalizePaymentStatus(
            rawPaymentStatus,
            status: normalizedStatus,
          ),
          customerName: customerName,
          customerPhone: customerPhone,
          deliveryAddress: _asNullableString(raw['delivery_address']),
          tableNumber: remoteTableNumber,
          note: _asNullableString(raw['note']),
          rewardId: _asInt(raw['reward_id']),
          cancelReason: _asNullableString(raw['cancel_reason']),
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

    order.staffId = staffId;
    order.restaurantId = restaurantId;
    order.channel = existingOrder?.channel ?? 'api';
    order.fulfillmentType = normalizedFulfillment;
    order.status = normalizedStatus;
    order.totalPrice = totalPrice;
    order.originalTotal = originalTotal;
    order.discountAmount = discountAmount;
    order.hasDiscount = discountAmount > 0;
    order.paymentMethod = _asNullableString(raw['payment_method']);
    order.paymentStatus = _normalizePaymentStatus(
      rawPaymentStatus,
      status: normalizedStatus,
    );
    order.customerName = customerName;
    order.customerPhone = customerPhone;
    order.deliveryAddress = _asNullableString(raw['delivery_address']);
    order.tableNumber = _asNullableString(raw['table_number']);
    order.note = _asNullableString(raw['note']);
    order.rewardId = _asInt(raw['reward_id']);
    order.cancelReason = _asNullableString(raw['cancel_reason']);
    order.createdAt = createdAt;
    order.updatedAt = updatedAt;

    int localOrderId;
    final created = existingOrder == null;
    if (existingOrder == null) {
      localOrderId = await DatabaseService.createPosOrder(order);
    } else {
      localOrderId = order.id;
      await DatabaseService.updatePosOrder(order);
      await DatabaseService.deletePosOrderItems(localOrderId);
    }

    final items = _extractOrderItems(raw);
    for (final item in items) {
      final orderItem = PosOrderItem(
        orderId: localOrderId,
        productId: item.productId,
        productName: item.productName,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        createdAt: createdAt,
      );
      await DatabaseService.createPosOrderItem(orderItem);
    }

    return _UpsertRemoteOrderResult(localId: localOrderId, created: created);
  }

  List<Map<String, dynamic>> _extractOrderList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is! Map) return const [];

    final root = Map<String, dynamic>.from(decoded);
    final directCandidates = [
      root['data'],
      root['orders'],
      root['items'],
      root['results'],
    ];
    for (final candidate in directCandidates) {
      final parsed = _mapList(candidate);
      if (parsed.isNotEmpty) return parsed;
    }

    final nestedData = root['data'];
    if (nestedData is Map) {
      final nested = Map<String, dynamic>.from(nestedData);
      final nestedCandidates = [
        nested['data'],
        nested['orders'],
        nested['items'],
        nested['results'],
      ];
      for (final candidate in nestedCandidates) {
        final parsed = _mapList(candidate);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    return const [];
  }

  Uri? _extractNextPageUri(dynamic decoded) {
    if (decoded is! Map) return null;
    final root = Map<String, dynamic>.from(decoded);

    final nextRoot = _asTrimmedString(root['next_page_url']);
    if (nextRoot.isNotEmpty) {
      return _resolveUri(nextRoot);
    }

    final nestedData = root['data'];
    if (nestedData is Map) {
      final nested = Map<String, dynamic>.from(nestedData);
      final nextNested = _asTrimmedString(nested['next_page_url']);
      if (nextNested.isNotEmpty) {
        return _resolveUri(nextNested);
      }
    }

    return null;
  }

  Uri? _resolveUri(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;
    final base = Uri.tryParse(_baseUrl);
    if (base == null) return null;
    return base.resolve(trimmed);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int? _extractRestaurantId(Map<String, dynamic> raw) {
    final direct = _asInt(raw['restaurant_id'] ?? raw['restaurantId']);
    if (direct != null) return direct;
    final restaurant = _extractMap(raw['restaurant']);
    return _asInt(restaurant['id']);
  }

  List<_RemoteOrderItem> _extractOrderItems(Map<String, dynamic> raw) {
    final detailsCandidates = [
      raw['details'],
      raw['items'],
      raw['order_items'],
      raw['orderItems'],
    ];
    List<dynamic> details = const [];
    for (final candidate in detailsCandidates) {
      if (candidate is List) {
        details = candidate;
        break;
      }
      if (candidate is Map && candidate['data'] is List) {
        details = candidate['data'] as List;
        break;
      }
    }

    final parsed = <_RemoteOrderItem>[];
    for (final detail in details) {
      if (detail is! Map) continue;
      final detailMap = Map<String, dynamic>.from(detail);
      final productMap = _extractMap(detailMap['product']);
      final quantity = (_asInt(detailMap['quantity'] ?? detailMap['qty']) ?? 1)
          .clamp(1, 1000000);

      var unitPrice = _asDouble(detailMap['unit_price']);
      if (unitPrice <= 0) unitPrice = _asDouble(detailMap['price']);
      if (unitPrice <= 0) unitPrice = _asDouble(detailMap['product_price']);
      if (unitPrice <= 0) {
        final lineTotal = _asDouble(
          detailMap['line_total'] ?? detailMap['total'],
        );
        if (lineTotal > 0 && quantity > 0) {
          unitPrice = lineTotal / quantity;
        }
      }
      if (unitPrice <= 0) {
        unitPrice = _asDouble(productMap['price']);
      }

      final productId =
          _asInt(
            detailMap['product_id'] ??
                detailMap['productId'] ??
                productMap['id'],
          ) ??
          0;
      final productName = _firstNonEmptyString([
        _asTrimmedString(detailMap['product_name']),
        _asTrimmedString(detailMap['name']),
        _asTrimmedString(productMap['name']),
        productId > 0 ? 'Produit #$productId' : 'Produit',
      ]);

      parsed.add(
        _RemoteOrderItem(
          productId: productId,
          productName: productName,
          unitPrice: unitPrice > 0 ? unitPrice : 0.0,
          quantity: quantity,
        ),
      );
    }
    return parsed;
  }

  int _resolveStaffId(
    Map<String, dynamic> raw, {
    required int? fallbackStaffId,
  }) {
    final staffId = _asInt(raw['staff_id'] ?? raw['staffId']);
    if (staffId != null && staffId > 0) {
      return staffId;
    }
    if (fallbackStaffId != null && fallbackStaffId > 0) {
      return fallbackStaffId;
    }
    return 0;
  }

  double _resolveTotalPrice(Map<String, dynamic> raw) {
    final candidates = [
      raw['total_price'],
      raw['total'],
      raw['grand_total'],
      raw['amount'],
    ];
    for (final value in candidates) {
      final parsed = _asDouble(value);
      if (parsed > 0) return parsed;
    }
    return 0.0;
  }

  double _resolveOriginalTotal({
    required Map<String, dynamic> raw,
    required double totalPrice,
    required double discountAmount,
  }) {
    final parsed = _asDouble(raw['original_total'] ?? raw['subtotal']);
    if (parsed > 0) return parsed;
    if (discountAmount > 0) return totalPrice + discountAmount;
    return totalPrice;
  }

  String _normalizeFulfillment(dynamic value) {
    final normalized = _asTrimmedString(value).toLowerCase();
    switch (normalized) {
      case 'on_site':
      case 'pickup':
      case 'delivery':
        return normalized;
      default:
        return 'delivery';
    }
  }

  String _normalizeStatus(dynamic value) {
    final normalized = _asTrimmedString(value).toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'new':
        return 'pending';
      case 'preparing':
      case 'in_preparation':
      case 'in_progress':
      case 'processing':
      case 'confirmed':
      case 'accepted':
        return 'preparing';
      case 'ready':
      case 'prepared':
      case 'in_delivery':
        return 'ready';
      case 'paid':
      case 'completed':
        return 'paid';
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _normalizePaymentStatus(dynamic value, {required String status}) {
    final normalized = _asTrimmedString(value).toLowerCase();
    if (normalized == 'paid') return 'paid';
    if (normalized == 'pending' || normalized.isEmpty) {
      return status == 'paid' ? 'paid' : 'pending';
    }
    return status == 'paid' ? 'paid' : 'pending';
  }

  String _normalizeStatusForBackend(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'new':
        return 'pending';
      case 'preparing':
      case 'in_preparation':
      case 'confirmed':
      case 'accepted':
        return 'confirmed';
      case 'ready':
      case 'prepared':
      case 'in_delivery':
        return 'ready';
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return 'cancelled';
      case 'paid':
      case 'completed':
        return 'completed';
      default:
        return 'pending';
    }
  }

  List<String> _backendStatusCandidates(String localStatus) {
    final normalizedLocal = localStatus.trim().toLowerCase();
    final preferred = _normalizeStatusForBackend(normalizedLocal);
    String fallback = '';
    switch (normalizedLocal) {
      case 'pending':
      case 'new':
        fallback = 'new';
        break;
      case 'preparing':
      case 'confirmed':
      case 'accepted':
      case 'in_preparation':
        fallback = 'preparing';
        break;
      case 'ready':
      case 'prepared':
      case 'in_delivery':
        fallback = 'prepared';
        break;
      case 'paid':
      case 'completed':
        fallback = 'paid';
        break;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        fallback = 'canceled';
        break;
      default:
        fallback = '';
    }

    final ordered = <String>[];
    final seen = <String>{};
    for (final candidate in [preferred, fallback]) {
      final value = candidate.trim().toLowerCase();
      if (value.isEmpty) continue;
      if (seen.add(value)) {
        ordered.add(value);
      }
    }
    if (ordered.isEmpty) return const ['pending'];
    return ordered;
  }

  String _normalizePaymentStatusForBackend(
    String? paymentStatus, {
    required String fallbackStatus,
  }) {
    final normalized = paymentStatus?.trim().toLowerCase() ?? '';
    if (normalized == 'paid') return 'paid';
    if (fallbackStatus == 'completed') return 'paid';
    return 'pending';
  }

  Future<bool> _pushRemoteOrderStatus({
    required int remoteOrderId,
    required String backendStatus,
    required Map<String, dynamic> payload,
  }) async {
    final attempts = <_OrderStatusEndpointAttempt>[
      _OrderStatusEndpointAttempt(
        method: 'PATCH',
        path: '/api/orders/$remoteOrderId/status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'PUT',
        path: '/api/orders/$remoteOrderId/status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'POST',
        path: '/api/orders/$remoteOrderId/status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'POST',
        path: '/api/orders/$remoteOrderId/update-status',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'PATCH',
        path: '/api/orders/$remoteOrderId',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'PUT',
        path: '/api/orders/$remoteOrderId',
        payload: payload,
      ),
      _OrderStatusEndpointAttempt(
        method: 'PATCH',
        path: '/api/orders/$remoteOrderId',
        payload: {'status': backendStatus},
      ),
      _OrderStatusEndpointAttempt(
        method: 'PUT',
        path: '/api/orders/$remoteOrderId',
        payload: {'status': backendStatus},
      ),
    ];

    for (final attempt in attempts) {
      final uri = Uri.parse('$_baseUrl${attempt.path}');
      http.Response response;
      try {
        switch (attempt.method) {
          case 'PATCH':
            response = await http.patch(
              uri,
              headers: _headers,
              body: json.encode(attempt.payload),
            );
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: _headers,
              body: json.encode(attempt.payload),
            );
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: _headers,
              body: json.encode(attempt.payload),
            );
            break;
          default:
            continue;
        }
      } catch (_) {
        continue;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      if (response.statusCode == 404 ||
          response.statusCode == 405 ||
          response.statusCode == 501) {
        continue;
      }
    }
    return false;
  }

  Map<String, dynamic> _extractMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DateTime _asDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String _asTrimmedString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String? _asNullableString(dynamic value) {
    final str = _asTrimmedString(value);
    if (str.isEmpty) return null;
    return str;
  }

  String _firstNonEmptyString(List<String> values) {
    for (final value in values) {
      final v = value.trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
  };

  Future<void> _loadState() async {
    final file = _stateFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) return;

      final rawOrders = decoded['orders'];
      final sourceMap = rawOrders is Map<String, dynamic> ? rawOrders : decoded;

      _remoteState.clear();
      _remoteLocalOrderIds.clear();
      for (final entry in sourceMap.entries) {
        final remoteId = int.tryParse(entry.key);
        if (remoteId == null) continue;
        final value = entry.value;
        if (value is! Map) continue;
        final parsedValue = Map<String, dynamic>.from(value);
        final localId = _asInt(parsedValue['local_id']);
        final updatedAt = _asTrimmedString(parsedValue['updated_at']);
        final restaurantId = _asInt(parsedValue['restaurant_id']) ?? 0;
        if (localId == null || localId <= 0 || updatedAt.isEmpty) continue;
        _remoteState[remoteId] = _RemoteOrderSyncState(
          localId: localId,
          updatedAt: updatedAt,
          restaurantId: restaurantId,
        );
        _remoteLocalOrderIds.add(localId);
      }
    } catch (_) {}
  }

  Future<void> _saveState() async {
    final file = _stateFile;
    if (file == null) return;
    final payload = <String, dynamic>{
      'orders': <String, dynamic>{
        for (final entry in _remoteState.entries)
          entry.key.toString(): entry.value.toJson(),
      },
    };
    await file.writeAsString(json.encode(payload));
  }
}

class _RemoteOrderSyncState {
  const _RemoteOrderSyncState({
    required this.localId,
    required this.updatedAt,
    required this.restaurantId,
  });

  final int localId;
  final String updatedAt;
  final int restaurantId;

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'updated_at': updatedAt,
    'restaurant_id': restaurantId,
  };
}

class _RemoteOrderItem {
  const _RemoteOrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
}

class _UpsertRemoteOrderResult {
  const _UpsertRemoteOrderResult({
    required this.localId,
    required this.created,
  });

  final int localId;
  final bool created;
}

class ApiOrderSyncResult {
  const ApiOrderSyncResult({
    this.changedCount = 0,
    this.newOrdersCount = 0,
    this.updatedOrdersCount = 0,
  });

  final int changedCount;
  final int newOrdersCount;
  final int updatedOrdersCount;
}

class _OrderStatusEndpointAttempt {
  const _OrderStatusEndpointAttempt({
    required this.method,
    required this.path,
    required this.payload,
  });

  final String method;
  final String path;
  final Map<String, dynamic> payload;
}
