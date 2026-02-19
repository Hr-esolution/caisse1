import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../theme/sushi_design.dart';
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
      title: 'Paramètres',
      activeRoute: '/settings',
      child: GetBuilder<SettingsController>(
        builder: (_) {
          final settings = controller.settings;
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  constraints.maxWidth >= 1400 ? 3 : constraints.maxWidth >= 960 ? 2 : 1;
              final childAspect = crossAxisCount == 1 ? 1.05 : 1.2;

              final grid = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: SushiSpace.lg,
                mainAxisSpacing: SushiSpace.lg,
                childAspectRatio: childAspect,
                children: [
                  _settingCard(
                    icon: Icons.currency_exchange,
                    title: 'Devise',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _textField(
                          controller: _codeController,
                          label: 'Code devise',
                          hint: 'MAD',
                          icon: Icons.code,
                        ),
                        const SizedBox(height: SushiSpace.sm),
                        _textField(
                          controller: _symbolController,
                          label: 'Symbole',
                          hint: 'DH',
                          icon: Icons.attach_money,
                        ),
                        const SizedBox(height: SushiSpace.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SushiCTAButton(
                            label: 'Enregistrer',
                            icon: Icons.save_rounded,
                            onTap: () async {
                              await controller.updateCurrency(
                                code: _codeController.text,
                                symbol: _symbolController.text,
                              );
                              if (!mounted) return;
                              _toast(true, 'Devise mise à jour');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _settingCard(
                    icon: Icons.apps,
                    title: 'Logo Application',
                    child: _logoPickerCard(
                      path: settings.appLogoPath,
                      onPick: () => _handlePick(
                        pick: controller.uploadAppLogo,
                        label: 'logo application',
                      ),
                      onClear: () async {
                        await controller.updateAppLogo(null);
                        if (!mounted) return;
                        _toast(true, 'Logo application supprimé');
                      },
                    ),
                  ),
                  _settingCard(
                    icon: Icons.receipt_long,
                    title: 'Logo Ticket',
                    child: _logoPickerCard(
                      path: settings.ticketLogoPath,
                      onPick: () => _handlePick(
                        pick: controller.uploadTicketLogo,
                        label: 'logo ticket',
                      ),
                      onClear: () async {
                        await controller.updateTicketLogo(null);
                        if (!mounted) return;
                        _toast(true, 'Logo ticket supprimé');
                      },
                    ),
                  ),
                ],
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(SushiSpace.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        grid,
                        const SizedBox(height: SushiSpace.lg),
                        _infoPanel(),
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

  Future<void> _handlePick({
    required Future<bool> Function(PlatformFile file) pick,
    required String label,
  }) async {
    final selectedFile = await _pickImageFile();
    if (selectedFile == null) return;
    final ok = await pick(selectedFile);
    if (!mounted) return;
    _toast(ok, ok ? '$label mis à jour' : 'Impossible de traiter le fichier');
  }

  Future<PlatformFile?> _pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
        lockParentWindow: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      if (file.path == null) return null;
      return file;
    } catch (e) {
      _toast(false, 'Sélection impossible: $e');
      return null;
    }
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SushiSpace.sm),
                decoration: SushiDeco.badge(bg: SushiColors.redPale),
                child: Icon(icon, color: SushiColors.red, size: 18),
              ),
              const SizedBox(width: SushiSpace.sm),
              Text(title, style: SushiTypo.h3),
            ],
          ),
          const SizedBox(height: SushiSpace.md),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _textField({
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
        prefixIcon: Icon(icon, size: 18, color: SushiColors.inkMid),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: SushiDeco.card(),
          padding: const EdgeInsets.all(SushiSpace.sm),
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          child: preview,
        ),
        const SizedBox(height: SushiSpace.sm),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await onPick();
              },
              icon: const Icon(Icons.image, size: 18),
              label: const Text('Choisir'),
              style: SushiButtonStyle.secondary(),
            ),
            const SizedBox(width: SushiSpace.sm),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Supprimer'),
              style: ButtonStyle(
                foregroundColor: const WidgetStatePropertyAll(SushiColors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _logoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported_outlined,
            size: 48, color: SushiColors.inkLight),
        const SizedBox(height: SushiSpace.sm),
        const Text('Aucun logo', style: SushiTypo.caption),
      ],
    );
  }

  Widget _infoPanel() {
    return Container(
      width: double.infinity,
      decoration: SushiDeco.card(),
      padding: const EdgeInsets.all(SushiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Astuces paramétrage', style: SushiTypo.h2),
          SizedBox(height: SushiSpace.sm),
          _InfoRow(
            icon: Icons.print,
            text: 'Le logo ticket est utilisé sur les reçus imprimés (salle & livraison).',
          ),
          SizedBox(height: SushiSpace.sm),
          _InfoRow(
            icon: Icons.apps,
            text: 'Le logo application apparaît dans le lanceur et l’écran de connexion.',
          ),
          SizedBox(height: SushiSpace.sm),
          _InfoRow(
            icon: Icons.currency_exchange,
            text: 'Mettez à jour code et symbole pour aligner prix et tickets.',
          ),
        ],
      ),
    );
  }

  void _toast(bool success, String message) {
    Get.snackbar(
      success ? 'Succès' : 'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? SushiColors.green : SushiColors.error,
      colorText: SushiColors.white,
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
          decoration: SushiDeco.badge(bg: SushiColors.redPale),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: SushiColors.red),
        ),
        const SizedBox(width: SushiSpace.sm),
        Expanded(child: Text(text, style: SushiTypo.bodyMd)),
      ],
    );
  }
}
