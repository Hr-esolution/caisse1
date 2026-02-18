import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  String _selectedRole = 'staff';
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final user = Get.arguments; // Get the user passed as argument

    // Initialize controllers with user data
    if (!_initialized) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email;
      _pinCodeController.text = user.pinCode ?? '';
      _selectedRole = user.role;
      _isActive = user.isActive;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier utilisateur'),
        backgroundColor: AppColors.blancPur,
        foregroundColor: AppColors.charbon,
        leading: const AppBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un numéro de téléphone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedRole,
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
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Code PIN',
                    hintText: 'Entrez un PIN à 4-6 chiffres',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedRole == 'staff') {
                      if (value == null || value.isEmpty) {
                        return 'Le code PIN est requis pour le personnel';
                      }
                    }
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 4 || value.length > 6) {
                        return 'Le PIN doit comporter 4 à 6 chiffres';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'Le PIN doit contenir uniquement des chiffres';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Statut actif'),
                  value: _isActive,
                  onChanged: (bool value) {
                    // Update the user's active status
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final success = await userController.updateUser(
                          userId: user.id,
                          name: _nameController.text,
                          phone: _phoneController.text,
                          email: _emailController.text,
                          role: _selectedRole,
                          pinCode: _pinCodeController.text.isNotEmpty
                              ? _pinCodeController.text
                              : null,
                          isActive: _isActive,
                        );

                        if (success) {
                          Get.back(result: true);
                          return;
                        } else {
                          Get.snackbar(
                            'Erreur',
                            'Échec de la mise à jour (aucune modification enregistrée).',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Erreur',
                          e.toString(),
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terraCotta,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Mettre à jour',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }
}
