import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import '../restaurant/restaurant_detail_screen.dart';

class HappyHourOfferDetailScreen extends StatelessWidget {
  const HappyHourOfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final SpetoHappyHourOffer offer =
        appState.selectedHappyHourOffer ??
        (appState.happyHourOffers.isNotEmpty
            ? appState.happyHourOffers.first
            : defaultHappyHourOffers().first);
    final bool canPurchase = appState.canPurchaseProduct(offer.productId);
    final String? stockWarning = appState.stockWarningForProduct(offer.productId);
    final int hours = offer.expiresInMinutes ~/ 60;
    final int minutes = offer.expiresInMinutes % 60;

    return Scaffold(
      backgroundColor: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    SpetoImage(
                      url: offer.imageUrl,
                      height: 320,
                      borderRadius: 0,
                      heroTag: offer.id,
                      overlay: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.black.withValues(alpha: 0.15),
                              Palette.aubergine,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            roundButton(
                              context,
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            roundButton(
                              context,
                              icon: Icons.share_outlined,
                              onTap: () => copyShareLinkToClipboard(
                                context,
                                path: 'offers/happy-hour/${offer.id}',
                                successMessage:
                                    'Happy Hour fırsat bağlantısı panoya kopyalandı.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: LabelChip(
                        label: offer.badge,
                        color: Palette.crimson,
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Palette.aubergine,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Column(
                            children: <Widget>[
                              Text(
                                'TEKLİFİN BİTMESİNE',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Palette.crimson.withValues(
                                        alpha: 0.8,
                                      ),
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _timeBox(
                                    context,
                                    hours.toString().padLeft(2, '0'),
                                    'Saat',
                                  ),
                                  _separator(context),
                                  _timeBox(
                                    context,
                                    minutes.toString().padLeft(2, '0'),
                                    'Dak',
                                    active: true,
                                  ),
                                  _separator(context),
                                  _timeBox(context, '00', 'Sn'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          offer.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offer.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Palette.soft, height: 1.6),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Text(
                              offer.discountedPriceText,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Palette.crimson,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              offer.originalPriceText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Palette.faint,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '+${offer.rewardPoints} Puan',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Palette.orange,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, color: Color(0x22FFFFFF)),
                        if (stockWarning != null) ...<Widget>[
                          SpetoCard(
                            radius: 16,
                            color: offer.stockStatus.isInStock
                                ? Palette.cardWarm
                                : Palette.card,
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  offer.stockStatus.isInStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.remove_shopping_cart_outlined,
                                  color: offer.stockStatus.isInStock
                                      ? Palette.orange
                                      : Palette.crimson,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    stockWarning,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          'AÇIKLAMA',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Palette.muted,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          offer.description,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Palette.soft, height: 1.8),
                        ),
                        const SizedBox(height: 22),
                        SpetoCard(
                          radius: 16,
                          color: Palette.cardWarm,
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Palette.crimson.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: Palette.crimson,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          offer.locationTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          offer.locationSubtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Palette.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.local_fire_department_outlined,
                                    color: Palette.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${offer.claimCount} kişi bugün bu fırsatı kullandı.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Palette.soft),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.category_outlined,
                                    color: Palette.red,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${offer.vendorName} • ${offer.sectionLabel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Palette.soft),
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
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                          'Toplam Tutar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Palette.muted),
                        ),
                        Text(
                          offer.discountedPriceText,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SpetoPrimaryButton(
                        label: appState.hasCart
                            ? 'Sepete Ekle ve Devam Et'
                            : 'Hemen Al',
                        icon: Icons.arrow_forward_rounded,
                        onTap: () {
                          if (!canPurchase) {
                            SpetoToast.show(
                              context,
                              message:
                                  stockWarning ??
                                  '${offer.title} şu anda satın alınamıyor.',
                              icon: Icons.info_outline_rounded,
                            );
                            return;
                          }
                          addCartItemAndOpenCheckout(
                            context,
                            SpetoCartItem(
                              id: offer.productId,
                              vendor: offer.vendorName,
                              title: offer.title,
                              image: offer.imageUrl,
                              unitPrice: offer.discountedPrice,
                            ),
                            notice: '${offer.title} sepete eklendi.',
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

  Widget _timeBox(
    BuildContext context,
    String value,
    String label, {
    bool active = false,
  }) {
    return Column(
      children: <Widget>[
        Container(
          width: 48,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.cardWarm,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: active ? Palette.crimson : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Palette.muted),
        ),
      ],
    );
  }

  Widget _separator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
