import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../src/core/domain_api.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import 'order_history_screen.dart';

class OrderReceiptScreen extends StatelessWidget {
  const OrderReceiptScreen({super.key});

  Future<void> _completeOrderAndReturnHome(
    BuildContext context,
    SpetoAppState appState,
    SpetoOrder order,
  ) async {
    try {
      appState.selectOrder(order);
      if (order.status == SpetoOrderStatus.active) {
        await appState.completeSelectedOrder();
      }
      if (!context.mounted) {
        return;
      }
      openRootScreen(context, SpetoScreen.home);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final String message;
      if (error is SpetoRemoteApiException) {
        message = 'Sipariş tamamlanamadı. Lütfen tekrar dene.';
      } else {
        message = 'Bir sorun oluştu. Lütfen tekrar dene.';
      }
      SpetoToast.show(
        context,
        message: message,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final SpetoOrder? order = appState.selectedOrder;
    if (order == null) {
      return SpetoScreenScaffold(
        title: 'Sipariş Fişi',
        showBottomNav: true,
        activeNav: NavSection.orders,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: SpetoEmptyState(
            icon: Icons.receipt_long_outlined,
            iconColor: Palette.cyan,
            title: 'Gösterilecek fiş yok',
            description:
                'Tamamlanan veya geçmiş sipariş oluştuğunda fiş detayları burada gösterilecek.',
            primaryButtonLabel: 'Siparişlerime Git',
            primaryButtonIcon: Icons.history_rounded,
            onPrimaryButtonTap: () =>
                openRootScreen(context, SpetoScreen.orderHistory),
          ),
        ),
      );
    }
    final int? currentRating = appState.ratingForOrder(order.id);
    return SpetoScreenScaffold(
      title: 'Sipariş Fişi',
      backFallbackScreen: SpetoScreen.orderHistory,
      footer: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          color: Palette.base,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: SpetoCard(
                      radius: 16,
                      color: Palette.cardWarm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.receipt_long_rounded),
                          const SizedBox(width: 10),
                          Text(
                            'Fatura',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SpetoPrimaryButton(
                      label: currentRating == null
                          ? 'Siparişi Değerlendir'
                          : 'Puanı Güncelle • $currentRating/5',
                      icon: currentRating == null
                          ? Icons.star_rounded
                          : Icons.stars_rounded,
                      onTap: () => showOrderRatingSheet(context, order),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SpetoSecondaryButton(
                label: 'Siparişi tamamla ve ana sayfaya dön',
                height: 48,
                onTap: () =>
                    _completeOrderAndReturnHome(context, appState, order),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SpetoCard(
              radius: 20,
              color: Palette.cardWarm,
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      order.image,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => Container(
                            width: 64,
                            height: 64,
                            color: Palette.card,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          order.vendor,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.placedAtLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Palette.soft),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: orderStatusColor(
                                  order.status,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                orderStatusLabel(order.status),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: orderStatusColor(order.status),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              order.etaLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Palette.soft),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SpetoCard(
              radius: 20,
              color: Palette.cardWarm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Sipariş İçeriği',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...order.items.asMap().entries.map(
                    (MapEntry<int, SpetoCartItem> entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == order.items.length - 1 ? 0 : 12,
                      ),
                      child: ReceiptItem(
                        qty: '${entry.value.quantity}',
                        title: entry.value.title,
                        price: formatPrice(entry.value.totalPrice),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0x33FFFFFF)),
                  const SizedBox(height: 18),
                  _summaryRow(
                    context,
                    'Ara Toplam',
                    formatPrice(order.totalPrice),
                  ),
                  _summaryRow(
                    context,
                    'Sipariş Modu',
                    '${order.deliveryMode} • ${formatPrice(order.deliveryFee)}',
                  ),
                  _summaryRow(context, 'Ödeme', order.paymentMethod),
                  if (order.promoCode.isNotEmpty)
                    _summaryRow(
                      context,
                      'Kampanya',
                      '${order.promoCode} • -${formatPrice(order.discountAmount)}',
                    ),
                  _summaryRow(
                    context,
                    'Kazanılan Puan',
                    '+${formatPoints(order.rewardPoints)}',
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0x33FFFFFF)),
                  const SizedBox(height: 8),
                  _summaryRow(
                    context,
                    'Toplam',
                    formatPrice(order.payableTotal),
                    strong: true,
                  ),
                  const SizedBox(height: 18),
                  SpetoCard(
                    radius: 14,
                    color: Palette.base,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: Palette.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bu siparişten +${formatPoints(order.rewardPoints)} kazandınız.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Palette.soft),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SpetoCard(
              radius: 18,
              color: Palette.cardWarm,
              child: Column(
                children: <Widget>[
                  Text(
                    'Yardıma mı ihtiyacın var?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sipariş ile ilgili destek, iptal ve iade akışları yardım merkezinde hazır.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Palette.soft,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () =>
                        openScreen(context, SpetoScreen.helpCenter),
                    child: const Text('Müşteri desteğine ulaş'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) {
    final TextStyle? valueStyle = strong
        ? Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: strong ? Colors.white : Palette.soft,
            ),
          ),
          const Spacer(),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class ReceiptItem extends StatelessWidget {
  const ReceiptItem({
    super.key,
    required this.qty,
    required this.title,
    required this.price,
  });

  final String qty;
  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Palette.base,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(qty, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          price,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
