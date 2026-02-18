// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../models/pos_table.dart';
import '../services/image_cache_service.dart';
import '../utils/image_resolver_shared.dart';

class ApiImportService {
  final String baseUrl;
  String _authToken;
  final Map<int, int> _categoryIdMap = {};

  ApiImportService({required this.baseUrl, String authToken = ''})
    : _authToken = authToken;

  void updateAuthToken(String token) {
    _authToken = token.trim();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
  };

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _asTrimmedString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on') {
      return true;
    }
    if (normalized == '0' ||
        normalized == 'false' ||
        normalized == 'no' ||
        normalized == 'off') {
      return false;
    }
    return defaultValue;
  }

  DateTime _asDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Restaurant _restaurantFromApi(Map<String, dynamic> data) {
    final restaurant = Restaurant(
      name: _asTrimmedString(data['name']),
      address: _asTrimmedString(data['address']),
      phone: _asTrimmedString(data['phone']),
      isActive: _asBool(data['is_active'], defaultValue: true),
      createdAt: _asDate(data['created_at']),
      updatedAt: _asDate(data['updated_at']),
    );
    final remoteId = _asInt(data['id']);
    if (remoteId != null && remoteId > 0) {
      restaurant.id = remoteId;
    }
    return restaurant;
  }

  User _userFromApi(Map<String, dynamic> data, {User? existing}) {
    final hashedOrPlainPassword = _asTrimmedString(data['password']);
    String finalPassword = existing?.password ?? User.hashPassword('123456');
    if (hashedOrPlainPassword.isNotEmpty) {
      final looksSha256 =
          hashedOrPlainPassword.length == 64 &&
          RegExp(r'^[a-fA-F0-9]+$').hasMatch(hashedOrPlainPassword);
      finalPassword = looksSha256
          ? hashedOrPlainPassword
          : User.hashPassword(hashedOrPlainPassword);
    }

    final user = User(
      name: _asTrimmedString(data['name']),
      phone: _asTrimmedString(data['phone']),
      email: _asTrimmedString(data['email']),
      password: finalPassword,
      role: _asTrimmedString(data['role']).isEmpty
          ? (existing?.role ?? 'staff')
          : _asTrimmedString(data['role']),
      restaurantId: _asInt(data['restaurant_id']),
      pinCode: _asTrimmedString(data['pin_code']).isEmpty
          ? null
          : _asTrimmedString(data['pin_code']),
      isActive: _asBool(data['is_active'], defaultValue: true),
      createdAt: _asDate(data['created_at']),
      updatedAt: _asDate(data['updated_at']),
    );
    final remoteId = _asInt(data['id']);
    if (remoteId != null && remoteId > 0) {
      user.id = remoteId;
    }
    return user;
  }

  PosTable _tableFromApi(Map<String, dynamic> data) {
    return PosTable(
      remoteId: _asInt(data['id']),
      restaurantId: _asInt(data['restaurant_id']),
      number: _asTrimmedString(data['number']),
      status: _asTrimmedString(data['status']),
      gridColumnStart: _asInt(data['grid_column_start']) ?? 1,
      gridColumnEnd: _asInt(data['grid_column_end']) ?? 2,
      gridRowStart: _asInt(data['grid_row_start']) ?? 1,
      gridRowEnd: _asInt(data['grid_row_end']) ?? 2,
    );
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is! Map) return const [];

    final directKeys = ['data', 'items', 'results'];
    for (final key in directKeys) {
      final value = decoded[key];
      if (value is List) return value;
      if (value is Map && value['data'] is List) {
        return value['data'] as List;
      }
    }

    final entityKeys = [
      'users',
      'products',
      'categories',
      'restaurants',
      'tables',
    ];
    for (final key in entityKeys) {
      final value = decoded[key];
      if (value is List) return value;
      if (value is Map && value['data'] is List) {
        return value['data'] as List;
      }
    }

    // Laravel pagination shape: { success: true, data: { data: [...] } }
    if (decoded['data'] is Map) {
      final inner = decoded['data'];
      if (inner is Map && inner['data'] is List) {
        return inner['data'] as List;
      }
    }

    return const [];
  }

  Future<void> _ensureCategoryIdMapByName() async {
    if (_categoryIdMap.isNotEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: _headers,
      );
      if (response.statusCode != 200) return;
      final decoded = json.decode(response.body);
      final List<dynamic> categoriesData = _extractList(decoded);
      final localCategories = await DatabaseService.getAllCategories();
      final Map<String, int> nameToLocalId = {
        for (final c in localCategories) c.name: c.id,
      };

      for (final categoryData in categoriesData) {
        final apiId = _asInt(categoryData['id']);
        final name = _asTrimmedString(categoryData['name']);
        if (apiId == null || name.isEmpty) continue;
        final localId = nameToLocalId[name];
        if (localId != null) {
          _categoryIdMap[apiId] = localId;
        }
      }
    } catch (e) {
      print('⚠️ Unable to build category id map: $e');
    }
  }

  int _resolveLocalCategoryId(
    Map<String, dynamic> productData,
    Map<String, int> nameToLocalId,
  ) {
    final apiCategoryId =
        _asInt(productData['category_id']) ?? _asInt(productData['categoryId']);
    if (apiCategoryId != null && _categoryIdMap.containsKey(apiCategoryId)) {
      return _categoryIdMap[apiCategoryId]!;
    }

    String categoryName = _asTrimmedString(productData['category_name']);
    if (categoryName.isEmpty) {
      categoryName = _asTrimmedString(productData['categoryName']);
    }
    if (categoryName.isNotEmpty && nameToLocalId.containsKey(categoryName)) {
      return nameToLocalId[categoryName]!;
    }

    if (productData['category'] is Map) {
      final Map<String, dynamic> category = Map<String, dynamic>.from(
        productData['category'],
      );
      final embeddedName = _asTrimmedString(category['name']);
      if (embeddedName.isNotEmpty && nameToLocalId.containsKey(embeddedName)) {
        return nameToLocalId[embeddedName]!;
      }
      final embeddedApiId = _asInt(category['id']);
      if (embeddedApiId != null && _categoryIdMap.containsKey(embeddedApiId)) {
        return _categoryIdMap[embeddedApiId]!;
      }
    }

    return apiCategoryId ?? 0;
  }

  // Import categories from backend
  Future<bool> importCategories() async {
    try {
      print('🔍 Starting categories import...');
      print('🌐 Request URL: $baseUrl/api/categories');

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: _headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> categoriesData = _extractList(decoded);
        print('📊 Total categories received: ${categoriesData.length}');

        int createdCount = 0;
        int updatedCount = 0;

        final existingCategories = await DatabaseService.getAllCategories();
        final Map<String, Category> nameToCategory = {
          for (final c in existingCategories) c.name: c,
        };

        for (int i = 0; i < categoriesData.length; i++) {
          final categoryData = categoriesData[i];
          final categoryName = _asTrimmedString(categoryData['name']);
          if (categoryName.isEmpty) {
            print('⚠️ Skipping category with empty name');
            continue;
          }
          final apiCategoryId = _asInt(categoryData['id']);
          print(
            '📝 Processing category ${i + 1}/${categoriesData.length}: $categoryName',
          );

          // Convert API data to Category object
          final categoryImage =
              categoryData['image_url'] ?? categoryData['image'];
          final normalizedCategoryImage = normalizeImagePath(
            categoryImage?.toString(),
            baseUrl: baseUrl,
          );
          await ImageCacheService.instance.cacheImage(
            normalizedCategoryImage,
            baseUrl: baseUrl,
          );
          final category = Category(
            name: categoryName,
            image: normalizedCategoryImage,
            createdAt: DateTime.parse(
              categoryData['created_at'] ?? DateTime.now().toIso8601String(),
            ),
            updatedAt: DateTime.parse(
              categoryData['updated_at'] ?? DateTime.now().toIso8601String(),
            ),
          );

          // Check if category already exists by name
          final existingCategory = nameToCategory[category.name];

          if (existingCategory == null) {
            // Create new category
            final createdId = await DatabaseService.createCategory(category);
            category.id = createdId;
            nameToCategory[category.name] = category;
            if (apiCategoryId != null) {
              _categoryIdMap[apiCategoryId] = createdId;
            }
            createdCount++;
            print('✅ Created category: ${category.name}');
          } else {
            // Update existing category
            existingCategory.name = category.name;
            existingCategory.image = category.image;
            existingCategory.updatedAt = category.updatedAt;
            await DatabaseService.updateCategory(existingCategory);
            if (apiCategoryId != null) {
              _categoryIdMap[apiCategoryId] = existingCategory.id;
            }
            updatedCount++;
            print('🔄 Updated category: ${category.name}');
          }
        }

        print(
          '🎉 Categories import completed! Created: $createdCount, Updated: $updatedCount',
        );
        return true;
      } else {
        print('❌ Failed to load categories: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception(
          'Échec du chargement des catégories : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error importing categories: $e');
      print('Stack trace: ${e.runtimeType}');
      rethrow;
    }
  }

  // Import restaurants from backend
  Future<bool> importRestaurants() async {
    try {
      print('🔍 Starting restaurants import...');
      print('🌐 Request URL: $baseUrl/api/restaurants');

      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurants'),
        headers: _headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> restaurantsData = _extractList(decoded);
        print('📊 Total restaurants received: ${restaurantsData.length}');

        final existingRestaurants = await DatabaseService.getAllRestaurants();
        final byId = <int, Restaurant>{
          for (final restaurant in existingRestaurants)
            restaurant.id: restaurant,
        };
        final byName = <String, Restaurant>{
          for (final restaurant in existingRestaurants)
            restaurant.name.trim().toLowerCase(): restaurant,
        };

        int createdCount = 0;
        int updatedCount = 0;

        for (int i = 0; i < restaurantsData.length; i++) {
          final data = Map<String, dynamic>.from(restaurantsData[i]);
          final parsed = _restaurantFromApi(data);
          if (parsed.name.isEmpty) {
            print('⚠️ Skipping restaurant with empty name');
            continue;
          }

          final apiId = _asInt(data['id']);
          Restaurant? existing;
          if (apiId != null) {
            existing = byId[apiId];
          }
          existing ??= byName[parsed.name.trim().toLowerCase()];

          print(
            '📝 Processing restaurant ${i + 1}/${restaurantsData.length}: ${parsed.name}',
          );

          if (existing == null) {
            await DatabaseService.createRestaurant(parsed);
            if (apiId != null) {
              byId[apiId] = parsed;
            }
            byName[parsed.name.trim().toLowerCase()] = parsed;
            createdCount++;
            print('✅ Created restaurant: ${parsed.name}');
            continue;
          }

          if (apiId != null && existing.id != apiId) {
            await DatabaseService.deleteRestaurant(existing.id);
            parsed.id = apiId;
            await DatabaseService.createRestaurant(parsed);
          } else {
            parsed.id = existing.id;
            await DatabaseService.updateRestaurant(parsed);
          }

          if (apiId != null) {
            byId[apiId] = parsed;
          }
          byName[parsed.name.trim().toLowerCase()] = parsed;
          updatedCount++;
          print('🔄 Updated restaurant: ${parsed.name}');
        }

        print(
          '🎉 Restaurants import completed! Created: $createdCount, Updated: $updatedCount',
        );
        return true;
      } else {
        print('❌ Failed to load restaurants: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception(
          'Échec du chargement des restaurants : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error importing restaurants: $e');
      rethrow;
    }
  }

  // Import products from backend
  Future<bool> importProducts() async {
    try {
      print('🔍 Starting products import...');
      print('🌐 Request URL: $baseUrl/api/products');

      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: _headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> productsData = _extractList(decoded);
        print('📊 Total products received: ${productsData.length}');

        int createdCount = 0;
        int updatedCount = 0;

        await _ensureCategoryIdMapByName();
        final existingCategories = await DatabaseService.getAllCategories();
        final Map<String, int> nameToLocalCategoryId = {
          for (final c in existingCategories) c.name: c.id,
        };

        for (int i = 0; i < productsData.length; i++) {
          final productData = productsData[i];
          final apiProductId = _asInt(productData['id']);
          final productName = _asTrimmedString(productData['name']);
          if (productName.isEmpty ||
              apiProductId == null ||
              apiProductId <= 0) {
            print('⚠️ Skipping product with empty name');
            continue;
          }
          final localCategoryId = _resolveLocalCategoryId(
            productData,
            nameToLocalCategoryId,
          );
          print(
            '📝 Processing product ${i + 1}/${productsData.length}: $productName',
          );

          // Convert API data to Product object
          final productImage = productData['image_url'] ?? productData['image'];
          final normalizedProductImage = normalizeImagePath(
            productImage?.toString(),
            baseUrl: baseUrl,
          );
          await ImageCacheService.instance.cacheImage(
            normalizedProductImage,
            baseUrl: baseUrl,
          );
          final product = Product(
            id: apiProductId,
            name: productName,
            description: productData['description'],
            price: (productData['price'] is num)
                ? productData['price'].toDouble()
                : double.tryParse(productData['price'].toString()) ?? 0.0,
            image: normalizedProductImage,
            categoryId: localCategoryId,
            createdAt: DateTime.parse(
              productData['created_at'] ?? DateTime.now().toIso8601String(),
            ),
            updatedAt: DateTime.parse(
              productData['updated_at'] ?? DateTime.now().toIso8601String(),
            ),
          );

          // Set boolean values after creation since they have defaults
          if (productData['offer'] != null) {
            product.offer =
                productData['offer'] == 1 || productData['offer'] == true;
          }
          if (productData['is_available'] != null) {
            product.isAvailable =
                productData['is_available'] == 1 ||
                productData['is_available'] == true;
          }
          if (productData['sort_order'] != null) {
            product.sortOrder = productData['sort_order'];
          }

          final existingById = await DatabaseService.getProductById(
            apiProductId,
          );
          if (existingById != null) {
            existingById.name = product.name;
            existingById.description = product.description;
            existingById.price = product.price;
            existingById.image = product.image;
            existingById.categoryId = product.categoryId;
            existingById.offer = product.offer;
            existingById.isAvailable = product.isAvailable;
            existingById.sortOrder = product.sortOrder;
            existingById.updatedAt = product.updatedAt;
            await DatabaseService.updateProduct(existingById);
            updatedCount++;
            print('🔄 Updated product: ${product.name}');
            continue;
          }

          final existingByKey =
              await DatabaseService.getProductByNameAndCategory(
                product.name,
                product.categoryId,
              );
          if (existingByKey != null && existingByKey.id != apiProductId) {
            await DatabaseService.relinkOrderItemsProductId(
              fromId: existingByKey.id,
              toId: apiProductId,
            );
            await DatabaseService.deleteProduct(existingByKey.id);
          }

          await DatabaseService.createProduct(product);
          createdCount++;
          print('✅ Created product: ${product.name}');
        }

        print(
          '🎉 Products import completed! Created: $createdCount, Updated: $updatedCount',
        );
        return true;
      } else {
        print('❌ Failed to load products: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception(
          'Échec du chargement des produits : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error importing products: $e');
      print('Stack trace: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<bool> importUsers() async {
    try {
      print('🔍 Starting users import...');
      print('🌐 Request URL: $baseUrl/api/users');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: _headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> usersData = _extractList(decoded);
        print('📊 Total users received: ${usersData.length}');

        int createdCount = 0;
        int updatedCount = 0;

        final existingUsers = await DatabaseService.getAllUsers();
        final byId = <int, User>{for (final u in existingUsers) u.id: u};
        final byEmail = <String, User>{
          for (final u in existingUsers) u.email.trim().toLowerCase(): u,
        };

        for (int i = 0; i < usersData.length; i++) {
          final data = Map<String, dynamic>.from(usersData[i]);
          final email = _asTrimmedString(data['email']).toLowerCase();
          final apiId = _asInt(data['id']);
          if (email.isEmpty) {
            print('⚠️ Skipping user with empty email');
            continue;
          }

          User? existing;
          if (apiId != null) {
            existing = byId[apiId];
          }
          existing ??= byEmail[email];

          final parsed = _userFromApi(data, existing: existing);
          if (parsed.name.isEmpty) {
            print('⚠️ Skipping user with empty name: $email');
            continue;
          }

          if (existing == null) {
            await DatabaseService.createUser(parsed);
            if (apiId != null) {
              byId[apiId] = parsed;
            }
            byEmail[email] = parsed;
            createdCount++;
            print('✅ Created user: ${parsed.email}');
            continue;
          }

          if (apiId != null && existing.id != apiId) {
            await DatabaseService.deleteUser(existing.id);
            parsed.id = apiId;
            await DatabaseService.createUser(parsed);
          } else {
            parsed.id = existing.id;
            await DatabaseService.updateUser(parsed);
          }
          if (apiId != null) {
            byId[apiId] = parsed;
          }
          byEmail[email] = parsed;
          updatedCount++;
          print('🔄 Updated user: ${parsed.email}');
        }

        print(
          '🎉 Users import completed! Created: $createdCount, Updated: $updatedCount',
        );
        return true;
      } else {
        print('❌ Failed to load users: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception(
          'Échec du chargement des users : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error importing users: $e');
      rethrow;
    }
  }

  // Import both categories and products
  Future<bool> importAllData() async {
    try {
      print('🚀 Starting full data import...');

      final categoriesSuccess = await importCategories();
      if (!categoriesSuccess) {
        print('⚠️ Categories import failed, stopping import process');
        return false;
      }

      final productsSuccess = await importProducts();
      if (!productsSuccess) {
        print('⚠️ Products import failed, stopping import process');
        return false;
      }

      print('🎉 Full data import completed successfully!');
      return true;
    } catch (e) {
      print('💥 Error importing all data: $e');
      rethrow;
    }
  }

  // Test connection to API
  Future<bool> testConnection() async {
    try {
      print('🔌 Testing connection to: $baseUrl/api/categories');

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: _headers,
      );

      print('🔌 Connection test result: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '📊 Sample data: ${data.length > 0 ? data[0]['name'] : 'No data'}',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  // Get a specific restaurant from backend
  Future<Map<String, dynamic>?> getRestaurant(int restaurantId) async {
    try {
      print('🔍 Fetching restaurant ID: $restaurantId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurants/$restaurantId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to load restaurant: ${response.statusCode}');
        throw Exception(
          'Échec du chargement du restaurant : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error getting restaurant: $e');
      rethrow;
    }
  }

  // Get all restaurants from backend
  Future<List<Map<String, dynamic>>?> getAllRestaurants() async {
    try {
      print('🔍 Fetching all restaurants');

      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurants'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final restaurantsData = _extractList(decoded);
        return restaurantsData
            .map((raw) => Map<String, dynamic>.from(raw))
            .toList();
      } else {
        print('❌ Failed to load restaurants: ${response.statusCode}');
        throw Exception(
          'Échec du chargement des restaurants : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error getting restaurants: $e');
      rethrow;
    }
  }

  // Import tables from backend
  Future<bool> importTables({int? restaurantId}) async {
    try {
      final query = restaurantId == null ? '' : '?restaurant_id=$restaurantId';
      final response = await http.get(
        Uri.parse('$baseUrl/api/tables$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> tablesData = _extractList(decoded);
        final existingTables = restaurantId == null
            ? await DatabaseService.getPosTables()
            : await DatabaseService.getPosTablesByRestaurant(restaurantId);
        final Map<String, PosTable> byKey = {
          for (final t in existingTables)
            '${t.remoteId ?? 'local'}|${t.restaurantId}|${t.number}': t,
        };

        for (final raw in tablesData) {
          final data = Map<String, dynamic>.from(raw);
          final table = _tableFromApi(data);
          if (table.number.isEmpty || table.restaurantId == null) {
            continue;
          }

          PosTable? existing;
          if (table.remoteId != null) {
            existing = await DatabaseService.getPosTableByRemoteId(
              table.remoteId!,
            );
          }
          existing ??= await DatabaseService.getPosTableByNumberAndRestaurant(
            table.number,
            table.restaurantId,
          );
          existing ??=
              byKey['${table.remoteId ?? 'local'}|${table.restaurantId}|${table.number}'];

          if (existing == null) {
            await DatabaseService.createPosTable(table);
          } else {
            table.id = existing.id;
            await DatabaseService.updatePosTable(table);
          }
        }
        return true;
      }
      throw Exception(
        'Échec du chargement des tables : ${response.statusCode}',
      );
    } catch (e) {
      print('💥 Error importing tables: $e');
      rethrow;
    }
  }

  Future<PosTable?> createTable({
    required String number,
    required String status,
    required int restaurantId,
    required int gridColumnStart,
    required int gridColumnEnd,
    required int gridRowStart,
    required int gridRowEnd,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tables'),
        headers: _headers,
        body: json.encode({
          'number': number,
          'status': status,
          'restaurant_id': restaurantId,
          'grid_column_start': gridColumnStart,
          'grid_column_end': gridColumnEnd,
          'grid_row_start': gridRowStart,
          'grid_row_end': gridRowEnd,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data is Map && data['data'] is Map) {
          return _tableFromApi(Map<String, dynamic>.from(data['data']));
        }
      }
      throw Exception('Échec de la création de la table');
    } catch (e) {
      print('💥 Error creating table: $e');
      rethrow;
    }
  }

  Future<PosTable?> updateTable({
    required int remoteId,
    required String number,
    required String status,
    required int gridColumnStart,
    required int gridColumnEnd,
    required int gridRowStart,
    required int gridRowEnd,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/tables/$remoteId'),
        headers: _headers,
        body: json.encode({
          'number': number,
          'status': status,
          'grid_column_start': gridColumnStart,
          'grid_column_end': gridColumnEnd,
          'grid_row_start': gridRowStart,
          'grid_row_end': gridRowEnd,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['data'] is Map) {
          return _tableFromApi(Map<String, dynamic>.from(data['data']));
        }
      }
      throw Exception('Échec de la mise à jour de la table');
    } catch (e) {
      print('💥 Error updating table: $e');
      rethrow;
    }
  }

  Future<void> deleteTable({required int remoteId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/tables/$remoteId'),
        headers: _headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Échec de la suppression de la table');
    } catch (e) {
      print('💥 Error deleting table: $e');
      rethrow;
    }
  }

  Future<PosTable?> changeTableStatus({
    required int remoteId,
    required String status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/tables/$remoteId/status'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['data'] is Map) {
          return _tableFromApi(Map<String, dynamic>.from(data['data']));
        }
      }
      throw Exception('Échec de la mise à jour du statut');
    } catch (e) {
      print('💥 Error changing table status: $e');
      rethrow;
    }
  }
}
