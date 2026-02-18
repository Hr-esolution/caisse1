import 'package:caisse_1/api/api_client.dart';
import 'package:caisse_1/controllers/auth_controller.dart';
import 'package:caisse_1/controllers/category_controller.dart';
import 'package:caisse_1/controllers/import_controller.dart';
import 'package:caisse_1/controllers/product_controller.dart';
import 'package:caisse_1/controllers/restaurant_controller.dart';
import 'package:caisse_1/controllers/settings_controller.dart';
import 'package:caisse_1/controllers/sync_controller.dart';
import 'package:caisse_1/controllers/table_controller.dart';
import 'package:caisse_1/controllers/user_controller.dart';
import 'package:caisse_1/controllers/pos_controller.dart';
import 'package:caisse_1/data/app_constants.dart';
import 'package:caisse_1/repos/category_repo.dart';
import 'package:caisse_1/repos/product_repo.dart';
import 'package:caisse_1/services/auth_session_service.dart';
import 'package:caisse_1/services/app_settings_service.dart';
import 'package:caisse_1/services/api_order_pull_service.dart';
import 'package:caisse_1/services/notification_sound_service.dart';
import 'package:caisse_1/services/sync_queue_service.dart';
import 'package:get/get.dart';

class DependencyInjection {
  static Future<void> init() async {
    await AuthSessionService.instance.init();
    await AppSettingsService.instance.init();
    final startupToken = AuthSessionService.instance.token.isNotEmpty
        ? AuthSessionService.instance.token
        : AppConstant.apiToken;

    // Initialize services
    // DatabaseService.init(); // This is called in each controller's onInit

    // Api Client
    Get.put(ApiClient(appBaseUrl: AppConstant.baseUrl, token: startupToken));

    // Repositories
    Get.put(CategoryRepo(apiClient: Get.find()));
    Get.put(ProductRepo(apiClient: Get.find()));

    // Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<UserController>(UserController(), permanent: true);
    Get.put<RestaurantController>(RestaurantController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
    Get.put<CategoryController>(CategoryController());
    Get.put<ProductController>(ProductController());
    Get.lazyPut<ImportController>(() => ImportController());
    Get.lazyPut<TableController>(() => TableController());
    Get.put<PosController>(PosController(), permanent: true);

    await SyncQueueService.instance.init(
      baseUrl: AppConstant.baseUrl,
      authToken: startupToken,
    );
    await ApiOrderPullService.instance.init(
      baseUrl: AppConstant.baseUrl,
      authToken: startupToken,
    );
    await NotificationSoundService.instance.init();
    await SyncQueueService.instance.queueUnsyncedOrders();
    await SyncQueueService.instance.flushQueue();
    Get.put<SyncController>(SyncController(), permanent: true);
  }
}
