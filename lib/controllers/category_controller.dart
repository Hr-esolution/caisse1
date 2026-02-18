import 'package:caisse_1/controllers/product_controller.dart';

// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../services/sync_queue_service.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  final RxList<Category> _categories = <Category>[].obs;
  final Rx<Category?> _selectedCategory = Rx<Category?>(null);
  final RxBool _isLoaded = false.obs;
  List<Category> get categories => _categories.toList();
  Rx<Category?> get selectedCategory => _selectedCategory;
  RxBool get isLoaded => _isLoaded;

  @override
  void onInit() {
    super.onInit();
    // Initialize database when the controller is ready
    DatabaseService.init();
    fetchAllCategories();
  }

  Future<void> fetchAllCategories() async {
    try {
      final categories = await DatabaseService.getAllCategories();
      _categories.assignAll(categories);

      if (categories.isEmpty) {
        _selectedCategory.value = null;
      } else {
        final selectedId = _selectedCategory.value?.id;
        final selectedExists =
            selectedId != null &&
            categories.any((category) => category.id == selectedId);
        if (!selectedExists) {
          _selectedCategory.value = categories.first;
        }
      }

      _isLoaded.value = true;
      update();
    } catch (e) {
      print('Error fetching categories: $e');
      _isLoaded.value = true; // Still set to loaded even if there's an error
      update();
      rethrow;
    }
  }

  // Create a new category
  Future<bool> createCategory({required String name, String? image}) async {
    try {
      // Create new category
      final newCategory = Category(
        name: name,
        image: image,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save category to database
      final categoryId = await DatabaseService.createCategory(newCategory);

      if (categoryId != 0) {
        _categories.add(newCategory);
        await SyncQueueService.instance.enqueueCategoryUpsert(newCategory);
        update();
        return true;
      }

      return false;
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  // Update category
  Future<bool> updateCategory({
    required int categoryId,
    String? name,
    String? image,
    bool? isDeleted,
  }) async {
    try {
      // Get the category from database
      final category = await DatabaseService.getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Catégorie introuvable');
      }

      // Update fields if provided
      if (name != null) category.name = name;
      if (image != null) category.image = image;
      if (isDeleted != null) category.isDeleted = isDeleted;

      category.updatedAt = DateTime.now();

      // Update category in database
      final result = await DatabaseService.updateCategory(category);

      if (result != 0) {
        // Update the category in the observable list
        final index = _categories.indexWhere((c) => c.id == categoryId);
        if (index != -1) {
          _categories[index] = category;
        } else {
          // If not in the list, add it
          _categories.add(category);
        }
        await SyncQueueService.instance.enqueueCategoryUpsert(category);
        update();
        return true;
      }

      return false;
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Get active categories only
  List<Category> getActiveCategories() {
    return _categories.where((category) => !category.isDeleted).toList();
  }

  // Get deleted categories only
  List<Category> getDeletedCategories() {
    return _categories.where((category) => category.isDeleted).toList();
  }

  // Soft delete category
  Future<bool> deleteCategory(int categoryId) async {
    try {
      final category = await DatabaseService.getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Catégorie introuvable');
      }

      // Set isDeleted to true instead of actually deleting
      category.isDeleted = true;
      category.updatedAt = DateTime.now();

      final result = await DatabaseService.updateCategory(category);

      if (result != 0) {
        // Update the category in the observable list
        final index = _categories.indexWhere((c) => c.id == categoryId);
        if (index != -1) {
          _categories[index] = category;
        }
        await SyncQueueService.instance.enqueueCategoryUpsert(category);
        update();
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Permanently delete category
  Future<bool> permanentlyDeleteCategory(int categoryId) async {
    // Note: ISAR doesn't have a direct way to permanently delete with schema
    // We'll rely on soft deletion for now
    return await deleteCategory(categoryId);
  }

  // Select a category
  void selectCategory(Category category) {
    _selectedCategory.value = category;
    update();
  }

  // Get products for the selected category
  List<Product> get products {
    if (_selectedCategory.value == null) return [];
    return Get.find<ProductController>().getProductsByCategory(
      _selectedCategory.value!.id,
    );
  }
}
