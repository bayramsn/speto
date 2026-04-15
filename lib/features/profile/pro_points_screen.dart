import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/events/event_data.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';

class ProPointsScreen extends StatefulWidget {
  const ProPointsScreen({super.key});

  @override
  State<ProPointsScreen> createState() => _ProPointsScreenState();
}

class _ProPointsScreenState extends State<ProPointsScreen> {
  int _selectedSection = 0;

  static const List<String> _sections = <String>[
    'Biletlerim',
    'Kullan',
    'Kazan',
  ];

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      title: 'Pro Puan',
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.points,
      background: Palette.aubergine,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF39201B), Color(0xFF221010)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Palette.red.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Palette.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Palette.orange,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.base.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          formatPoints(appState.proPointsBalance),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Palette.orange,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Eğlence ve sosyal yaşam için hazır bakiyen burada.',
                    style: context.spetoFeatureTitleStyle(
                      fontSize: 20,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pro puanlar market ve restoran sepetinde indirim olarak kullanılmaz. Bilet, atölye ve özel deneyimlerde geçerlidir.',
                    style: context.spetoDescriptionStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double cardWidth =
                              (constraints.maxWidth - 20) / 3;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              SizedBox(
                                width: cardWidth,
                                child: _walletStatCard(
                                  context,
                                  label: 'Bu hafta',
                                  value: '+120 Pro',
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _walletStatCard(
                                  context,
                                  label: 'Seviye',
                                  value: 'Gümüş',
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _walletStatCard(
                                  context,
                                  label: 'Açılabilir',
                                  value: '2 bilet',
                                ),
                              ),
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: SizedBox(
                      width: 148,
                      height: 148,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 0.62),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder:
                            (
                              BuildContext context,
                              double value,
                              Widget? child,
                            ) {
                              return CustomPaint(
                                painter: _GaugePainter(progress: value),
                                child: Center(
                                  child: Text(
                                    '${(value * 100).toInt()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Palette.orange,
                                        ),
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sections.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 10),
                itemBuilder: (BuildContext context, int index) {
                  return TabChip(
                    label: _sections[index],
                    active: index == _selectedSection,
                    onTap: () => setState(() => _selectedSection = index),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildSection(context, appState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, SpetoAppState appState) {
    switch (_selectedSection) {
      case 1:
        return _usageSection(context, appState);
      case 2:
        return _earnSection(context, appState);
      default:
        return _ticketsSection(context, appState);
    }
  }

  Widget _ticketsSection(BuildContext context, SpetoAppState appState) {
    if (appState.ownedTickets.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey<String>('empty-tickets'),
        child: SpetoCard(
          radius: 24,
          color: Palette.cardWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Henüz aktif biletin yok',
                style: context.spetoSectionTitleStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Konser, atölye ve sosyal yaşam etkinliklerini Pro puan ile açtığında biletlerin burada listelenecek.',
                style: context.spetoDescriptionStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              SpetoPrimaryButton(
                label: 'Etkinlikleri Keşfet',
                icon: Icons.celebration_outlined,
                onTap: () =>
                    openRootScreen(context, SpetoScreen.eventsDiscovery),
              ),
            ],
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey<String>('owned-tickets'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: appState.ownedTickets.map((SpetoEventTicket ticket) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: ticket == appState.ownedTickets.last ? 0 : 14,
            ),
            child: GestureDetector(
              onTap: () {
                appState.selectTicket(ticket);
                openScreen(context, SpetoScreen.digitalTicket);
              },
              child: SpetoCard(
                radius: 22,
                color: Palette.cardWarm,
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        ticket.image,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) => Container(
                              width: 86,
                              height: 86,
                              color: Palette.card,
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            ticket.title,
                            style: context.spetoCardTitleStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ticket.venue} • ${ticket.dateLabel} • ${ticket.timeLabel}',
                            style: context.spetoMetaStyle(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Palette.base,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  ticket.zone,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Palette.red,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formatPoints(ticket.pointsCost),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Palette.orange,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _usageSection(BuildContext context, SpetoAppState appState) {
    final EventExperience? promotedEvent = featuredEventExperience;
    return KeyedSubtree(
      key: const ValueKey<String>('usage-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SpetoCard(
            radius: 24,
            color: Palette.cardWarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Pro puanı nerede kullanırsın?',
                  style: context.spetoSectionTitleStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bu bakiye sadece etkinlik, atölye ve sosyal yaşam bileti açmak için kullanılır. Restoran ve market sepetinde nakit yerine geçmez.',
                  style: context.spetoDescriptionStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SpetoCard(
            radius: 24,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF231715), Color(0xFF111114)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Pro kullanım kuralları',
                  style: context.spetoSectionTitleStyle(fontSize: 17),
                ),
                const SizedBox(height: 12),
                _walletTimelineRow(
                  context,
                  title: '1. Bakiye kazan',
                  subtitle:
                      'Sipariş, gel-al ve kampanya akışlarından Pro topla',
                ),
                const SizedBox(height: 12),
                _walletTimelineRow(
                  context,
                  title: '2. Bilet aç',
                  subtitle: 'Etkinlik veya atölye ekranında Pro ile bilet seç',
                ),
                const SizedBox(height: 12),
                _walletTimelineRow(
                  context,
                  title: '3. Dijital bileti göster',
                  subtitle: 'QR ve cüzdan kartını girişte kullan',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (promotedEvent == null)
            SpetoCard(
              radius: 24,
              color: Palette.cardWarm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Şu anda açılabilir etkinlik yok',
                    style: context.spetoSectionTitleStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Etkinlik akışı geldiğinde Pro ile açılabilen biletler burada gösterilecek.',
                    style: context.spetoDescriptionStyle(fontSize: 14),
                  ),
                ],
              ),
            )
          else
            SpetoCard(
              radius: 26,
              padding: EdgeInsets.zero,
              color: Palette.cardWarm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SpetoImage(
                    url: promotedEvent.image,
                    height: 188,
                    borderRadius: 26,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          promotedEvent.title,
                          style: context.spetoSectionTitleStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${promotedEvent.venue} • ${promotedEvent.dateLabel} • ${promotedEvent.timeLabel}',
                          style: context.spetoDescriptionStyle(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Text(
                              formatPoints(promotedEvent.pointsCost),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Palette.orange,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const Spacer(),
                            SpetoPrimaryButton(
                              label: 'Etkinliği Aç',
                              icon: Icons.arrow_forward_rounded,
                              onTap: () =>
                                  openScreen(context, SpetoScreen.eventDetail),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _earnSection(BuildContext context, SpetoAppState appState) {
    final List<SpetoOrder> rewardOrders = <SpetoOrder>[
      ...appState.activeOrders,
      ...appState.historyOrders,
    ].where((SpetoOrder order) => order.rewardPoints > 0).take(4).toList();

    return KeyedSubtree(
      key: const ValueKey<String>('earn-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SpetoCard(
            radius: 24,
            color: Palette.cardWarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Pro puan nasıl kazanılır?',
                  style: context.spetoSectionTitleStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  'Restoran, Happy Hour ve market siparişlerinden Pro puan kazanırsın. Kazandığın puanlar eğlence ve sosyal yaşam biletlerinde açılır.',
                  style: context.spetoDescriptionStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...rewardOrders.map((SpetoOrder order) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: order == rewardOrders.last ? 0 : 12,
              ),
              child: SpetoCard(
                radius: 20,
                color: Palette.cardWarm,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Palette.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Palette.orange,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            order.vendor,
                            style: context.spetoCardTitleStyle(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.placedAtLabel,
                            style: context.spetoMetaStyle(),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${formatPoints(order.rewardPoints)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Palette.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _walletStatCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: context.spetoMetaStyle(color: Palette.soft)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _walletTimelineRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    bool last = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 20,
          child: Column(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Palette.orange,
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 42,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: context.spetoCardTitleStyle()),
              const SizedBox(height: 4),
              Text(subtitle, style: context.spetoMetaStyle(height: 1.42)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const double strokeWidth = 12;
    final Paint bgPaint = Paint()
      ..color = Palette.cardWarm
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final Paint fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Palette.red, Palette.orange],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const double startAngle = -pi * 0.75;
    const double sweepAngle = pi * 1.5;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      startAngle,
      sweepAngle * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
