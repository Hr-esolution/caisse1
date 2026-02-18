// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../models/restaurant.dart';
import '../services/database_service.dart';

class RestaurantController extends GetxController {
  static RestaurantController get instance => Get.find();

  final RxList<Restaurant> _restaurants = <Restaurant>[].obs;
  List<Restaurant> get restaurants => _restaurants.toList();
  final RxnInt _selectedRestaurantId = RxnInt();
  int? get selectedRestaurantId => _selectedRestaurantId.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize database when the controller is ready
    DatabaseService.init();
    fetchAllRestaurants();
  }

  Future<void> fetchAllRestaurants() async {
    try {
      final restaurants = await DatabaseService.getAllRestaurants();
      _restaurants.assignAll(restaurants);
      if (_selectedRestaurantId.value == null && restaurants.isNotEmpty) {
        _selectedRestaurantId.value = restaurants.first.id;
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      rethrow;
    }
  }

  void setSelectedRestaurantId(int? id) {
    _selectedRestaurantId.value = id;
  }

  // Create a new restaurant
  Future<bool> createRestaurant({
    required String name,
    required String address,
    required String phone,
    bool isActive = true,
  }) async {
    try {
      // Create new restaurant
      final newRestaurant = Restaurant(
        name: name,
        address: address,
        phone: phone,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save restaurant to database
      final restaurantId = await DatabaseService.createRestaurant(
        newRestaurant,
      );

      if (restaurantId != 0) {
        _restaurants.add(newRestaurant);
        return true;
      }

      return false;
    } catch (e) {
      print('Error creating restaurant: $e');
      rethrow;
    }
  }

  // Update restaurant
  Future<bool> updateRestaurant({
    required int restaurantId,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      // Get the restaurant from database
      final restaurant = await DatabaseService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        throw Exception('Restaurant introuvable');
      }

      // Update fields if provided
      if (name != null) restaurant.name = name;
      if (address != null) restaurant.address = address;
      if (phone != null) restaurant.phone = phone;
      if (isActive != null) restaurant.isActive = isActive;

      restaurant.updatedAt = DateTime.now();

      // Update restaurant in database
      final result = await DatabaseService.updateRestaurant(restaurant);

      if (result != 0) {
        // Update the restaurant in the observable list
        final index = _restaurants.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
          _restaurants[index] = restaurant;
        } else {
          // If not in the list, add it
          _restaurants.add(restaurant);
        }
        return true;
      }

      return false;
    } catch (e) {
      print('Error updating restaurant: $e');
      rethrow;
    }
  }

  // Toggle restaurant activation status
  Future<bool> toggleRestaurantActivation(int restaurantId) async {
    try {
      final restaurant = await DatabaseService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        throw Exception('Restaurant introuvable');
      }

      // Toggle the active status
      restaurant.isActive = !restaurant.isActive;
      restaurant.updatedAt = DateTime.now();

      final result = await DatabaseService.updateRestaurant(restaurant);

      if (result != 0) {
        // Update the restaurant in the observable list
        final index = _restaurants.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
          _restaurants[index] = restaurant;
        }
        return true;
      }

      return false;
    } catch (e) {
      print('Error toggling restaurant activation: $e');
      rethrow;
    }
  }

  Future<bool> deleteRestaurant(int restaurantId) async {
    try {
      final result = await DatabaseService.deleteRestaurant(restaurantId);
      if (result) {
        _restaurants.removeWhere((r) => r.id == restaurantId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting restaurant: $e');
      rethrow;
    }
  }

  // Get active restaurants only
  List<Restaurant> getActiveRestaurants() {
    return _restaurants.where((restaurant) => restaurant.isActive).toList();
  }

  // Get inactive restaurants only
  List<Restaurant> getInactiveRestaurants() {
    return _restaurants.where((restaurant) => !restaurant.isActive).toList();
  }
}
