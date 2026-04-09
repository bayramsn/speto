import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/marketplace/market_store_detail_screen.dart';
import 'home_data.dart';

class HappyHourListScreen extends StatelessWidget {
  const HappyHourListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ListingCardData> items = <ListingCardData>[
      const ListingCardData(
        title: 'Burger King',
        subtitle: 'Mega burger menü',
        meta: '00:45 kaldı',
        price: '85 TL',
        image: AppImages.burger,
      ),
      const ListingCardData(
        title: 'Espresso Lab',
        subtitle: 'Latte + kruvasan',
        meta: '00:52 kaldı',
        price: '69 TL',
        image: AppImages.nightlife,
      ),
      const ListingCardData(
        title: 'Pizza Locale',
        subtitle: 'Pepperoni dilim menü',
        meta: '01:10 kaldı',
        price: '79 TL',
        image: AppImages.burgerHero,
      ),
    ];
    return SpetoScreenScaffold(
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.explore,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Happy Hour',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                roundButton(
                  context,
                  icon: Icons.tune_rounded,
                  onTap: () => openScreen(context, SpetoScreen.appMap),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, int index) {
                  final bool active = index == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active ? Palette.red : Palette.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      filterChips[index],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : Palette.soft,
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 12),
                itemCount: filterChips.length,
              ),
            ),
            const SizedBox(height: 24),
            ...items.map(
              (ListingCardData item) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () => openScreen(context, SpetoScreen.happyHourDetail),
                  child: SpetoCard(
                    padding: EdgeInsets.zero,
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            SpetoImage(
                              url: item.image,
                              height: 192,
                              borderRadius: 24,
                              heroTag: item.image,
                              overlay: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Colors.black.withValues(alpha: 0.0),
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Palette.red,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '%35 İndirim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '+50 Puan',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Palette.orange,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          item.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.subtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: Palette.soft),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Palette.orange.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: Palette.orange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.meta,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Palette.orange,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              Row(
                                children: <Widget>[
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(
                                      AppImages.profile,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '24 kişi bugün aldı',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Palette.soft),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => openScreen(
                                      context,
                                      SpetoScreen.happyHourDetail,
                                    ),
                                    icon: const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 14,
                                    ),
                                    label: const Text('Hemen Al'),
                                  ),
                                ],
                              ),
                              Text(
                                item.price,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Palette.red,
                                      fontWeight: FontWeight.w900,
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
      ),
    );
  }
}

