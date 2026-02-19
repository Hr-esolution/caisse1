// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'helper/dependencies.dart' as dep;
import 'controllers/auth_controller.dart';
import 'seeders/database_seeder.dart';
import 'services/database_service.dart';
import 'services/image_cache_service.dart';
import 'bindings/catalog_binding.dart';
import 'theme/app_theme.dart';
import 'data/glass_theme.dart';
import 'views/login_screen.dart';
import 'views/registration_screen.dart';
import 'views/user_management_screen.dart';
import 'views/create_user_screen.dart';
import 'views/edit_user_screen.dart';
import 'views/import_data_screen.dart';
import 'views/product_catalog_screen.dart';
import 'views/pos_screen.dart';
import 'views/pos_lock_screen.dart';
import 'views/pos_choice_screen.dart';
import 'views/pos_table_plan_screen.dart';
import 'views/pos_staff_menu_screen.dart';
import 'views/pos_staff_orders_screen.dart';
import 'views/table_management_screen.dart';
import 'views/admin_dashboard_screen.dart';
import 'views/staff_dashboard_screen.dart';
import 'views/restaurant_management_screen.dart';
import 'views/admin_accounting_screen.dart';
import 'views/settings_screen.dart';
import 'views/splash_screen.dart';
import 'widgets/app_back_button.dart';
import 'theme/pos_scoped_theme.dart';
import 'controllers/import_controller.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database service first
  await DatabaseService.init();
  await ImageCacheService.instance.init();

  // Log database initialization
  print('Database initialized');

  final isSubWindow = args.isNotEmpty && args.first == 'multi_window';

  // Always run seeders on main window startup (debug/release/install).
  // Seeder is idempotent (firstOrCreate), so this is safe across restarts.
  if (!isSubWindow) {
    print('Running startup seeders...');
    await DatabaseSeeder.seed(DatabaseService.db);
    print('Startup seeders completed');
  }

  await dep.DependencyInjection.init(); // Initialize dependencies

  String initialRoute = isSubWindow ? '/pos' : '/';

  runApp(MyApp(initialRoute: initialRoute, isSubWindow: isSubWindow));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = '/', this.isSubWindow = false});

  final String initialRoute;
  final bool isSubWindow;

  @override
  Widget build(BuildContext context) {
    final appTheme = glassTheme();
    final posTheme = buildPosTheme(appTheme);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Système POS',
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        if (content is Scaffold && (content.appBar == null)) {
          content = SafeArea(top: true, bottom: false, child: content);
        } else if (content is! Scaffold) {
          content = SafeArea(top: true, bottom: false, child: content);
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(child: content),
            ],
          ),
        );
      },
      home: isSubWindow
          ? Theme(data: posTheme, child: const PosLockScreen())
          : null,
      theme: appTheme,
      initialRoute: isSubWindow ? '/pos-lock' : '/splash',
      getPages: [
        GetPage(name: '/', page: () => LoginScreen()),
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegistrationScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(
          name: '/admin-dashboard',
          page: () => const AdminDashboardScreen(),
        ),
        GetPage(
          name: '/staff-dashboard',
          page: () => const StaffDashboardScreen(),
        ),
        GetPage(
          name: '/pos',
          page: () => Theme(data: posTheme, child: const PosLockScreen()),
        ),
        GetPage(
          name: '/pos-lock',
          page: () => Theme(data: posTheme, child: const PosLockScreen()),
        ),
        GetPage(
          name: '/pos-menu',
          page: () => Theme(data: posTheme, child: const PosStaffMenuScreen()),
        ),
        GetPage(
          name: '/pos-choice',
          page: () => Theme(data: posTheme, child: const PosChoiceScreen()),
        ),
        GetPage(
          name: '/pos-tables',
          page: () => Theme(data: posTheme, child: const PosTablePlanScreen()),
        ),
        GetPage(
          name: '/pos-order',
          page: () => Theme(
            data: posTheme,
            child: const PosScreen(title: 'Tableau de bord POS'),
          ),
        ),
        GetPage(
          name: '/pos-orders',
          page: () =>
              Theme(data: posTheme, child: const PosStaffOrdersScreen()),
        ),
        GetPage(name: '/users', page: () => const UserManagementScreen()),
        GetPage(
          name: '/restaurants',
          page: () => const RestaurantManagementScreen(),
        ),
        GetPage(
          name: '/admin-accounting',
          page: () => const AdminAccountingScreen(),
        ),
        GetPage(name: '/tables', page: () => const TableManagementScreen()),
        GetPage(name: '/create-user', page: () => CreateUserScreen()),
        GetPage(name: '/edit-user', page: () => EditUserScreen()),
        GetPage(
          name: '/import-data',
          page: () => const ImportDataScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ImportController>()) {
              Get.lazyPut<ImportController>(() => ImportController());
            }
          }),
        ),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(
          name: '/catalog',
          page: () => const ProductCatalogScreen(),
          binding: CatalogBinding(),
        ),
      ],
    );
  }
}

// Home screen after login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloudDancer,
      appBar: AppBar(
        title: const Text('Tableau de Bord POS'),
        backgroundColor: AppColors.blancPur,
        foregroundColor: AppColors.charbon,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.terraCotta),
        leading: const AppBackButton(),
      ),
      drawer: _buildDrawer(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blancPur,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    Icon(Icons.store, size: 80, color: AppColors.terraCotta),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Bienvenue au Système POS',
                style: AppTypography.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sélectionnez une option dans le menu',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                alignment: WrapAlignment.center,
                children: [
                  _buildActionCard(
                    icon: Icons.point_of_sale,
                    title: 'Ouvrir le POS',
                    description:
                        "Accédez à l'interface de caisse sécurisée pour encaisser immédiatement.",
                    buttonLabel: 'Accéder au POS',
                    badgeColor: AppColors.terraCotta,
                    onPressed: () => Get.toNamed('/pos'),
                  ),
                  _buildActionCard(
                    icon: Icons.login,
                    title: 'Connexion',
                    description:
                        "Revenir à l'écran de connexion pour changer d'utilisateur.",
                    buttonLabel: 'Aller au login',
                    badgeColor: AppColors.bleuGris,
                    onPressed: () => Get.toNamed('/login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    Color badgeColor = AppColors.terraCotta,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.blancPur,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: AppColors.grisLeger),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Icon(icon, color: badgeColor, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.headline2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.blancPur,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.login,
            title: 'Connexion',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/login');
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_add,
            title: 'S\'inscrire',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/register');
            },
          ),
          _buildDrawerDivider(),
          _buildDrawerItem(
            icon: Icons.shopping_cart,
            title: 'Interface POS',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/pos');
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Gestion des Utilisateurs',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const UserManagementScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.inventory,
            title: 'Catalogue de Produits',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/catalog');
            },
          ),
          _buildDrawerItem(
            icon: Icons.sync,
            title: 'Importer les Données',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ImportDataScreen());
            },
          ),
          _buildDrawerDivider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Déconnexion',
            onTap: () async {
              Navigator.pop(context);
              await Get.find<AuthController>().logout();
              Get.offAllNamed('/login');
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.cloudDancer,
        border: Border(
          bottom: BorderSide(color: AppColors.grisLeger, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.terraCotta.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.store,
              size: 40,
              color: AppColors.terraCotta,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Système POS', style: AppTypography.headline2),
          const SizedBox(height: AppSpacing.xs),
          const Text('Gestion des restaurants', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.taupeDore : AppColors.terraCotta,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.taupeDore : AppColors.charbon,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: AppColors.cloudDancer.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildDrawerDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Divider(color: AppColors.grisLeger, height: 1),
    );
  }
}
