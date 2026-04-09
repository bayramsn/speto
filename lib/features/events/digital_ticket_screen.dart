import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';
import 'event_data.dart';

class DigitalTicketScreen extends StatefulWidget {
  const DigitalTicketScreen({super.key});

  @override
  State<DigitalTicketScreen> createState() => _DigitalTicketScreenState();
}

class _DigitalTicketScreenState extends State<DigitalTicketScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final SpetoEventTicket ticket =
        appState.selectedTicket ?? featuredEventTicket;
    return SpetoScreenScaffold(
      title: 'Dijital Bilet',
      background: Palette.aubergine,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Palette.cardWarm,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SpetoImage(
                            url: ticket.image,
                            height: 160,
                            borderRadius: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          ticket.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Palette.soft,
                            ),
                            const SizedBox(width: 6),
                            Text(ticket.venue),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TicketInfo(
                                title: 'Tarih',
                                value: ticket.dateLabel,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TicketInfo(
                                title: 'Saat',
                                value: ticket.timeLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TicketInfo(
                                title: 'Bölüm',
                                value: ticket.zone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TicketInfo(
                                title: 'Koltuk',
                                value: ticket.seat,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TicketInfo(
                                title: 'Kapı',
                                value: ticket.gate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 2, color: Color(0x44FFFFFF)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Etkinlik girişinde bu kodu gösterin',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Palette.soft),
                        ),
                        const SizedBox(height: 18),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: Container(
                              width: 218,
                              height: 218,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.cover,
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Colors.black,
                                  size: 200,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ticket.code,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Palette.soft),
                        ),
                        const SizedBox(height: 20),
                        SpetoCard(
                          radius: 16,
                          color: Palette.base,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(Icons.wallet_outlined),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Cüzdana Ekle',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Kullanılan Pro puan: ${formatPoints(ticket.pointsCost)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Palette.soft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => copyShareLinkToClipboard(
                context,
                path: 'tickets/${ticket.id}',
                successMessage: 'Bilet bağlantısı panoya kopyalandı.',
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Bileti Paylaş'),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketInfo extends StatelessWidget {
  const TicketInfo({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SpetoCard(
      radius: 18,
      color: Palette.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Palette.muted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

