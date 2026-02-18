import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// UserSeeder - Equivalent to Laravel UserSeeder
/// Seeds the User collection with default users
/// Follows firstOrCreate pattern to prevent duplicates
class UserSeeder {
  /// Static method to seed the User collection
  /// Checks if users already exist by email before creating
  static Future<void> seed(Isar isar) async {
    debugPrint('Starting UserSeeder...');
    final existingCount = await isar.users.count();
    debugPrint('Existing users count: $existingCount');

    // Define the default users to seed
    final usersToSeed = [
      // Superadmin user (no restaurantId, no pinCode)
      User(
        name: 'Super Admin',
        phone: '+1234567890',
        email: 'superadmin@example.com',
        password: User.hashPassword('password123'),
        role: 'superadmin',
        restaurantId: null, // No restaurant for superadmin
        pinCode: null, // No pin code for superadmin
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // Admin user (with restaurantId)
      User(
        name: 'Admin User',
        phone: '+1987654321',
        email: 'admin@example.com',
        password: User.hashPassword('password123'),
        role: 'admin',
        restaurantId: 1, // Assigned to restaurant ID 1
        pinCode: null, // No pin code for admin
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // Staff user (with restaurantId and pinCode)
      User(
        name: 'Staff Member',
        phone: '+1555123456',
        email: 'staff@example.com',
        password: User.hashPassword('password123'),
        role: 'staff',
        restaurantId: 1, // Assigned to restaurant ID 1
        pinCode: '1234', // Required 4-digit pin code for staff
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // Client user (no pinCode)
      User(
        name: 'Regular Client',
        phone: '+1555987654',
        email: 'client@example.com',
        password: User.hashPassword('password123'),
        role: 'client',
        restaurantId: null, // Clients may not have restaurant association
        pinCode: null, // No pin code for clients
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Process each user using firstOrCreate pattern
    for (final userData in usersToSeed) {
      await _createUserIfNotExists(isar, userData);
    }

    final finalCount = await isar.users.count();
    debugPrint('Final users count: $finalCount');
    debugPrint('UserSeeder completed successfully!');
  }

  /// Helper method that implements firstOrCreate pattern
  /// Checks if a user with the given email exists, creates if not
  static Future<void> _createUserIfNotExists(Isar isar, User userData) async {
    // Query for existing user by email
    final existingUser = await isar.users
        .where()
        .filter()
        .emailEqualTo(userData.email)
        .findFirst();

    if (existingUser == null) {
      // User doesn't exist, create it
      await isar.writeTxn(() async {
        final userId = await isar.users.put(userData);
        debugPrint('Created user: ${userData.name} (${userData.email}) with ID: $userId');
      });
    } else {
      // User already exists
      debugPrint('User already exists: ${userData.name} (${userData.email}), skipping...');
    }
  }
}

/*
 * Comparison with Laravel equivalent:
 * 
 * Laravel PHP:
 * User::firstOrCreate([
 *     'email' => $email
 * ], [
 *     'name' => $name,
 *     'password' => bcrypt($password),
 *     ...
 * ]);
 * 
 * Isar Dart equivalent:
 * final existingUser = await isar.users.where().emailEqualTo(email).findFirst();
 * if (existingUser == null) {
 *     await isar.writeTxn(() async {
 *         await isar.users.put(user);
 *     });
 * }
 */
