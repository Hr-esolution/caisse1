import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('SOYABOX POS CAISSE'),
        backgroundColor: GlassColors.glassWhite.withAlpha(220),
        foregroundColor: GlassColors.glassText,
        elevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final formCard = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/branding/app_icon.png',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Connexion',
                      style: AppTypography.headline1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Identifiez-vous pour accéder à la caisse et vos espaces.',
                      style: AppTypography.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Téléphone',
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre téléphone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPasswordField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Obx(
                      () => SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authController.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    try {
                                      final success = await authController
                                          .loginUser(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                      if (success) {
                                        final role =
                                            authController.currentRole ??
                                            'staff';
                                        if (role == 'admin' ||
                                            role == 'superadmin') {
                                          Get.offAllNamed('/admin-dashboard');
                                        } else if (role == 'staff' ||
                                            role == 'livreur') {
                                          Get.offAllNamed('/pos');
                                        } else {
                                          Get.offAllNamed('/home');
                                        }
                                      }
                                    } catch (e) {
                                      Get.snackbar(
                                        'Erreur',
                                        e.toString(),
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.taupeDore,
                                        colorText: AppColors.blancPur,
                                        borderRadius: 12,
                                        margin: const EdgeInsets.all(
                                          AppSpacing.lg,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: GlassButtonStyle.primary(),
                          child: authController.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Se connecter'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          final pinCard = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 34,
                    color: GlassColors.redAccent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Accès rapide POS',
                    style: AppTypography.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Serveur : ouvrez le POS avec votre code PIN en un clic.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/pos-lock'),
                      style: GlassButtonStyle.secondary().copyWith(
                        minimumSize: const WidgetStatePropertyAll(
                          Size(double.infinity, 44),
                        ),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Ouvrir le POS avec PIN'),
                    ),
                  ),
                ],
              ),
            ),
          );

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.xl : AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Center(child: formCard),
                  ),
                  if (isWide) const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Center(child: pinCard),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.grisModerne,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: GlassColors.redAccent, size: 20),
          filled: true,
          fillColor: GlassColors.glassWhite.withAlpha(220),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: GlassColors.sushi.withAlpha(120),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: GlassColors.sushi.withAlpha(120),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: GlassColors.redAccent,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: GlassColors.redAccent,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: GlassColors.redAccent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          labelStyle: const TextStyle(
            color: AppColors.grisModerne,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: GlassColors.redAccent,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: GlassColors.redAccent,
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
          filled: true,
          fillColor: GlassColors.glassWhite.withAlpha(220),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: GlassColors.sushi.withAlpha(120),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: GlassColors.sushi.withAlpha(120),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: GlassColors.redAccent,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: GlassColors.redAccent,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: GlassColors.redAccent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
