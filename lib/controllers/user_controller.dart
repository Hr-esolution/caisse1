// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final RxList<User> _users = <User>[].obs;
  List<User> get users => _users.toList();

  @override
  void onInit() {
    super.onInit();
    // Initialize database when the controller is ready
    DatabaseService.init();
    final restId = Get.find<AuthController>().currentUser?.restaurantId;
    final isSuperAdmin = Get.find<AuthController>().currentRole == 'superadmin';
    fetchAllUsers(restaurantId: isSuperAdmin ? null : restId);
  }

  Future<void> fetchAllUsers({int? restaurantId}) async {
    try {
      final auth = Get.find<AuthController>();
      final role = auth.currentRole ?? '';

      if (role == 'superadmin') {
        _users.assignAll(await DatabaseService.getAllUsers());
        return;
      }

      final restId = restaurantId ?? auth.currentUser?.restaurantId;
      if (restId == null || restId <= 0) {
        _users.clear();
        return;
      }
      final scoped = await DatabaseService.getUsersByRestaurant(restId);
      final filtered = scoped
          .where((u) => u.role == 'admin' || u.role == 'staff')
          .toList();
      _users.assignAll(filtered);
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  // Create a new user (for admin use)
  Future<bool> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    int? restaurantId,
    String? pinCode,
    bool isActive = true,
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
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user to database
      final userId = await DatabaseService.createUser(newUser);

      if (userId != 0) {
        _users.add(newUser);
        await SyncQueueService.instance.enqueueUserUpsert(newUser);
        return true;
      }

      return false;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Update user (for admin use)
  Future<bool> updateUser({
    required int userId,
    String? name,
    String? phone,
    String? email,
    String? role,
    int? restaurantId,
    String? pinCode,
    bool? isActive,
  }) async {
    try {
      print('🔧 UpdateUser called for id=$userId');
      // Get the user from database
      final user = await DatabaseService.getUserById(userId);
      if (user == null) {
        print('❌ User not found for id=$userId');
        throw Exception('Utilisateur introuvable');
      }

      // Update fields if provided
      if (name != null) user.name = name;
      if (phone != null) user.phone = phone;
      if (email != null) user.email = email;
      if (role != null) user.role = role;
      if (restaurantId != null) user.restaurantId = restaurantId;
      if (pinCode != null) {
        if (user.isStaff() && !isValidPin(pinCode)) {
          print('❌ Invalid PIN for staff user id=$userId');
          throw Exception('Format de PIN invalide');
        }
        user.pinCode = pinCode;
      }
      if (isActive != null) user.isActive = isActive;

      user.updatedAt = DateTime.now();

      // Update user in database
      print(
        '🧾 Updating user id=$userId name=${user.name} email=${user.email} role=${user.role} active=${user.isActive}',
      );
      final result = await DatabaseService.updateUser(user);
      print('✅ DatabaseService.updateUser result=$result');

      if (result != 0) {
        // Update the user in the observable list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = user;
        } else {
          // If not in the list, add it
          _users.add(user);
        }
        update();
        await SyncQueueService.instance.enqueueUserUpsert(user);
        return true;
      }

      throw Exception(
        'Échec de la mise à jour de l’utilisateur (la base a renvoyé 0)',
      );
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Toggle user activation status
  Future<bool> toggleUserActivation(int userId) async {
    try {
      final user = await DatabaseService.getUserById(userId);
      if (user == null) {
        throw Exception('Utilisateur introuvable');
      }

      // Toggle the active status
      user.isActive = !user.isActive;
      user.updatedAt = DateTime.now();

      final result = await DatabaseService.updateUser(user);

      if (result != 0) {
        // Update the user in the observable list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = user;
        }
        await SyncQueueService.instance.enqueueUserUpsert(user);
        return true;
      }

      return false;
    } catch (e) {
      print('Error toggling user activation: $e');
      rethrow;
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      final existing = await DatabaseService.getUserById(userId);
      final result = await DatabaseService.deleteUser(userId);

      if (result) {
        // Remove from the observable list
        _users.removeWhere((user) => user.id == userId);
        await SyncQueueService.instance.enqueueUserDelete(
          userId,
          email: existing?.email,
        );
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Validate PIN code format
  bool isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  // Get users by role
  List<User> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Get active users only
  List<User> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  // Get inactive users only
  List<User> getInactiveUsers() {
    return _users.where((user) => !user.isActive).toList();
  }
}
