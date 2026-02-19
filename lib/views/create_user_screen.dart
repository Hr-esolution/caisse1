import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  String _role = 'staff';
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    Get.find<RestaurantController>(); // ensure loaded

    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
        title: const Text('Créer un utilisateur', style: SushiTypo.h2),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: SushiSpace.xl,
          vertical: SushiSpace.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Container(
                  decoration: SushiDeco.card(),
                  padding: const EdgeInsets.all(SushiSpace.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Coordonnées', style: SushiTypo.h1),
                        const SizedBox(height: SushiSpace.sm),
                        Text(
                          'Ajoutez un membre de l’équipe. Le PIN est requis pour le personnel.',
                          style: SushiTypo.bodyMd,
                        ),
                        const SizedBox(height: SushiSpace.lg),
                        _field(
                          label: 'Nom complet',
                          controller: _nameController,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Nom requis' : null,
                        ),
                        const SizedBox(height: SushiSpace.md),
                        _field(
                          label: 'Numéro de téléphone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Téléphone requis' : null,
                        ),
                        const SizedBox(height: SushiSpace.md),
                        _field(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email requis';
                            if (!GetUtils.isEmail(v)) return 'Email invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: SushiSpace.md),
                        _field(
                          label: 'Mot de passe',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Mot de passe requis';
                            if (v.length < 6) return 'Min. 6 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: SushiSpace.md),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: _decoration('Rôle'),
                          items: const [
                            DropdownMenuItem(value: 'staff', child: Text('Serveur')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'livreur', child: Text('Livreur')),
                            DropdownMenuItem(value: 'client', child: Text('Client')),
                            DropdownMenuItem(value: 'superadmin', child: Text('Super admin')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _role = v);
                          },
                        ),
                        const SizedBox(height: SushiSpace.md),
                        _field(
                          label: 'Code PIN (4-6 chiffres)',
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (_role == 'staff') {
                              if (v == null || v.isEmpty) {
                                return 'PIN requis pour le personnel';
                              }
                            }
                            if (v != null && v.isNotEmpty) {
                              if (v.length < 4 || v.length > 6) {
                                return '4 à 6 chiffres';
                              }
                              if (!RegExp(r'^\\d+$').hasMatch(v)) {
                                return 'Chiffres uniquement';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: SushiSpace.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Actif', style: SushiTypo.h4),
                        Switch(
                          value: _isActive,
                          thumbColor:
                              const WidgetStatePropertyAll(SushiColors.red),
                          trackColor:
                              const WidgetStatePropertyAll(SushiColors.redPale),
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                          ],
                        ),
                        const SizedBox(height: SushiSpace.xl),
                        SushiCTAButton(
                          label: 'Créer l’utilisateur',
                          icon: Icons.person_add_rounded,
                          onTap: () async {
                            if (!_formKey.currentState!.validate()) return;
                            try {
                              final ok = await userController.createUser(
                                name: _nameController.text,
                                phone: _phoneController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                                role: _role,
                                pinCode: _pinController.text.isEmpty
                                    ? null
                                    : _pinController.text,
                                isActive: _isActive,
                              );
                              if (ok) {
                                Get.back(result: true);
                              } else {
                                Get.snackbar(
                                  'Erreur',
                                  'Création impossible.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: SushiColors.error,
                                  colorText: SushiColors.white,
                                );
                              }
                            } catch (e) {
                              Get.snackbar(
                                'Erreur',
                                e.toString(),
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: SushiColors.error,
                                colorText: SushiColors.white,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(labelText: label);

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: _decoration(label),
      validator: validator,
    );
  }
}
