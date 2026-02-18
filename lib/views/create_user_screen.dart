import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';
import '../widgets/glass_card.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'staff';

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    Get.find<RestaurantController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Créer un utilisateur'),
        backgroundColor: GlassColors.glassWhite.withAlpha(140),
        foregroundColor: GlassColors.glassText,
        elevation: 0,
        centerTitle: false,
        leading: const AppBackButton(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildForm(context, userController),
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(
                              flex: 2,
                              child: GlassCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: _buildInfo(),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildForm(context, userController),
                            const SizedBox(height: AppSpacing.lg),
                            GlassCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: _buildInfo(),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, UserController userController) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Coordonnées', style: GlassTypography.headline2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ajoutez un membre de l’équipe. Le code PIN sécurise les commandes sur place.',
              style: GlassTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            _field(
              label: 'Nom complet',
              controller: _nameController,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Veuillez entrer un nom'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              label: 'Numéro de téléphone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Veuillez entrer un numéro'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un email';
                }
                if (!GetUtils.isEmail(value)) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              label: 'Mot de passe',
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 6) {
                  return 'Min. 6 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              decoration: _decoration(label: 'Rôle'),
              items: const [
                DropdownMenuItem(value: 'staff', child: Text('Serveur')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'livreur', child: Text('Livreur')),
                DropdownMenuItem(value: 'client', child: Text('Client')),
                DropdownMenuItem(
                  value: 'superadmin',
                  child: Text('Super admin'),
                ),
              ],
              initialValue: _selectedRole,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedRole = value);
              },
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Veuillez sélectionner un rôle'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              label: 'Code PIN (pour le personnel)',
              hint: '4 à 6 chiffres',
              controller: _pinCodeController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_selectedRole == 'staff') {
                  if (value == null || value.isEmpty) {
                    return 'PIN requis pour le personnel';
                  }
                }
                if (value != null && value.isNotEmpty) {
                  if (value.length < 4 || value.length > 6) {
                    return 'Le PIN doit comporter 4 à 6 chiffres';
                  }
                  if (!RegExp(r'^\\d+$').hasMatch(value)) {
                    return 'Chiffres uniquement';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: GlassButtonStyle.primary(),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  try {
                    await userController.createUser(
                      name: _nameController.text,
                      phone: _phoneController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                      role: _selectedRole,
                      pinCode: _pinCodeController.text.isNotEmpty
                          ? _pinCodeController.text
                          : null,
                    );
                    Get.snackbar(
                      'Succès',
                      'Utilisateur créé avec succès !',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: GlassColors.redAccent,
                      colorText: Colors.white,
                      borderRadius: 14,
                      margin: const EdgeInsets.all(AppSpacing.lg),
                    );
                    Get.back();
                  } catch (e) {
                    Get.snackbar(
                      'Erreur',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: GlassColors.redAccentDark,
                      colorText: Colors.white,
                      borderRadius: 14,
                      margin: const EdgeInsets.all(AppSpacing.lg),
                    );
                  }
                },
                child: const Text(
                  'Créer un utilisateur',
                  style: GlassTypography.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rôles & Sécurité', style: GlassTypography.headline2),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Le POS accepte les commandes des serveurs, du site web et de l’app mobile. '
          'Attribuez un rôle clair pour tracer les actions et sécuriser l’encaissement.',
          style: GlassTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: const [
            Icon(Icons.lock_clock, color: GlassColors.redAccent, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'PIN obligatoire pour les serveurs afin de valider les commandes sur place.',
                style: GlassTypography.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            Icon(Icons.public, color: GlassColors.sushiDark, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Les commandes web et mobile restent associées à l’utilisateur “client”.',
                style: GlassTypography.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            Icon(
              Icons.verified_user,
              color: GlassColors.redAccentDark,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin : gestion catalogue & caisse. Super admin : paramètres avancés.',
                style: GlassTypography.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: _decoration(label: label, hint: hint),
      validator: validator,
    );
  }

  InputDecoration _decoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: GlassColors.glassWhite.withAlpha(120),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      labelStyle: const TextStyle(
        color: GlassColors.glassText,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      hintStyle: const TextStyle(color: GlassColors.glassText, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: GlassColors.sushi.withAlpha(90),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: GlassColors.sushi.withAlpha(90),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlassColors.redAccent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlassColors.redAccentDark,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlassColors.redAccent, width: 1.4),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }
}
