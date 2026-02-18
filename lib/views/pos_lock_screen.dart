import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_back_button.dart';
import '../widgets/glass_card.dart';

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
      appBar: AppBar(
        title: const Text('POS verrouillé'),
        leading: const AppBackButton(),
        backgroundColor: GlassColors.glassWhite.withAlpha(220),
        foregroundColor: GlassColors.glassText,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Flex(
                    direction: MediaQuery.of(context).size.width >= 960
                        ? Axis.horizontal
                        : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: GlassCard(
                          child: GetBuilder<PosController>(
                            builder: (_) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: GlassThemeData.accentGradient(),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Text(
                                    'Entrer le code PIN',
                                    style: AppTypography.headline2,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  const Text(
                                    'Saisis ton code serveur pour ouvrir la caisse en mode POS.',
                                    style: AppTypography.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  TextField(
                                    controller: _pinController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'PIN',
                                    ),
                                  ),
                                  if (pos.error != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        pos.error!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final pin = _pinController.text.trim();
                                        final ok = await pos.unlockWithPin(pin);
                                        if (!ok || !mounted) return;
                                        _pinController.clear();
                                        Get.offAllNamed('/pos-menu');
                                      },
                                      style: GlassButtonStyle.primary(),
                                      child: const Text('Déverrouiller'),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      style: GlassButtonStyle.secondary(),
                                      onPressed: () =>
                                          Get.offAllNamed('/login'),
                                      child: const Text('Retour Login'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                      ),
                      Expanded(
                        flex: 1,
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              Icon(
                                Icons.info_outline,
                                size: 32,
                                color: GlassColors.redAccent,
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Pourquoi le POS ?',
                                style: AppTypography.headline2,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Le serveur gère ici toutes les commandes :\n'
                                '• Sur place (tables)\n'
                                '• À emporter / livraison\n'
                                '• Commandes entrantes depuis mobile et site web\n'
                                '• Paiements et encaissements rapides\n'
                                '• Suivi des tickets cuisine et statut des tables',
                                style: AppTypography.bodySmall,
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Connecte-toi avec ton PIN pour reprendre les commandes en cours ou en créer de nouvelles.',
                                style: AppTypography.bodyLarge,
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
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(gradient: GlassThemeData.backgroundGradient()),
      child: CustomPaint(
        painter: _LockBackgroundPainter(
          lineColor: GlassColors.redAccent.withAlpha(16),
        ),
      ),
    );
  }
}

class _LockBackgroundPainter extends CustomPainter {
  _LockBackgroundPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double y = 30; y < size.height; y += 84) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 22) {
        final offset = math.sin((x / 80) + (y / 64)) * 4.0;
        path.lineTo(x, y + offset);
      }
      canvas.drawPath(path, paint);
    }

    final dotPaint = Paint()..color = lineColor.withAlpha(90);
    for (double x = 24; x < size.width; x += 132) {
      for (double y = 20; y < size.height; y += 120) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LockBackgroundPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
