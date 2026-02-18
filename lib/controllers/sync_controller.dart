import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../data/app_constants.dart';
import '../services/api_order_pull_service.dart';
import '../services/auth_session_service.dart';
import '../services/notification_sound_service.dart';
import '../services/sync_queue_service.dart';

class SyncController extends GetxController {
  static const Duration _autoSyncInterval = Duration(seconds: 5);

  final RxBool _isOnline = false.obs;
  final RxBool _isSyncing = false.obs;
  final Rxn<DateTime> _lastSyncAt = Rxn<DateTime>();

  bool get isOnline => _isOnline.value;
  bool get isSyncing => _isSyncing.value;
  DateTime? get lastSyncAt => _lastSyncAt.value;
  bool get canManualSync => _isAdminUser;
  Timer? _timer;
  bool _wasOnline = false;

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  bool get _isAdminUser {
    if (!Get.isRegistered<AuthController>()) return false;
    final role = Get.find<AuthController>().currentRole;
    return role == 'admin' || role == 'superadmin';
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoSyncInterval, (_) async {
      await _tick();
    });
    unawaited(_tick());
  }

  Future<void> syncNow({bool showSuccess = false}) async {
    final online = await _checkOnline();
    _isOnline.value = online;
    if (!online) return;

    await AuthSessionService.instance.init();
    final hasSessionToken = AuthSessionService.instance.token.trim().isNotEmpty;
    if (!hasSessionToken) {
      Get.snackbar(
        'Authentification requise',
        'Connectez-vous pour synchroniser',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await _syncInternal(showSuccess: showSuccess && _isAdminUser);
  }

  Future<void> _tick() async {
    final online = await _checkOnline();
    _isOnline.value = online;

    if (!online) {
      _wasOnline = false;
      return;
    }

    await AuthSessionService.instance.init();
    final hasSessionToken = AuthSessionService.instance.token.trim().isNotEmpty;
    if (!hasSessionToken) return;

    if (!_wasOnline && _isAdminUser) {
      Get.snackbar(
        'Connexion détectée',
        'Synchronisation automatique en cours',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    _wasOnline = true;

    await _syncInternal();
  }

  Future<void> manualSync() async {
    if (!_isAdminUser) return;
    if (!isOnline) {
      Get.snackbar(
        'Hors ligne',
        'Connexion internet indisponible',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _syncInternal(showSuccess: true);
  }

  Future<void> _syncInternal({bool showSuccess = false}) async {
    if (_isSyncing.value) return;
    _isSyncing.value = true;
    try {
      await SyncQueueService.instance.queueUnsyncedOrders();
      await SyncQueueService.instance.flushQueue();
      final pullResult = await _pullIncomingApiOrders();
      if (pullResult.newOrdersCount > 0) {
        await NotificationSoundService.instance.playNewOrderAlarm();
      }
      if (pullResult.changedCount > 0 && Get.isRegistered<PosController>()) {
        await Get.find<PosController>().loadOrdersToday();
      }
      _lastSyncAt.value = DateTime.now();
      if (showSuccess) {
        Get.snackbar(
          'Succès',
          pullResult.newOrdersCount > 0
              ? 'Sync OK: +${pullResult.newOrdersCount} cmd API'
              : 'Synchronisation terminée',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur sync',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSyncing.value = false;
    }
  }

  Future<ApiOrderSyncResult> _pullIncomingApiOrders() async {
    final restaurantId = _resolveRestaurantId();
    if (restaurantId == null || restaurantId <= 0) {
      return const ApiOrderSyncResult();
    }

    final fallbackStaffId = _resolveFallbackStaffId();
    return ApiOrderPullService.instance.syncApiOrdersForRestaurant(
      restaurantId: restaurantId,
      fallbackStaffId: fallbackStaffId,
    );
  }

  int? _resolveRestaurantId() {
    final authRestaurantId =
        Get.find<AuthController>().currentUser?.restaurantId;
    if (authRestaurantId != null && authRestaurantId > 0) {
      return authRestaurantId;
    }

    if (Get.isRegistered<PosController>()) {
      final posRestaurantId = Get.find<PosController>().restaurantId;
      if (posRestaurantId != null && posRestaurantId > 0) {
        return posRestaurantId;
      }
    }

    return null;
  }

  int? _resolveFallbackStaffId() {
    if (Get.isRegistered<PosController>()) {
      final activeStaffId = Get.find<PosController>().activeStaffId;
      if (activeStaffId != null && activeStaffId > 0) {
        return activeStaffId;
      }
    }

    final authUserId = Get.find<AuthController>().currentUser?.id;
    if (authUserId != null && authUserId > 0) {
      return authUserId;
    }

    return null;
  }

  Future<bool> _checkOnline() async {
    // Simple DNS reachability check (avoids MissingPlugin on macOS)
    final host = Uri.parse(AppConstant.baseUrl).host;
    try {
      final result = await InternetAddress.lookup(host);
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
