import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/app_constants.dart';
import '../models/category_model.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/product_model.dart';
import '../models/user.dart';
import 'database_service.dart';

class SyncQueueService {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  // Sync toggle: send orders to backend
  static const bool _syncOrdersEnabled = true;

  final List<Map<String, dynamic>> _queue = <Map<String, dynamic>>[];
  final Map<int, String> _ordersSyncState = <int, String>{};
  Timer? _timer;
  File? _queueFile;
  File? _ordersStateFile;
  bool _initialized = false;
  bool _isFlushing = false;
  String _baseUrl = AppConstant.baseUrl;
  String _authToken = AppConstant.apiToken;
  bool get _hasAuthToken => _authToken.trim().isNotEmpty;
  int get pendingCount => _queue.length;

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
    _queueFile = File('${dir.path}/sync_queue.json');
    _ordersStateFile = File('${dir.path}/orders_sync_state.json');

    await _loadQueue();
    await _loadOrdersSyncState();
    _startPeriodicFlush();
    _initialized = true;
  }

  void updateBaseUrl(String baseUrl) {
    if (baseUrl.trim().isEmpty) return;
    _baseUrl = baseUrl.trim();
  }

  void updateAuthToken(String token) {
    _authToken = token.trim();
  }

  Future<void> enqueueUserUpsert(User user) async {
    await _enqueue(
      entity: 'users',
      action: 'upsert',
      dedupeKey: 'users:upsert:${user.email.toLowerCase()}',
      payload: {
        'id': user.id,
        'name': user.name,
        'phone': user.phone,
        'email': user.email,
        'password': user.password,
        'role': user.role,
        'restaurant_id': user.restaurantId,
        'pin_code': user.pinCode,
        'is_active': user.isActive,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueUserDelete(int userId, {String? email}) async {
    await _enqueue(
      entity: 'users',
      action: 'delete',
      dedupeKey: 'users:delete:${email?.toLowerCase() ?? userId}',
      payload: {'id': userId, 'email': email},
    );
  }

  Future<void> enqueueCategoryUpsert(Category category) async {
    await _enqueue(
      entity: 'categories',
      action: 'upsert',
      dedupeKey: 'categories:upsert:${category.id}',
      payload: {
        'id': category.id,
        'name': category.name,
        'image': category.image,
        'is_deleted': category.isDeleted,
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueCategoryDelete(int categoryId) async {
    await _enqueue(
      entity: 'categories',
      action: 'delete',
      dedupeKey: 'categories:delete:$categoryId',
      payload: {'id': categoryId},
    );
  }

  Future<void> enqueueProductUpsert(Product product) async {
    await _enqueue(
      entity: 'products',
      action: 'upsert',
      dedupeKey: 'products:upsert:${product.id}',
      payload: {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'image': product.image,
        'category_id': product.categoryId,
        'offer': product.offer,
        'is_available': product.isAvailable,
        'sort_order': product.sortOrder,
        'created_at': product.createdAt.toIso8601String(),
        'updated_at': product.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> enqueueProductDelete(int productId) async {
    await _enqueue(
      entity: 'products',
      action: 'delete',
      dedupeKey: 'products:delete:$productId',
      payload: {'id': productId},
    );
  }

  Future<void> enqueueOrderUpsert(
    PosOrder order,
    List<PosOrderItem> items,
  ) async {
    if (!_syncOrdersEnabled) return;
    if (order.channel.trim().toLowerCase() == 'api') {
      return;
    }

    final updatedAt = order.updatedAt.toIso8601String();
    final lastSyncedUpdatedAt = _ordersSyncState[order.id];
    if (lastSyncedUpdatedAt == updatedAt) {
      return;
    }

    final staffUser = await DatabaseService.getUserById(order.staffId);
    final resolvedRestaurantId = order.restaurantId ?? staffUser?.restaurantId;
    final normalizedStatus = _normalizeOrderStatus(order.status);
    final normalizedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final resolvedProductId = await _resolveProductIdForSync(item);
      normalizedItems.add({
        'local_id': item.id,
        'source_local_item_id': item.id,
        'product_id': resolvedProductId,
        'product_name': item.productName,
        'unit_price': item.unitPrice,
        'quantity': item.quantity,
        'created_at': item.createdAt.toIso8601String(),
      });
    }
    if (resolvedRestaurantId == null) {
      debugPrint(
        '⚠️ Skip order sync local_id=${order.id}: restaurant_id is missing.',
      );
      return;
    }

    await _enqueue(
      entity: 'orders',
      action: 'upsert',
      dedupeKey: 'orders:upsert:${order.id}',
      payload: {
        'local_id': order.id,
        'source_local_id': order.id,
        'staff_id': order.staffId,
        'user_id': order.staffId,
        'restaurant_id': resolvedRestaurantId,
        'staff_name': staffUser?.name,
        'client_order_id': 'pos-${order.id}',
        'synced_from': 'flutter_pos',
        'channel': order.channel,
        'fulfillment_type': order.fulfillmentType,
        'status': normalizedStatus,
        'payment_status': order.paymentStatus,
        'payment_method': order.paymentMethod,
        'total_price': order.totalPrice,
        'original_total': order.originalTotal,
        'discount_amount': order.discountAmount,
        'has_discount': order.hasDiscount,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'delivery_address': order.deliveryAddress,
        'table_number': order.tableNumber,
        'note': order.note,
        'reward_id': order.rewardId,
        'cancel_reason': order.cancelReason,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': updatedAt,
        'items': normalizedItems,
      },
    );
  }

  Future<void> enqueueOrderDelete(int localOrderId) async {
    if (!_syncOrdersEnabled) return;
    await init();
    final order = await DatabaseService.getPosOrderById(localOrderId);
    if (order != null && order.channel.trim().toLowerCase() == 'api') {
      return;
    }

    await _enqueue(
      entity: 'orders',
      action: 'delete',
      dedupeKey: 'orders:delete:$localOrderId',
      payload: {'local_id': localOrderId, 'source_local_id': localOrderId},
    );
  }

  Future<void> queueUnsyncedOrders() async {
    if (!_syncOrdersEnabled) return;
    await init();
    await DatabaseService.init();
    final orders = await DatabaseService.getPosOrders();
    for (final order in orders) {
      if (order.channel.trim().toLowerCase() == 'api') {
        continue;
      }
      final currentUpdatedAt = order.updatedAt.toIso8601String();
      final syncedUpdatedAt = _ordersSyncState[order.id];
      if (syncedUpdatedAt == currentUpdatedAt) {
        continue;
      }
      final items = await DatabaseService.getPosOrderItems(order.id);
      await enqueueOrderUpsert(order, items);
    }
  }

  Future<void> flushQueue() async {
    await init();
    if (_isFlushing || _queue.isEmpty || !_hasAuthToken) return;
    _isFlushing = true;
    try {
      final failedItems = <Map<String, dynamic>>[];
      final snapshot = List<Map<String, dynamic>>.from(_queue);
      for (final item in snapshot) {
        final success = await _sendItem(item);
        if (!success) {
          failedItems.add(item);
          continue;
        }

        if (item['entity'] == 'orders' &&
            item['action'] == 'upsert' &&
            item['payload'] is Map<String, dynamic>) {
          final payload = item['payload'] as Map<String, dynamic>;
          final localId = payload['local_id'];
          final updatedAt = payload['updated_at'];
          if (localId is int && updatedAt is String) {
            _ordersSyncState[localId] = updatedAt;
            await _saveOrdersSyncState();
          }
        }
      }
      _queue
        ..clear()
        ..addAll(failedItems);
      await _saveQueue();
    } finally {
      _isFlushing = false;
    }
  }

  void _startPeriodicFlush() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await queueUnsyncedOrders();
      await flushQueue();
    });
  }

  Future<void> _enqueue({
    required String entity,
    required String action,
    required String dedupeKey,
    required Map<String, dynamic> payload,
  }) async {
    await init();
    _queue.removeWhere((item) => item['dedupe_key'] == dedupeKey);
    _queue.add({
      'entity': entity,
      'action': action,
      'dedupe_key': dedupeKey,
      'queued_at': DateTime.now().toIso8601String(),
      'payload': payload,
    });
    await _saveQueue();
    await flushQueue();
  }

  Future<bool> _sendItem(Map<String, dynamic> item) async {
    if (!_syncOrdersEnabled && item['entity'] == 'orders') {
      return true;
    }
    if (!_hasAuthToken) return false;
    final entity = item['entity'];
    final action = item['action'];
    if (entity is! String || action is! String) return true;
    final payload = item['payload'];

    if (entity == 'orders' &&
        action == 'upsert' &&
        payload is Map<String, dynamic>) {
      final channel = payload['channel']?.toString().trim().toLowerCase() ?? '';
      if (channel == 'api') {
        return true;
      }
    }

    final endpoint = _resolveEndpoint(entity: entity, action: action);
    if (endpoint == null) return true;

    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
    };

    try {
      late http.Response response;
      response = await http.post(
        uri,
        headers: headers,
        body: json.encode(payload),
      );
      if (response.statusCode == 401) {
        debugPrint(
          '❌ Sync unauthorized; token missing/invalid. Pause until login. endpoint=$endpoint',
        );
        return false;
      }
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (response.statusCode == 422) {
        if (entity == 'orders' &&
            action == 'upsert' &&
            payload is Map<String, dynamic>) {
          final fallbackOk = await _retryOrderUpsertWithFallbackStatus(
            uri: uri,
            headers: headers,
            payload: payload,
          );
          if (fallbackOk) {
            final localId = payload['local_id'];
            final updatedAt = payload['updated_at'];
            if (localId is int && updatedAt is String) {
              _ordersSyncState[localId] = updatedAt;
              await _saveOrdersSyncState();
            }
            return true;
          }

          // Drop and mark as processed to avoid infinite re-queue loop.
          final localId = payload['local_id'];
          final updatedAt = payload['updated_at'];
          if (localId is int && updatedAt is String) {
            _ordersSyncState[localId] = updatedAt;
            await _saveOrdersSyncState();
          }
        }
        final body = response.body;
        final preview = body.length > 500
            ? '${body.substring(0, 500)}...'
            : body;
        debugPrint(
          '⚠️ Sync dropped (422 validation) [$entity/$action] endpoint=$endpoint body=$preview',
        );
        return true;
      }
      if (!ok) {
        final body = response.body;
        final preview = body.length > 500
            ? '${body.substring(0, 500)}...'
            : body;
        debugPrint(
          '❌ Sync failed [$entity/$action] status=${response.statusCode} endpoint=$endpoint body=$preview',
        );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _retryOrderUpsertWithFallbackStatus({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> payload,
  }) async {
    final currentStatus = payload['status']?.toString().trim().toLowerCase();
    final fallbacks = <String>[
      'pending',
      'preparing',
      'ready',
      'confirmed',
      'completed',
      'paid',
      'new',
    ];
    for (final candidate in fallbacks) {
      if (candidate == currentStatus) continue;
      final mutated = Map<String, dynamic>.from(payload)
        ..['status'] = candidate;
      try {
        final res = await http.post(
          uri,
          headers: headers,
          body: json.encode(mutated),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  String? _resolveEndpoint({required String entity, required String action}) {
    if (action == 'upsert') {
      return '/api/sync/$entity/upsert';
    }
    if (action == 'delete') {
      return '/api/sync/$entity/delete';
    }
    return null;
  }

  String _normalizeOrderStatus(String rawStatus) {
    final value = rawStatus.trim().toLowerCase();
    switch (value) {
      case 'cancelled':
      case 'pending':
      case 'preparing':
      case 'ready':
        return value;
      case 'paid':
        return 'ready';
      default:
        return 'pending';
    }
  }

  Future<int> _resolveProductIdForSync(PosOrderItem item) async {
    final byId = await DatabaseService.getProductById(item.productId);
    if (byId != null) return item.productId;

    final byName = await DatabaseService.getProductByName(item.productName);
    if (byName != null) {
      item.productId = byName.id;
      await DatabaseService.updatePosOrderItem(item);
      return byName.id;
    }

    return item.productId;
  }

  Future<void> _loadQueue() async {
    final file = _queueFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is List) {
        _queue
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map((e) {
              return Map<String, dynamic>.from(e);
            }),
          );
      }
    } catch (_) {}
  }

  Future<void> _saveQueue() async {
    final file = _queueFile;
    if (file == null) return;
    await file.writeAsString(json.encode(_queue));
  }

  Future<void> _loadOrdersSyncState() async {
    final file = _ordersStateFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        _ordersSyncState.clear();
        for (final entry in decoded.entries) {
          final localId = int.tryParse(entry.key);
          final updatedAt = entry.value;
          if (localId != null && updatedAt is String) {
            _ordersSyncState[localId] = updatedAt;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveOrdersSyncState() async {
    final file = _ordersStateFile;
    if (file == null) return;
    final encoded = <String, String>{
      for (final entry in _ordersSyncState.entries)
        entry.key.toString(): entry.value,
    };
    await file.writeAsString(json.encode(encoded));
  }
}
