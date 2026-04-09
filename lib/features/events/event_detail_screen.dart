import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';
import '../../features/restaurant/menu_item_detail_screen.dart';
import 'event_data.dart';
import 'events_discovery_screen.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EventDetailScreenContent(event: featuredEventExperience);
  }
}

void openExternalDirections(
  BuildContext context, {
  required String title,
  required String subtitle,
}) {
  final Uri uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$title $subtitle')}',
  );
  launchUrl(uri, mode: LaunchMode.externalApplication);
}

class EventDetailScreenContent extends StatelessWidget {
  const EventDetailScreenContent({required this.event});

  final EventExperience event;

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final bool isFavorite = appState.isEventFavorite(event.id);
    final String organizerId = slugify(event.organizer);
    final bool isFollowingOrganizer = appState.isOrganizerFollowed(organizerId);
    return Scaffold(
      backgroundColor: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 488,
                pinned: true,
                backgroundColor: Palette.aubergine,
                leadingWidth: 72,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: roundButton(
                    context,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: roundButton(
                      context,
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Palette.red : Colors.white,
                      onTap: () {
                        final bool willFavorite = !appState.isEventFavorite(
                          event.id,
                        );
                        appState.toggleEventFavorite(event.id);
                        SpetoToast.show(
                          context,
                          message: willFavorite
                              ? '${event.title} favorilerine eklendi.'
                              : '${event.title} favorilerden çıkarıldı.',
                          icon: willFavorite
                              ? Icons.favorite_rounded
                              : Icons.heart_broken_outlined,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: roundButton(
                      context,
                      icon: Icons.share_outlined,
                      onTap: () => copyShareLinkToClipboard(
                        context,
                        path: 'events/${slugify(event.title)}',
                        successMessage:
                            'Etkinlik bağlantısı panoya kopyalandı.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      SpetoImage(
                        url: event.image,
                        height: 488,
                        borderRadius: 0,
                        heroTag: event.image,
                        overlay: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Colors.transparent,
                                Palette.aubergine,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.confirmation_num_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BİLET SATIŞTA',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.08,
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
                                Text(event.venue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: const BoxDecoration(
                        color: Palette.aubergine,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SpetoCard(
                            radius: 18,
                            color: Palette.cardWarm,
                            child: Row(
                              children: <Widget>[
                                IconMetric(
                                  icon: Icons.groups_rounded,
                                  value: event.participantLabel,
                                  label: 'Katılımcı',
                                ),
                                const SizedBox(width: 12),
                                IconMetric(
                                  icon: Icons.confirmation_num_outlined,
                                  value: event.ticketCategory,
                                  label: 'Kategori',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Hakkında',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Palette.soft, height: 1.8),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              InfoTag(
                                label: event.primaryTag,
                                icon: Icons.music_note_rounded,
                              ),
                              InfoTag(
                                label: event.venue,
                                icon: Icons.location_city_outlined,
                              ),
                              InfoTag(
                                label: event.secondaryTag,
                                icon: Icons.verified_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SpetoCard(
                            radius: 18,
                            color: Palette.cardWarm,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Palette.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.stars_rounded,
                                    color: Palette.orange,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Bilet ödemesi sadece Pro ile yapılır',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sepette nakit indirimi yok. Güncel bakiye: ${formatPoints(appState.proPointsBalance)}',
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
                          const SizedBox(height: 24),
                          Text(
                            'Konum',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          SpetoCard(
                            radius: 18,
                            color: Palette.cardWarm,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SpetoImage(
                                  url:
                                      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
                                  height: 160,
                                  borderRadius: 14,
                                  overlay: const Center(
                                    child: Icon(
                                      Icons.location_pin,
                                      color: Palette.red,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Palette.red.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
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
                                            event.locationTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          Text(
                                            event.locationSubtitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Palette.muted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => openExternalDirections(
                                        context,
                                        title: event.locationTitle,
                                        subtitle: event.locationSubtitle,
                                      ),
                                      child: const Text('Yol Tarifi'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SpetoCard(
                            radius: 18,
                            color: Palette.cardWarm,
                            child: Row(
                              children: <Widget>[
                                const CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    AppImages.profile,
                                  ),
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Organizatör',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Palette.muted),
                                      ),
                                      Text(
                                        event.organizer,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final bool willFollow = !appState
                                        .isOrganizerFollowed(organizerId);
                                    appState.toggleOrganizerFollow(organizerId);
                                    SpetoToast.show(
                                      context,
                                      message: willFollow
                                          ? '${event.organizer} güncellemeleri takip ediliyor.'
                                          : '${event.organizer} takibi kapatıldı.',
                                      icon: willFollow
                                          ? Icons.notifications_active_outlined
                                          : Icons.notifications_off_outlined,
                                    );
                                  },
                                  child: Text(
                                    isFollowingOrganizer
                                        ? 'Takibi Bırak'
                                        : 'Takip Et',
                                  ),
                                ),
                              ],
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Palette.cardWarm.withValues(alpha: 0.94),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Giriş',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Palette.muted),
                        ),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                            children: <TextSpan>[
                              TextSpan(text: formatPoints(event.pointsCost)),
                              TextSpan(
                                text: ' / kişi',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Palette.soft,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SpetoPrimaryButton(
                        label: appState.canPurchaseTicket(event.pointsCost)
                            ? 'Pro ile Al'
                            : 'Puan Yetersiz',
                        icon: Icons.workspace_premium_rounded,
                        onTap: () {
                          if (!appState.canPurchaseTicket(event.pointsCost)) {
                            openScreen(context, SpetoScreen.proPoints);
                            return;
                          }
                          showEventTicketSelectionSheet(
                            context,
                            appState,
                            event,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

