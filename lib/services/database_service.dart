import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/restaurant.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../models/pos_table.dart';

class DatabaseService {
  static late Isar _isar;

  static Future<void> init() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([
        UserSchema,
        RestaurantSchema,
        CategorySchema,
        ProductSchema,
        PosOrderSchema,
        PosOrderItemSchema,
        PosTableSchema,
      ], directory: dir.path);
    } else {
      _isar = Isar.getInstance()!;
    }
  }

  static Isar get db => _isar;

  // User methods
  static Future<int> createUser(User user) async {
    return await _isar.writeTxn(() async {
      return await _isar.users.put(user);
    });
  }

  static Future<User?> getUserById(int id) async {
    return await _isar.users.where().idEqualTo(id).findFirst();
  }

  static Future<User?> getUserByEmail(String email) async {
    return await _isar.users.filter().emailEqualTo(email).findFirst();
  }

  static Future<User?> getUserByPhone(String phone) async {
    return await _isar.users.filter().phoneEqualTo(phone).findFirst();
  }

  static Future<User?> getStaffByPin(String pin) async {
    final users = await _isar.users
        .filter()
        .pinCodeEqualTo(pin)
        .isActiveEqualTo(true)
        .findAll();
    for (final user in users) {
      if (user.role == 'staff' ||
          user.role == 'admin' ||
          user.role == 'superadmin') {
        return user;
      }
    }
    return null;
  }

  static Future<List<User>> getAllUsers() async {
    return await _isar.users.where().findAll();
  }

  static Future<List<User>> getUsersByRestaurant(int? restaurantId) async {
    if (restaurantId == null) {
      return await getAllUsers();
    }
    return await _isar.users
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .findAll();
  }

  static Future<int> updateUser(User user) async {
    return await _isar.writeTxn(() async {
      return await _isar.users.put(user);
    });
  }

  static Future<bool> deleteUser(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.users.delete(id);
    });
  }

  // Restaurant methods
  static Future<int> createRestaurant(Restaurant restaurant) async {
    return await _isar.writeTxn(() async {
      return await _isar.restaurants.put(restaurant);
    });
  }

  static Future<Restaurant?> getRestaurantById(int id) async {
    return await _isar.restaurants.where().idEqualTo(id).findFirst();
  }

  static Future<List<Restaurant>> getAllRestaurants() async {
    return await _isar.restaurants.where().findAll();
  }

  static Future<int> updateRestaurant(Restaurant restaurant) async {
    return await _isar.writeTxn(() async {
      return await _isar.restaurants.put(restaurant);
    });
  }

  static Future<bool> deleteRestaurant(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.restaurants.delete(id);
    });
  }

  // Category methods
  static Future<int> createCategory(Category category) async {
    return await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
  }

  static Future<Category?> getCategoryById(int id) async {
    return await _isar.categorys.where().idEqualTo(id).findFirst();
  }

  static Future<List<Category>> getAllCategories() async {
    return await _isar.categorys.where().findAll();
  }

  static Future<int> updateCategory(Category category) async {
    return await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
  }

  // Product methods
  static Future<int> createProduct(Product product) async {
    return await _isar.writeTxn(() async {
      return await _isar.products.put(product);
    });
  }

  static Future<Product?> getProductById(int id) async {
    return await _isar.products.where().idEqualTo(id).findFirst();
  }

  static Future<Product?> getProductByNameAndCategory(
    String name,
    int categoryId,
  ) async {
    return await _isar.products
        .filter()
        .nameEqualTo(name)
        .categoryIdEqualTo(categoryId)
        .findFirst();
  }

  static Future<Product?> getProductByName(String name) async {
    return await _isar.products.filter().nameEqualTo(name).findFirst();
  }

  static Future<List<Product>> getAllProducts() async {
    return await _isar.products.where().findAll();
  }

  static Future<int> updateProduct(Product product) async {
    return await _isar.writeTxn(() async {
      return await _isar.products.put(product);
    });
  }

  static Future<bool> deleteProduct(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.products.delete(id);
    });
  }

  static Future<void> relinkOrderItemsProductId({
    required int fromId,
    required int toId,
  }) async {
    if (fromId == toId) return;
    await _isar.writeTxn(() async {
      final items = await _isar.posOrderItems
          .filter()
          .productIdEqualTo(fromId)
          .findAll();
      for (final item in items) {
        item.productId = toId;
      }
      if (items.isNotEmpty) {
        await _isar.posOrderItems.putAll(items);
      }
    });
  }

  // POS Order methods
  static Future<int> createPosOrder(PosOrder order) async {
    return await _isar.writeTxn(() async {
      return await _isar.posOrders.put(order);
    });
  }

  static Future<int> updatePosOrder(PosOrder order) async {
    return await _isar.writeTxn(() async {
      return await _isar.posOrders.put(order);
    });
  }

  static Future<PosOrder?> getPosOrderById(int id) async {
    return await _isar.posOrders.where().idEqualTo(id).findFirst();
  }

  static Future<List<PosOrder>> getPosOrders() async {
    return await _isar.posOrders.where().sortByCreatedAtDesc().findAll();
  }

  static Future<List<PosOrder>> getPosOrdersByStatus(String status) async {
    return await _isar.posOrders.filter().statusEqualTo(status).findAll();
  }

  static Future<List<PosOrder>> getPosOrdersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _isar.posOrders
        .filter()
        .createdAtBetween(start, end)
        .sortByCreatedAtDesc()
        .findAll();
  }

  static Future<PosOrder?> findSimilarLocalPosOrder({
    required DateTime createdAt,
    required double totalPrice,
    String? tableNumber,
    String? fulfillmentType,
    String channel = 'pos',
    Duration tolerance = const Duration(minutes: 2),
    double totalTolerance = 0.01,
  }) async {
    final start = createdAt.subtract(tolerance);
    final end = createdAt.add(tolerance);
    final lowerTotal = totalPrice - totalTolerance;
    final upperTotal = totalPrice + totalTolerance;

    var query = _isar.posOrders
        .filter()
        .channelEqualTo(channel, caseSensitive: false)
        .createdAtBetween(start, end)
        .totalPriceBetween(lowerTotal, upperTotal);

    if (tableNumber != null && tableNumber.trim().isNotEmpty) {
      query = query.tableNumberEqualTo(tableNumber.trim());
    }
    if (fulfillmentType != null && fulfillmentType.trim().isNotEmpty) {
      query = query.fulfillmentTypeEqualTo(fulfillmentType.trim());
    }
    return await query.findFirst();
  }

  // POS Order Items
  static Future<int> createPosOrderItem(PosOrderItem item) async {
    return await _isar.writeTxn(() async {
      return await _isar.posOrderItems.put(item);
    });
  }

  static Future<List<PosOrderItem>> getPosOrderItems(int orderId) async {
    return await _isar.posOrderItems.filter().orderIdEqualTo(orderId).findAll();
  }

  static Future<int> updatePosOrderItem(PosOrderItem item) async {
    return await _isar.writeTxn(() async {
      return await _isar.posOrderItems.put(item);
    });
  }

  static Future<bool> deletePosOrder(int orderId) async {
    return await _isar.writeTxn(() async {
      final deletedItems = await deletePosOrderItems(orderId);
      final deletedOrder = await _isar.posOrders.delete(orderId);
      return deletedItems && deletedOrder;
    });
  }

  static Future<bool> deletePosOrderItems(int orderId) async {
    return await _isar.writeTxn(() async {
      final items = await _isar.posOrderItems
          .filter()
          .orderIdEqualTo(orderId)
          .findAll();
      final ids = items.map((e) => e.id).toList();
      final deletedCount = await _isar.posOrderItems.deleteAll(ids);
      return deletedCount == ids.length;
    });
  }

  static Future<double> getStaffDailySales(int staffId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final orders = await _isar.posOrders
        .filter()
        .staffIdEqualTo(staffId)
        .createdAtBetween(start, end)
        .findAll();
    return orders.fold<double>(0.0, (sum, o) => sum + o.totalPrice);
  }

  // POS Tables
  static Future<List<PosTable>> getPosTables() async {
    return await _isar.posTables.where().sortByNumber().findAll();
  }

  static Future<List<PosTable>> getPosTablesByRestaurant(
    int restaurantId,
  ) async {
    return await _isar.posTables
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .sortByNumber()
        .findAll();
  }

  static Future<PosTable?> getPosTableByRemoteId(int remoteId) async {
    return await _isar.posTables.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  static Future<PosTable?> getPosTableByNumberAndRestaurant(
    String number,
    int? restaurantId,
  ) async {
    return await _isar.posTables
        .filter()
        .numberEqualTo(number)
        .restaurantIdEqualTo(restaurantId)
        .findFirst();
  }

  static Future<int> createPosTable(PosTable table) async {
    return await _isar.writeTxn(() async {
      return await _isar.posTables.put(table);
    });
  }

  static Future<int> updatePosTable(PosTable table) async {
    return await _isar.writeTxn(() async {
      return await _isar.posTables.put(table);
    });
  }

  static Future<bool> deletePosTable(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.posTables.delete(id);
    });
  }

  static Future<bool> deletePosTableByRemoteId(int remoteId) async {
    return await _isar.writeTxn(() async {
      final table = await _isar.posTables
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
      if (table == null) return false;
      return await _isar.posTables.delete(table.id);
    });
  }

  // Clear local POS/catalog data while keeping users for login access.
  static Future<void> clearLocalBusinessData() async {
    await _isar.writeTxn(() async {
      await _isar.posOrderItems.clear();
      await _isar.posOrders.clear();
      await _isar.posTables.clear();
      await _isar.products.clear();
      await _isar.categorys.clear();
      await _isar.restaurants.clear();
    });
  }
}
