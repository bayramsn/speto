import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';

Future<void> showOrderRatingSheet(
  BuildContext context,
  SpetoOrder order,
) async {
  final BuildContext rootContext = context;
  final SpetoAppState appState = SpetoAppScope.of(context);
  int selectedRating = appState.ratingForOrder(order.id) ?? 0;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final String statusText = switch (selectedRating) {
            5 => 'Mükemmel',
            4 => 'Çok İyi',
            3 => 'İyi',
            2 => 'Geliştirilebilir',
            1 => 'Zayıf',
            _ => 'Puan Seç',
          };
          return Container(
            decoration: const BoxDecoration(
              color: Palette.base,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      'Siparişi Değerlendir',
                      style: context.spetoSectionTitleStyle(fontSize: 19),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order.vendor} sipariş deneyimini puanlayın.',
                      style: context.spetoDescriptionStyle(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(5, (int index) {
                          final int star = index + 1;
                          final bool active = star <= selectedRating;
                          return IconButton(
                            onPressed: () =>
                                setModalState(() => selectedRating = star),
                            icon: Icon(
                              active
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: active ? Palette.orange : Palette.faint,
                              size: 34,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        statusText,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SpetoPrimaryButton(
                      label: selectedRating == 0 ? 'Puan Seç' : 'Puanı Kaydet',
                      icon: Icons.star_rounded,
                      onTap: () {
                        if (selectedRating == 0) {
                          SpetoToast.show(
                            rootContext,
                            message: 'Devam etmek için yıldız seçin.',
                            icon: Icons.info_outline_rounded,
                          );
                          return;
                        }
                        appState.rateOrder(order.id, selectedRating);
                        Navigator.of(context).pop();
                        SpetoToast.show(
                          rootContext,
                          message:
                              '${order.vendor} için $selectedRating yıldız kaydedildi.',
                          icon: Icons.star_rounded,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedOrderTab = 0;

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final List<SpetoOrder> activeOrders = appState.activeOrders;
    final List<SpetoOrder> historyOrders = appState.historyOrders;
    final bool canPop = Navigator.of(context).canPop();
    return SpetoScreenScaffold(
      title: 'Siparişlerim',
      showBottomNav: true,
      activeNav: NavSection.orders,
      showBack: canPop,
      footer: const SizedBox(height: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _orderTabSelector(
              context,
              activeCount: activeOrders.length,
              historyCount: historyOrders.length,
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedOrderTab),
                child: _selectedOrderTab == 0
                    ? _activeOrdersPage(
                        context,
                        appState: appState,
                        activeOrders: activeOrders,
                      )
                    : _historyOrdersPage(context, historyOrders: historyOrders),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTabSelector(
    BuildContext context, {
    required int activeCount,
    required int historyCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Palette.cardWarm,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _orderTabButton(
              context,
              label: 'Aktif',
              count: activeCount,
              active: _selectedOrderTab == 0,
              onTap: () => setState(() => _selectedOrderTab = 0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _orderTabButton(
              context,
              label: 'Geçmiş',
              count: historyCount,
              active: _selectedOrderTab == 1,
              onTap: () => setState(() => _selectedOrderTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTabButton(
    BuildContext context, {
    required String label,
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Palette.red : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : Palette.soft,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? Colors.black.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : Palette.soft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeOrdersPage(
    BuildContext context, {
    required SpetoAppState appState,
    required List<SpetoOrder> activeOrders,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Aktif Siparişler',
              style: context.spetoSectionTitleStyle(),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Palette.cardWarm,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${activeOrders.length} aktif'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activeOrders.isEmpty)
          SpetoEmptyState(
            icon: Icons.receipt_long_outlined,
            iconColor: Palette.orange,
            title: 'Aktif siparişin yok',
            description:
                'Sepete yeni ürün eklediğinde siparişin burada canlı olarak görünecek.',
            primaryButtonLabel: 'Yeni Sipariş Oluştur',
            primaryButtonIcon: Icons.shopping_bag_outlined,
            onPrimaryButtonTap: () => openRootScreen(context, SpetoScreen.home),
          )
        else
          ...activeOrders.map(
            (SpetoOrder order) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _activeOrderCard(
                context,
                order: order,
                appState: appState,
              ),
            ),
          ),
      ],
    );
  }

  Widget _historyOrdersPage(
    BuildContext context, {
    required List<SpetoOrder> historyOrders,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Geçmiş Siparişler',
              style: context.spetoSectionTitleStyle(),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Palette.cardWarm,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${historyOrders.length} kayıt'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Tamamlanan ve iptal edilen siparişlerin ayrı fiş kayıtları burada tutulur.',
          style: context.spetoDescriptionStyle(),
        ),
        const SizedBox(height: 16),
        if (historyOrders.isEmpty)
          SpetoEmptyState(
            icon: Icons.history_toggle_off_rounded,
            iconColor: Palette.cyan,
            title: 'Henüz geçmiş sipariş yok',
            description:
                'Tamamlanan siparişlerin ve fiş kayıtların burada listelenecek.',
            primaryButtonLabel: 'Keşfet',
            primaryButtonIcon: Icons.explore_outlined,
            onPrimaryButtonTap: () => openRootScreen(context, SpetoScreen.home),
          )
        else
          ...historyOrders.map(
            (SpetoOrder order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HistoryTile(order: order),
            ),
          ),
      ],
    );
  }

  Widget _activeOrderCard(
    BuildContext context, {
    required SpetoOrder order,
    required SpetoAppState appState,
  }) {
    return SpetoCard(
      radius: 20,
      color: Palette.cardWarm,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
                      ) =>
                          Container(width: 48, height: 48, color: Palette.card),
                ),
              ),
              const SizedBox(width: 12),
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
                      '${order.itemCount} ürün • Toplam ${formatPrice(order.totalPrice)}',
                      style: context.spetoMetaStyle(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: orderStatusColor(order.status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          orderStatusLabel(order.status),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: context.spetoMetaStyle(color: Palette.muted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.etaLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0x33FFFFFF)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                appState.selectOrder(order);
                openScreen(context, SpetoScreen.orderTracking);
              },
              child: Text(order.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.order});

  final SpetoOrder order;

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final bool cancelled = order.status == SpetoOrderStatus.cancelled;
    return SpetoCard(
      radius: 18,
      color: Palette.cardWarm,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cancelled
                      ? Colors.red.withValues(alpha: 0.12)
                      : Palette.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  order.vendor.characters.first,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
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
                      '${order.placedAtLabel} • ${order.itemCount} ürün',
                      style: context.spetoMetaStyle(),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatPrice(order.totalPrice),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cancelled
                          ? Colors.red.withValues(alpha: 0.12)
                          : Palette.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      orderStatusLabel(order.status),
                      style: context.spetoMetaStyle(
                        color: cancelled ? Colors.redAccent : Palette.soft,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              appState.selectOrder(order);
              if (cancelled) {
                openScreen(context, SpetoScreen.orderReceipt);
                return;
              }
              appState.reorder(order);
              openScreen(context, SpetoScreen.happyHourCheckout);
            },
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: Text(cancelled ? 'Detayları Gör' : 'Tekrar Sipariş Ver'),
          ),
        ],
      ),
    );
  }
}
