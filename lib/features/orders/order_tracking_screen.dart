import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import '../../src/core/models.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final SpetoOrder order =
        appState.selectedOrder ??
        (appState.activeOrders.isNotEmpty
            ? appState.activeOrders.first
            : appState.historyOrders.first);
    final bool isActive = order.status == SpetoOrderStatus.active;
    return Scaffold(
      backgroundColor: Palette.base,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final EdgeInsets viewPadding = MediaQuery.viewPaddingOf(context);
          final double safeTop = viewPadding.top;
          final double screenHeight = constraints.maxHeight;
          final double headerTop = safeTop + 16;
          final double statusCardTop = headerTop + 56;
          final double selfPinTop = statusCardTop + 82;
          final double bottomPanelHeight = screenHeight < 760
              ? screenHeight * 0.58
              : 535;
          final double bottomPanelTop = screenHeight - bottomPanelHeight;
          double pickupPinTop = bottomPanelTop - 118;
          if (pickupPinTop < selfPinTop + 110) {
            pickupPinTop = selfPinTop + 110;
          }

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        const Color(0xFF2F1F1B),
                        const Color(0xFF1A1414),
                        Palette.base,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(0.35),
                    ),
                  ),
                  child: CustomPaint(painter: RoutePainter()),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: headerTop,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    roundButton(
                      context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (navigator.canPop()) {
                          navigator.pop();
                          return;
                        }
                        openRootScreen(context, SpetoScreen.orderHistory);
                      },
                    ),
                    Text(
                      'Sipariş Takibi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    roundButton(
                      context,
                      icon: Icons.home_outlined,
                      onTap: () => openRootScreen(context, SpetoScreen.home),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 88,
                top: statusCardTop,
                child: SpetoCard(
                  radius: 22,
                  color: Palette.cardWarm.withValues(alpha: 0.92),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Palette.green.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: Palette.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Gel-Al hazırlık akışı aktif',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isActive
                                  ? '3 operasyon adımı kaldı'
                                  : 'Gel-al akışı tamamlandı',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Palette.soft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: statusCardTop + 4,
                child: Column(
                  children: <Widget>[
                    _mapControl(Icons.my_location_rounded),
                    const SizedBox(height: 12),
                    _mapControl(Icons.layers_outlined),
                  ],
                ),
              ),
              Positioned(
                left: 58,
                top: selfPinTop,
                child: _mapPin(
                  Palette.cyan,
                  'Sen',
                  icon: Icons.person_pin_circle_rounded,
                ),
              ),
              Positioned(
                right: 28,
                top: pickupPinTop,
                child: _mapPin(
                  Palette.orange,
                  'Şube',
                  icon: Icons.storefront_rounded,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: bottomPanelHeight,
                  decoration: const BoxDecoration(
                    color: Palette.cardWarm,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: Colors.black45, blurRadius: 24),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      isActive
                                          ? 'Siparişiniz hazırlanıyor'
                                          : 'Sipariş özeti hazır',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Palette.muted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.vendor,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isActive
                                          ? 'Tahmini hazır olma • ${order.etaLabel}'
                                          : 'Durum • ${orderStatusLabel(order.status)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Palette.soft),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  order.image,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) => Container(
                                        width: 48,
                                        height: 48,
                                        color: Palette.card,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: isActive ? 0.72 : 1,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Palette.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _statusBadge(
                                context,
                                label: isActive ? 'Mutfakta' : 'Tamamlandı',
                                color: isActive
                                    ? Palette.orange
                                    : Palette.green,
                              ),
                              _statusBadge(
                                context,
                                label: isActive
                                    ? 'Gel-Al hazırlanıyor'
                                    : 'Arşive alındı',
                                color: isActive ? Palette.cyan : Palette.soft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          OrderTimelineStep(
                            title: 'Sipariş Alındı',
                            subtitle: order.placedAtLabel,
                            active: false,
                            completed: true,
                          ),
                          OrderTimelineStep(
                            title: 'Hazırlanıyor',
                            subtitle: isActive
                                ? 'Mutfakta ve pakette son kontroller yapılıyor'
                                : 'Sipariş tamamlandı',
                            active: isActive,
                            completed: !isActive,
                          ),
                          OrderTimelineStep(
                            title: isActive
                                ? 'Gel-Al Noktasında Hazır'
                                : 'Teslim Alındı',
                            subtitle: isActive
                                ? 'Gel-Al kodun hazır olduğunda bildirim gönderilir'
                                : 'Sipariş başarıyla teslim alındı',
                            active: false,
                            completed: !isActive,
                            showLine: false,
                          ),
                          const SizedBox(height: 12),
                          SpetoCard(
                            radius: 18,
                            color: Palette.card,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Palette.red.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: Palette.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        isActive
                                            ? 'Gel-Al noktası hazırlanıyor'
                                            : 'Gel-al akışı kapandı',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isActive
                                            ? order.deliveryAddress
                                            : 'Sipariş kaydı fiş ekranında tutuluyor',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Palette.soft),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SpetoCard(
                            radius: 18,
                            color: Palette.card,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Teslim Alma Kodu',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Palette.muted),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.pickupCode,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 4,
                                            ),
                                      ),
                                      Text(
                                        isActive
                                            ? 'Gel-al sırasında bu kodu gösterin'
                                            : 'Bu sipariş artık fiş kaydında saklanıyor',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Palette.soft),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.copy_all_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SpetoPrimaryButton(
                                  label: 'Fişi Gör',
                                  icon: Icons.receipt_long_rounded,
                                  onTap: () {
                                    appState.selectOrder(order);
                                    openScreen(
                                      context,
                                      SpetoScreen.orderReceipt,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      openRootScreen(context, SpetoScreen.home),
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Palette.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.home_outlined,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ana Menü',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapPin(Color color, String label, {required IconData icon}) {
    return PulsingMapPin(color: color, label: label, icon: icon);
  }

  Widget _mapControl(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, size: 18),
    );
  }

  Widget _statusBadge(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PulsingMapPin extends StatefulWidget {
  const PulsingMapPin({
    super.key,
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  State<PulsingMapPin> createState() => PulsingMapPinState();
}

class PulsingMapPinState extends State<PulsingMapPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  final double scale = 1.0 + _pulse.value * 0.6;
                  final double opacity = (1.0 - _pulse.value).clamp(0, 0.5);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withValues(alpha: opacity),
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(widget.label),
        ),
      ],
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint road = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final Path path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.17)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.24,
        size.width * 0.48,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.57,
        size.width * 0.78,
        size.height * 0.48,
      );
    canvas.drawPath(path, road);

    final Paint highlight = Paint()
      ..color = Palette.red.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
