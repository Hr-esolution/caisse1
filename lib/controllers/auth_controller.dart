// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../api/api_client.dart';
import '../data/app_constants.dart';
import '../models/user.dart';
import '../services/api_order_pull_service.dart';
import '../services/auth_session_service.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';
import 'import_controller.dart';
import 'dart:async';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final Rx<User?> _currentUser = Rx<User?>(null);
  User? get currentUser => _currentUser.value;
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  late final ApiClient _apiClient;

  @override
  void onReady() {
    super.onReady();
    // Initialize database when the controller is ready
    DatabaseService.init();
    _apiClient = Get.find<ApiClient>();
    _initSessionToken();
  }

  Future<void> _initSessionToken() async {
    await AuthSessionService.instance.init();
    final savedToken = AuthSessionService.instance.token;
    final token = savedToken.isNotEmpty ? savedToken : AppConstant.apiToken;
    _apiClient.updateHeaders(token);
    SyncQueueService.instance.updateAuthToken(token);
    ApiOrderPullService.instance.updateAuthToken(token);
    if (Get.isRegistered<ImportController>()) {
      Get.find<ImportController>().updateApiToken(token);
    }
  }

  // Register a new user
  Future<bool> registerUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    int? restaurantId,
    String? pinCode,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await DatabaseService.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Validate pin code if user is staff
      if (role == 'staff' && (pinCode == null || !isValidPin(pinCode))) {
        throw Exception(
          'Un code PIN valide est requis pour les comptes du personnel',
        );
      }

      // Create new user
      final newUser = User(
        name: name,
        phone: phone,
        email: email,
        password: User.hashPassword(password), // Hash the password
        role: role,
        restaurantId: restaurantId,
        pinCode: pinCode,
        isActive: true, // New users are active by default
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user to database
      final userId = await DatabaseService.createUser(newUser);

      if (userId != 0) {
        _currentUser.value = newUser;
        await SyncQueueService.instance.enqueueUserUpsert(newUser);
        return true;
      }

      return false;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Login user
  Future<bool> loginUser(String identifier, String password) async {
    _isLoading.value = true;
    try {
      final normalizedIdentifier = identifier.trim();
      final onlineUser = await _tryOnlineLogin(
        identifier: normalizedIdentifier,
        password: password,
      );
      if (onlineUser != null) {
        _currentUser.value = onlineUser;
        return true;
      }
      final localUser = await _loginLocal(
        identifier: normalizedIdentifier,
        password: password,
      );
      _currentUser.value = localUser;
      return true;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<User?> _tryOnlineLogin({
    required String identifier,
    required String password,
  }) async {
    try {
      String? phoneForApi = _normalizePhone(identifier);
      if (phoneForApi == null) {
        final localByEmail = await DatabaseService.getUserByEmail(
          identifier.toLowerCase(),
        );
        phoneForApi = _normalizePhone(localByEmail?.phone ?? '');
      }
      if (phoneForApi == null) return null;

      final response = await _apiClient.postData('/api/login', {
        'phone': phoneForApi,
        'password': password,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }
      final body = response.body;
      if (body is! Map) return null;

      final token = _extractToken(body);
      if (token.isEmpty) return null;

      final remoteUserData = _extractUserMap(body, identifier: identifier);
      final resolvedEmail = _resolveEmailForLocalUser(
        identifier: identifier,
        remoteUserData: remoteUserData,
        phoneForApi: phoneForApi,
      );
      final localUser = await _upsertUserFromRemote(
        email: resolvedEmail,
        enteredPassword: password,
        data: remoteUserData,
      );

      _apiClient.updateHeaders(token);
      SyncQueueService.instance.updateAuthToken(token);
      ApiOrderPullService.instance.updateAuthToken(token);
      if (Get.isRegistered<ImportController>()) {
        Get.find<ImportController>().updateApiToken(token);
      }
      await AuthSessionService.instance.saveSession(
        token: token,
        email: resolvedEmail,
      );
      return localUser;
    } catch (_) {
      return null;
    }
  }

  String _extractToken(Map body) {
    final direct = body['token'] ?? body['access_token'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final data = body['data'];
    if (data is Map) {
      final nested = data['token'] ?? data['access_token'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }
    return '';
  }

  Map<String, dynamic> _extractUserMap(Map body, {required String identifier}) {
    final user = body['user'];
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }
    final data = body['data'];
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user']);
    }
    return {'email': identifier};
  }

  String _resolveEmailForLocalUser({
    required String identifier,
    required Map<String, dynamic> remoteUserData,
    String? phoneForApi,
  }) {
    final remoteEmail = (remoteUserData['email'] ?? '').toString().trim();
    if (remoteEmail.isNotEmpty) return remoteEmail.toLowerCase();
    if (GetUtils.isEmail(identifier)) return identifier.toLowerCase();
    final phonePart = phoneForApi ?? 'unknown';
    return 'phone_$phonePart@local.pos';
  }

  String? _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 8) return null;
    return digits;
  }

  Future<User> _upsertUserFromRemote({
    required String email,
    required String enteredPassword,
    required Map<String, dynamic> data,
  }) async {
    final existing = await DatabaseService.getUserByEmail(email);
    final role = (data['role'] ?? existing?.role ?? 'staff').toString();
    final localPasswordHash = User.hashPassword(enteredPassword);
    final now = DateTime.now();
    final isActive = data['is_active'] == null
        ? (existing?.isActive ?? true)
        : (data['is_active'] == true || data['is_active'] == 1);

    if (existing == null) {
      final user = User(
        name: (data['name'] ?? email).toString(),
        phone: (data['phone'] ?? '').toString(),
        email: email,
        password: localPasswordHash,
        role: role,
        restaurantId: _asInt(data['restaurant_id']),
        pinCode: (data['pin_code'] ?? '').toString().trim().isEmpty
            ? null
            : data['pin_code'].toString(),
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );
      final remoteId = _asInt(data['id']);
      if (remoteId != null && remoteId > 0) {
        user.id = remoteId;
      }
      await DatabaseService.createUser(user);
      return user;
    }

    existing.name = (data['name'] ?? existing.name).toString();
    existing.phone = (data['phone'] ?? existing.phone).toString();
    existing.password = localPasswordHash;
    existing.role = role;
    existing.restaurantId =
        _asInt(data['restaurant_id']) ?? existing.restaurantId;
    existing.pinCode = (data['pin_code'] ?? existing.pinCode)?.toString();
    existing.isActive = isActive;
    existing.updatedAt = now;
    await DatabaseService.updateUser(existing);
    return existing;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<User> _loginLocal({
    required String identifier,
    required String password,
  }) async {
    final normalized = identifier.trim();
    User? user;
    if (GetUtils.isEmail(normalized)) {
      user = await DatabaseService.getUserByEmail(normalized.toLowerCase());
    } else {
      user = await _findLocalByPhoneVariants(normalized);
      user ??= await DatabaseService.getUserByEmail(normalized.toLowerCase());
    }
    if (user == null) {
      throw Exception('Utilisateur introuvable (hors ligne)');
    }
    if (!user.isActive) {
      throw Exception('Le compte est désactivé');
    }
    if (!user.verifyPassword(password)) {
      throw Exception('Mot de passe incorrect');
    }
    return user;
  }

  Future<User?> _findLocalByPhoneVariants(String input) async {
    final variants = <String>{
      input.trim(),
      input.replaceAll(RegExp(r'[^0-9]'), ''),
    };
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) variants.add('+$digits');

    for (final candidate in variants) {
      if (candidate.isEmpty) continue;
      final found = await DatabaseService.getUserByPhone(candidate);
      if (found != null) return found;
    }
    return null;
  }

  // Logout user
  Future<void> logout() async {
    _apiClient.updateHeaders('');
    SyncQueueService.instance.updateAuthToken('');
    ApiOrderPullService.instance.updateAuthToken('');
    await AuthSessionService.instance.clearSession();
    _currentUser.value = null;
  }

  // Check if user is logged in
  bool get isLoggedIn => _currentUser.value != null;

  String? get currentRole => _currentUser.value?.role;

  // Validate PIN code format
  bool isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  // Change user password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!isLoggedIn || _currentUser.value == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    final user = _currentUser.value!;

    // Verify old password
    if (!user.verifyPassword(oldPassword)) {
      throw Exception('L’ancien mot de passe est incorrect');
    }

    // Update password
    user.password = User.hashPassword(newPassword);
    user.updatedAt = DateTime.now();

    final result = await DatabaseService.updateUser(user);

    if (result != 0) {
      _currentUser.value = user;
      await SyncQueueService.instance.enqueueUserUpsert(user);
      return true;
    }

    return false;
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? email,
    String? pinCode,
  }) async {
    if (!isLoggedIn || _currentUser.value == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    final user = _currentUser.value!;

    // Update fields if provided
    if (name != null) user.name = name;
    if (phone != null) user.phone = phone;
    if (email != null) user.email = email;
    if (pinCode != null) {
      if (user.isStaff() && !isValidPin(pinCode)) {
        throw Exception('Format de PIN invalide');
      }
      user.pinCode = pinCode;
    }

    user.updatedAt = DateTime.now();

    final result = await DatabaseService.updateUser(user);

    if (result != 0) {
      _currentUser.value = user;
      await SyncQueueService.instance.enqueueUserUpsert(user);
      return true;
    }

    return false;
  }
}
