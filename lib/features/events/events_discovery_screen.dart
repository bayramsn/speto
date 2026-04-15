import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/home/home_dashboard_screen.dart';
import 'event_data.dart';
import 'event_detail_screen.dart';

Future<void> showEventTicketSelectionSheet(
  BuildContext context,
  SpetoAppState appState,
  EventExperience event,
) {
  final BuildContext rootContext = context;
  const List<Map<String, String>> seatOptions = <Map<String, String>>[
    <String, String>{'zone': 'VIP', 'seat': 'A12', 'gate': 'G3'},
    <String, String>{'zone': 'VIP', 'seat': 'A14', 'gate': 'G3'},
    <String, String>{'zone': 'Salon', 'seat': 'B08', 'gate': 'G2'},
  ];

  int selectedSeatIndex = 0;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final Map<String, String> activeSeat = seatOptions[selectedSeatIndex];
          return FractionallySizedBox(
            heightFactor: 0.68,
            child: Container(
              decoration: const BoxDecoration(
                color: Palette.base,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Biletini Seç',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bölge ve koltuk seçimini tamamla. Pro puan yalnızca etkinliklerde kullanılır.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Palette.soft,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...List<Widget>.generate(seatOptions.length, (int index) {
                        final Map<String, String> item = seatOptions[index];
                        final bool selected = index == selectedSeatIndex;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == seatOptions.length - 1 ? 0 : 12,
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedSeatIndex = index),
                            child: SpetoCard(
                              radius: 22,
                              color: selected ? Palette.cardWarm : Palette.card,
                              borderColor: selected
                                  ? Palette.red.withValues(alpha: 0.24)
                                  : Colors.white.withValues(alpha: 0.06),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Palette.red.withValues(alpha: 0.14)
                                          : Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.event_seat_outlined,
                                      color: selected
                                          ? Palette.red
                                          : Palette.soft,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          '${item['zone']} • ${item['seat']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kapı ${item['gate']} • ${formatPoints(event.pointsCost)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Palette.soft),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: selected
                                        ? Palette.red
                                        : Palette.faint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      SpetoPrimaryButton(
                        label: 'Pro ile Aç • ${formatPoints(event.pointsCost)}',
                        icon: Icons.workspace_premium_rounded,
                        onTap: () async {
                          final bool purchased = await appState
                              .purchaseEventTicket(
                                eventId: event.id,
                                title: event.title,
                                venue: event.venue,
                                dateLabel: event.dateLabel,
                                timeLabel: event.timeLabel,
                                image: event.image,
                                pointsCost: event.pointsCost,
                                seat: activeSeat['seat']!,
                                zone: activeSeat['zone']!,
                                gate: activeSeat['gate']!,
                              );
                          if (!context.mounted || !rootContext.mounted) {
                            return;
                          }
                          if (!purchased) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bu bilet için yeterli Pro puanın yok.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          openScreen(rootContext, SpetoScreen.ticketSuccess);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class EventsDiscoveryScreen extends StatefulWidget {
  const EventsDiscoveryScreen({super.key});

  @override
  State<EventsDiscoveryScreen> createState() => _EventsDiscoveryScreenState();
}

class _EventsDiscoveryScreenState extends State<EventsDiscoveryScreen> {
  int _selectedEventFilter = 0;

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final List<String> availableFilters = eventFilters.isEmpty
        ? const <String>['Hepsi']
        : eventFilters;
    final int activeFilterIndex =
        _selectedEventFilter >= availableFilters.length
        ? 0
        : _selectedEventFilter;
    final String selectedCategory = availableFilters[activeFilterIndex];
    final List<EventExperience> categoryEvents = eventsForCategory(
      selectedCategory,
    );
    final EventExperience? featuredEvent = categoryEvents.isNotEmpty
        ? categoryEvents.first
        : null;
    final List<EventExperience> secondaryEvents = categoryEvents
        .skip(1)
        .toList();
    return SpetoScreenScaffold(
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.explore,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Konum',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Palette.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'İstanbul Avrupa',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                roundButton(
                  context,
                  icon: Icons.notifications_none_rounded,
                  onTap: () => openScreen(context, SpetoScreen.helpCenter),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Etkinlikleri Keşfet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => showDiscoverySearchSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Palette.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.search_rounded, color: Palette.faint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sanatçı, konser veya mekan ara...',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Palette.faint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableFilters.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 10),
                itemBuilder: (_, int index) {
                  final bool active = index == activeFilterIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEventFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? Palette.red : Palette.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        availableFilters[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: active ? Colors.white : Palette.soft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            SpetoCard(
              radius: 22,
              gradient: const LinearGradient(
                colors: <Color>[Color(0x33FF3D00), Color(0x66221210)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: Palette.red.withValues(alpha: 0.16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Palette.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
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
                          'Etkinlik biletleri Pro ile açılır',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Güncel bakiye: ${formatPoints(appState.proPointsBalance)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Palette.soft),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        openRootScreen(context, SpetoScreen.proPoints),
                    child: const Text('Puanı Gör'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (featuredEvent == null)
              SpetoCard(
                radius: 24,
                color: Palette.cardWarm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Bu kategori için etkinlik bulunamadı',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canlı etkinlik akışı güncellendiğinde burada otomatik listelenecek.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Palette.soft,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  spetoRoute(EventDetailScreenContent(event: featuredEvent)),
                ),
                child: SpetoCard(
                  padding: EdgeInsets.zero,
                  radius: 32,
                  child: SizedBox(
                    height: 438,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        SpetoImage(
                          url: featuredEvent.image,
                          height: 438,
                          borderRadius: 32,
                          heroTag: featuredEvent.image,
                          overlay: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  featuredEvent.dateLabel
                                      .split(' ')
                                      .elementAt(1),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: Colors.black54),
                                ),
                                Text(
                                  featuredEvent.dateLabel.split(' ').first,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  LabelChip(
                                    label: featuredEvent.primaryTag,
                                    background: Colors.black54,
                                  ),
                                  const SizedBox(width: 8),
                                  LabelChip(
                                    label: featuredEvent.secondaryTag,
                                    background: Colors.black54,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                featuredEvent.title.replaceFirst(' ', '\n'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(featuredEvent.venue),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(featuredEvent.timeLabel),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Biletler',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                      Text(
                                        formatPoints(featuredEvent.pointsCost),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Palette.red,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Text(
                                      'Pro ile Aç',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
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
              ),
            const SizedBox(height: 24),
            if (featuredEvent != null) ...<Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '$selectedCategory Etkinlikleri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tümünü Gör',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Palette.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (secondaryEvents.isEmpty)
                SpetoCard(
                  radius: 20,
                  color: Palette.cardWarm,
                  child: Text(
                    'Bu kategori için gösterilecek ek etkinlik yok.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
                  ),
                )
              else
                ...List<Widget>.generate(secondaryEvents.length, (int index) {
                  final EventExperience event = secondaryEvents[index];
                  final bool useMiniCard = index.isEven;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == secondaryEvents.length - 1 ? 0 : 16,
                    ),
                    child: useMiniCard
                        ? _miniEventCard(context, event)
                        : _compactEventCard(context, event),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniEventCard(BuildContext context, EventExperience event) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(spetoRoute(EventDetailScreenContent(event: event))),
      child: SpetoCard(
        radius: 24,
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                event.image,
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
                      color: Palette.cardWarm,
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Palette.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.venue,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Palette.soft),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Text(
                        formatPoints(event.pointsCost),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Detayı Gör',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }

  Widget _compactEventCard(BuildContext context, EventExperience event) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(spetoRoute(EventDetailScreenContent(event: event))),
      child: SpetoCard(
        padding: EdgeInsets.zero,
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SpetoImage(
              url: event.image,
              height: 160,
              borderRadius: 24,
              overlay: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${event.dateLabel} • ${event.timeLabel} • ${formatPoints(event.pointsCost)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Palette.soft),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Palette.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
