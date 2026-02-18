// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../models/product_model.dart';

import '../services/database_service.dart';
import '../services/sync_queue_service.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  final RxList<Product> _products = <Product>[].obs;
  List<Product> get products => _products.toList();

  @override
  void onInit() {
    super.onInit();
    // Initialize database when the controller is ready
    DatabaseService.init();
    fetchAllProducts();
  }

  Future<void> fetchAllProducts() async {
    try {
      final products = await DatabaseService.getAllProducts();
      _products.assignAll(products);
      update();
    } catch (e) {
      print('Error fetching products: $e');
      update();
      rethrow;
    }
  }

  // Create a new product
  Future<bool> createProduct({
    required String name,
    String? description,
    required double price,
    String? image,
    required int categoryId,
    bool offer = false,
    bool isAvailable = true,
    int sortOrder = 0,
  }) async {
    try {
      // Create new product
      final newProduct = Product(
        name: name,
        description: description,
        price: price,
        image: image,
        categoryId: categoryId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set the boolean properties after creation since they have defaults
      newProduct.offer = offer;
      newProduct.isAvailable = isAvailable;
      newProduct.sortOrder = sortOrder;

      // Save product to database
      final productId = await DatabaseService.createProduct(newProduct);

      if (productId != 0) {
        _products.add(newProduct);
        await SyncQueueService.instance.enqueueProductUpsert(newProduct);
        update();
        return true;
      }

      return false;
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Update product
  Future<bool> updateProduct({
    required int productId,
    String? name,
    String? description,
    double? price,
    String? image,
    int? categoryId,
    bool? offer,
    bool? isAvailable,
    int? sortOrder,
  }) async {
    try {
      // Get the product from database
      final product = await DatabaseService.getProductById(productId);
      if (product == null) {
        throw Exception('Produit introuvable');
      }

      // Update fields if provided
      if (name != null) product.name = name;
      if (description != null) product.description = description;
      if (price != null) product.price = price;
      if (image != null) product.image = image;
      if (categoryId != null) product.categoryId = categoryId;
      if (offer != null) product.offer = offer;
      if (isAvailable != null) product.isAvailable = isAvailable;
      if (sortOrder != null) product.sortOrder = sortOrder;

      product.updatedAt = DateTime.now();

      // Update product in database
      final result = await DatabaseService.updateProduct(product);

      if (result != 0) {
        // Update the product in the observable list
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = product;
        } else {
          // If not in the list, add it
          _products.add(product);
        }
        await SyncQueueService.instance.enqueueProductUpsert(product);
        update();
        return true;
      }

      return false;
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    return _products
        .where(
          (product) => product.categoryId == categoryId && product.isAvailable,
        )
        .toList();
  }

  // Get available products only
  List<Product> getAvailableProducts() {
    return _products.where((product) => product.isAvailable).toList();
  }

  // Get products on offer
  List<Product> getProductsOnOffer() {
    return _products.where((product) => product.offer).toList();
  }

  // Delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      final result = await DatabaseService.deleteProduct(productId);

      if (result) {
        // Remove from the observable list
        _products.removeWhere((product) => product.id == productId);
        await SyncQueueService.instance.enqueueProductDelete(productId);
        update();
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}
