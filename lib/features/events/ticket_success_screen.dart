import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/data/default_data.dart';
import '../../core/state/app_state.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import 'digital_ticket_screen.dart';

class TicketSuccessScreen extends StatefulWidget {
  const TicketSuccessScreen({super.key});

  @override
  State<TicketSuccessScreen> createState() => _TicketSuccessScreenState();
}

class _TicketSuccessScreenState extends State<TicketSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final SpetoEventTicket? ticket = appState.selectedTicket;
    if (ticket == null) {
      return SpetoScreenScaffold(
        title: 'Bilet Durumu',
        background: Palette.aubergine,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: SpetoCard(
            radius: 24,
            color: Palette.cardWarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Onaylanmış bilet bulunamadı',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Etkinlik bileti satın alındığında başarı durumu burada gösterilecek.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Palette.soft,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SpetoScreenScaffold(
      title: '',
      showBack: false,
      background: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          // Confetti overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: ConfettiPainter(progress: _confettiController.value),
                );
              },
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (BuildContext context, double value, Widget? child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value.clamp(0, 1), child: child),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Palette.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Biletiniz Hazır!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Etkinlik girişinde dijital bileti göstermeniz yeterli.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Palette.soft,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 30),
                SpetoCard(
                  radius: 28,
                  padding: EdgeInsets.zero,
                  color: Palette.cardWarm,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                ticket.image,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) => Container(
                                      width: 96,
                                      height: 96,
                                      color: Palette.card,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Palette.red.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      ticket.zone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(color: Palette.red),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    ticket.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${ticket.venue} • ${ticket.dateLabel} • ${ticket.timeLabel}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 2, color: Color(0x44FFFFFF)),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            TicketInfo(title: 'Tarih', value: ticket.dateLabel),
                            const SizedBox(height: 12),
                            TicketInfo(
                              title: 'Bilet',
                              value: '${ticket.zone} • 1 Adet',
                            ),
                            const SizedBox(height: 12),
                            TicketInfo(title: 'Koltuk', value: ticket.seat),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SpetoCard(
                  radius: 20,
                  color: Palette.cardWarm,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Palette.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Palette.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Pro Harcama Özeti',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${formatPoints(ticket.pointsCost)} kullanıldı • Kalan bakiye ${formatPoints(appState.proPointsBalance)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Palette.soft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SpetoPrimaryButton(
                  label: 'BİLETİ GÖRÜNTÜLE',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => openScreen(context, SpetoScreen.digitalTicket),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => openRootScreen(context, SpetoScreen.home),
                  child: const Text('Ana sayfaya dön'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final math.Random rng = math.Random(42);
    const int count = 40;
    for (int i = 0; i < count; i++) {
      final double x = rng.nextDouble() * size.width;
      final double startY = -20 - rng.nextDouble() * 40;
      final double endY = size.height + 20;
      final double y = startY + (endY - startY) * progress;
      final double alpha = (1 - progress).clamp(0, 1);
      final Color color = <Color>[
        Palette.red,
        Palette.orange,
        Palette.yellow,
        Palette.cyan,
        Palette.green,
      ][i % 5];
      final Paint paint = Paint()
        ..color = color.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.fill;
      final double w = 4 + rng.nextDouble() * 6;
      final double h = 6 + rng.nextDouble() * 8;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * rng.nextDouble() * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class GaugePainter extends CustomPainter {
  GaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 8;
    const double startAngle = 2.3;
    const double sweepTotal = 4.6;

    // Background arc
    final Paint bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Progress arc
    final Paint fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Palette.orange, Palette.red],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class SpetoAnimatedListItem extends StatelessWidget {
  const SpetoAnimatedListItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: child,
    );
  }
}
