import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../utils/image_resolver.dart';
import '../widgets/admin_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _codeController;
  late final TextEditingController _symbolController;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<SettingsController>().settings;
    _codeController = TextEditingController(text: settings.currencyCode);
    _symbolController = TextEditingController(text: settings.currencySymbol);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return AdminShell(
      title: 'Settings',
      activeRoute: '/settings',
      child: GetBuilder<SettingsController>(
        builder: (_) {
          final settings = controller.settings;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;
              final crossAxisCount = constraints.maxWidth >= 1400
                  ? 3
                  : constraints.maxWidth >= 900
                  ? 2
                  : 1;

              final childAspect = crossAxisCount == 1 ? 1.05 : 1.25;

              final grid = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: childAspect,
                children: [
                  _buildSettingCard(
                    icon: Icons.currency_exchange,
                    title: 'Devise',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStyledTextField(
                          controller: _codeController,
                          label: 'Code devise',
                          hint: 'MAD',
                          icon: Icons.code,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildStyledTextField(
                          controller: _symbolController,
                          label: 'Symbole',
                          hint: 'DH',
                          icon: Icons.attach_money,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildStyledButton(
                            onPressed: () async {
                              await controller.updateCurrency(
                                code: _codeController.text,
                                symbol: _symbolController.text,
                              );
                              if (!mounted) return;
                              Get.snackbar(
                                'Succès',
                                'Devise mise à jour',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            },
                            label: 'Enregistrer',
                            icon: Icons.save,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSettingCard(
                    icon: Icons.apps,
                    title: 'Logo Application',
                    child: _logoPickerCard(
                      path: settings.appLogoPath,
                      onPick: () async {
                        final selectedFile = await _pickImageFile();
                        if (selectedFile == null) return;
                        final uploaded = await controller.uploadAppLogo(
                          selectedFile,
                        );
                        if (!mounted) return;
                        _showUploadFeedback(uploaded, 'logo application');
                      },
                      onClear: () async {
                        await controller.updateAppLogo(null);
                        if (!mounted) return;
                        _showUploadFeedback(true, 'logo application supprimé');
                      },
                    ),
                  ),
                  _buildSettingCard(
                    icon: Icons.receipt,
                    title: 'Logo Ticket',
                    child: _logoPickerCard(
                      path: settings.ticketLogoPath,
                      onPick: () async {
                        final selectedFile = await _pickImageFile();
                        if (selectedFile == null) return;
                        final uploaded = await controller.uploadTicketLogo(
                          selectedFile,
                        );
                        if (!mounted) return;
                        _showUploadFeedback(uploaded, 'logo ticket');
                      },
                      onClear: () async {
                        await controller.updateTicketLogo(null);
                        if (!mounted) return;
                        _showUploadFeedback(true, 'logo ticket supprimé');
                      },
                    ),
                  ),
                ],
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: grid),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(flex: 2, child: _settingsInfoPanel()),
                            ],
                          )
                        : Column(
                            children: [
                              grid,
                              const SizedBox(height: AppSpacing.lg),
                              _settingsInfoPanel(),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _settingsInfoPanel() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: GlassColors.glassWhite.withAlpha(180),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Astuces paramétrage', style: GlassTypography.headline2),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Personnalisez la devise, le logo app (icône) et le logo ticket pour que le POS soit cohérent sur mobile, web et imprimante.',
              style: GlassTypography.bodySmall,
            ),
            SizedBox(height: AppSpacing.md),
            _InfoRow(
              icon: Icons.print,
              text:
                  'Le logo ticket est utilisé sur les reçus imprimés pour la salle et la livraison.',
            ),
            SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.apps,
              text:
                  'Le logo application apparaît dans le lanceur et l’écran de connexion.',
            ),
            SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.currency_exchange,
              text:
                  'Mettez à jour le code et le symbole pour synchroniser les prix et tickets.',
            ),
          ],
        ),
      ),
    );
  }

  Future<PlatformFile?> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
        'bmp',
        'heic',
        'heif',
        'tif',
        'tiff',
        'avif',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: GlassColors.glassWhite.withAlpha(180),
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: GlassThemeData.accentGradient(),
                    boxShadow: [
                      BoxShadow(
                        color: GlassColors.redAccent.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTypography.headline2),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: GlassColors.sushi.withAlpha(120)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: GlassColors.sushi.withAlpha(120)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GlassColors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: GlassColors.glassWhite.withAlpha(120),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  Widget _buildStyledButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: GlassButtonStyle.primary().copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      ),
    );
  }

  Widget _logoPickerCard({
    required String? path,
    required Future<void> Function() onPick,
    required Future<void> Function() onClear,
  }) {
    final imageProvider = resolveImageProvider(path);
    final preview = imageProvider == null
        ? _logoPlaceholder()
        : Image(
            image: imageProvider,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _logoPlaceholder(),
          );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: GlassColors.glassLight,
              border: Border.all(
                color: GlassColors.sushi.withAlpha(110),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: preview,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image, size: 18),
                label: const Text('Choisir'),
                style: GlassButtonStyle.secondary().copyWith(
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: GlassColors.redAccent),
                  ),
                  foregroundColor: const WidgetStatePropertyAll(
                    GlassColors.redAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: TextButton.styleFrom(
                  foregroundColor: GlassColors.redAccentDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Aucun logo', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showUploadFeedback(bool success, String target) {
    Get.snackbar(
      success ? 'Succès' : 'Erreur',
      success ? '$target mis à jour' : 'Impossible de traiter le fichier image',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? Colors.green : Colors.red,
      colorText: Colors.white,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: GlassThemeData.accentGradient(),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: GlassTypography.bodySmall)),
      ],
    );
  }
}
