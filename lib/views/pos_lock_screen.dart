import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';

class PosLockScreen extends StatefulWidget {
  const PosLockScreen({super.key});

  @override
  State<PosLockScreen> createState() => _PosLockScreenState();
}

class _PosLockScreenState extends State<PosLockScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();
    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        title: const Text('POS verrouillé', style: SushiTypo.h2),
        leading: AppBackButton(
          alwaysVisible: true,
          iconColor: SushiColors.red,
          onPressed: () => Get.offAllNamed('/login'),
        ),
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final cardWidth = isWide
              ? (constraints.maxWidth - SushiSpace.lg) / 2
              : constraints.maxWidth;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SushiSpace.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Wrap(
                  spacing: SushiSpace.lg,
                  runSpacing: SushiSpace.lg,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: cardWidth.clamp(320, 520),
                      child: Container(
                        decoration: SushiDeco.card(),
                        padding: const EdgeInsets.all(SushiSpace.xl),
                        child: GetBuilder<PosController>(
                          builder: (_) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: SushiDeco.badge(
                                    bg: SushiColors.redSurface,
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    color: SushiColors.red,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: SushiSpace.md),
                                const Text(
                                  'Entrer le code PIN',
                                  style: SushiTypo.h2,
                                ),
                                const SizedBox(height: SushiSpace.sm),
                                const Text(
                                  'Saisis ton code serveur pour ouvrir la caisse en mode POS.',
                                  style: SushiTypo.bodyMd,
                                ),
                                const SizedBox(height: SushiSpace.lg),
                                TextField(
                                  controller: _pinController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'PIN',
                                  ),
                                ),
                                if (pos.error != null) ...[
                                  const SizedBox(height: SushiSpace.sm),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      pos.error!,
                                      style: SushiTypo.bodySm.copyWith(
                                        color: SushiColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: SushiSpace.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: SushiCTAButton(
                                    label: 'Déverrouiller',
                                    onTap: () async {
                                      final pin = _pinController.text.trim();
                                      final ok = await pos.unlockWithPin(pin);
                                      if (!ok || !mounted) return;
                                      _pinController.clear();
                                      Get.offAllNamed('/pos-menu');
                                    },
                                  ),
                                ),
                                const SizedBox(height: SushiSpace.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: SushiButtonStyle.secondary(),
                                    onPressed: () => Get.offAllNamed('/login'),
                                    child: const Text('Retour Login'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(320, 520),
                      child: Container(
                        decoration: SushiDeco.card(),
                        padding: const EdgeInsets.all(SushiSpace.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            Icon(
                              Icons.info_outline,
                              size: 32,
                              color: SushiColors.red,
                            ),
                            SizedBox(height: SushiSpace.md),
                            Text('Pourquoi le POS ?', style: SushiTypo.h2),
                            SizedBox(height: SushiSpace.sm),
                            Text(
                              'Le serveur gère ici toutes les commandes :\n'
                              '• Sur place (tables)\n'
                              '• À emporter / livraison\n'
                              '• Commandes entrantes depuis mobile et site web\n'
                              '• Paiements et encaissements rapides\n'
                              '• Suivi des tickets cuisine et statut des tables',
                              style: SushiTypo.bodyMd,
                            ),
                            SizedBox(height: SushiSpace.md),
                            Text(
                              'Connecte-toi avec ton PIN pour reprendre les commandes en cours ou en créer de nouvelles.',
                              style: SushiTypo.bodyLg,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
