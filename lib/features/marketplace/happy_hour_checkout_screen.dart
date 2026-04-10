import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../src/core/domain_api.dart';
import '../../src/core/models.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';
import '../../shared/widgets/widgets.dart';

Future<void> showAddressFormSheet(
  BuildContext context, {
  SpetoAddress? address,
}) async {
  final BuildContext rootContext = context;
  final SpetoAppState appState = SpetoAppScope.of(context);
  final TextEditingController labelController = TextEditingController(
    text: address?.label ?? '',
  );
  final TextEditingController addressController = TextEditingController(
    text: address?.address ?? '',
  );
  String iconKey = address?.iconKey ?? 'home';
  bool isPrimary = address?.isPrimary ?? appState.addresses.isEmpty;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return FractionallySizedBox(
            heightFactor: 0.78,
            child: Container(
              decoration: const BoxDecoration(
                color: Palette.base,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
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
                          address == null ? 'Yeni Adres' : 'Adresi Düzenle',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 18),
                        LabeledField(
                          label: 'Adres Başlığı',
                          icon: Icons.bookmark_outline_rounded,
                          controller: labelController,
                        ),
                        const SizedBox(height: 18),
                        LabeledField(
                          label: 'Açık Adres',
                          icon: Icons.location_on_outlined,
                          controller: addressController,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'İKON',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Palette.muted,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              <MapEntry<String, String>>[
                                    const MapEntry<String, String>(
                                      'home',
                                      'Ev',
                                    ),
                                    const MapEntry<String, String>(
                                      'work',
                                      'İş',
                                    ),
                                    const MapEntry<String, String>(
                                      'school',
                                      'Okul',
                                    ),
                                    const MapEntry<String, String>(
                                      'favorite',
                                      'Favori',
                                    ),
                                  ]
                                  .map(
                                    (MapEntry<String, String> entry) => TabChip(
                                      label: entry.value,
                                      active: entry.key == iconKey,
                                      onTap: () => setModalState(
                                        () => iconKey = entry.key,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 18),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: Palette.red,
                          activeTrackColor: Palette.red.withValues(alpha: 0.32),
                          title: const Text('Varsayılan adres yap'),
                          value: isPrimary,
                          onChanged: (bool value) =>
                              setModalState(() => isPrimary = value),
                        ),
                        const SizedBox(height: 16),
                        SpetoPrimaryButton(
                          label: address == null ? 'Adresi Kaydet' : 'Güncelle',
                          icon: Icons.save_outlined,
                          onTap: () async {
                            final String label = labelController.text.trim();
                            final String fullAddress = addressController.text
                                .trim();
                            if (label.isEmpty || fullAddress.isEmpty) {
                              SpetoToast.show(
                                rootContext,
                                message: 'Adres başlığı ve açık adres gerekli.',
                                icon: Icons.info_outline_rounded,
                              );
                              return;
                            }
                            await appState.saveAddress(
                              SpetoAddress(
                                id:
                                    address?.id ??
                                    'address-${DateTime.now().microsecondsSinceEpoch}',
                                label: label,
                                address: fullAddress,
                                iconKey: iconKey,
                                isPrimary: isPrimary,
                              ),
                            );
                            if (!rootContext.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            SpetoToast.show(
                              rootContext,
                              message: isPrimary
                                  ? '$label varsayılan adres olarak kaydedildi.'
                                  : '$label adresi kaydedildi.',
                              icon: Icons.location_on_outlined,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  labelController.dispose();
  addressController.dispose();
}

Future<void> showPaymentCardFormSheet(
  BuildContext context, {
  SpetoPaymentCard? card,
}) async {
  final BuildContext rootContext = context;
  final SpetoAppState appState = SpetoAppScope.of(context);
  final TextEditingController brandController = TextEditingController(
    text: card?.brand ?? '',
  );
  final TextEditingController holderController = TextEditingController(
    text: card?.holderName ?? appState.displayName,
  );
  final TextEditingController last4Controller = TextEditingController(
    text: card?.last4 ?? '',
  );
  final TextEditingController expiryController = TextEditingController(
    text: card?.expiry ?? '',
  );
  bool isDefault = card?.isDefault ?? appState.paymentCards.isEmpty;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return FractionallySizedBox(
            heightFactor: 0.82,
            child: Container(
              decoration: const BoxDecoration(
                color: Palette.base,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
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
                          card == null ? 'Yeni Ödeme Kartı' : 'Kartı Düzenle',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 18),
                        LabeledField(
                          label: 'Kart Markası',
                          icon: Icons.credit_card_rounded,
                          controller: brandController,
                        ),
                        const SizedBox(height: 18),
                        LabeledField(
                          label: 'Kart Sahibi',
                          icon: Icons.person_outline_rounded,
                          controller: holderController,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledField(
                                label: 'Son 4 Hane',
                                icon: Icons.lock_outline_rounded,
                                controller: last4Controller,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: LabeledField(
                                label: 'Son Kullanma',
                                icon: Icons.date_range_outlined,
                                controller: expiryController,
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: Palette.red,
                          activeTrackColor: Palette.red.withValues(alpha: 0.32),
                          title: const Text('Varsayılan kart yap'),
                          value: isDefault,
                          onChanged: (bool value) =>
                              setModalState(() => isDefault = value),
                        ),
                        const SizedBox(height: 16),
                        SpetoPrimaryButton(
                          label: card == null
                              ? 'Kartı Kaydet'
                              : 'Kartı Güncelle',
                          icon: Icons.save_outlined,
                          onTap: () async {
                            final String brand = brandController.text.trim();
                            final String last4 = last4Controller.text.trim();
                            final String expiry = expiryController.text.trim();
                            final String holder = holderController.text.trim();
                            if (brand.isEmpty ||
                                holder.isEmpty ||
                                last4.length != 4 ||
                                expiry.isEmpty) {
                              SpetoToast.show(
                                rootContext,
                                message:
                                    'Kart markası, sahibi, son 4 hane ve son kullanma gerekli.',
                                icon: Icons.info_outline_rounded,
                              );
                              return;
                            }
                            await appState.savePaymentCard(
                              SpetoPaymentCard(
                                id:
                                    card?.id ??
                                    'card-${DateTime.now().microsecondsSinceEpoch}',
                                brand: brand,
                                last4: last4,
                                expiry: expiry,
                                holderName: holder,
                                isDefault: isDefault,
                              ),
                            );
                            if (!rootContext.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            SpetoToast.show(
                              rootContext,
                              message: '•••• $last4 kartı kaydedildi.',
                              icon: Icons.credit_card_rounded,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  brandController.dispose();
  holderController.dispose();
  last4Controller.dispose();
  expiryController.dispose();
}

class HappyHourCheckoutScreen extends StatefulWidget {
  const HappyHourCheckoutScreen({super.key});

  @override
  State<HappyHourCheckoutScreen> createState() =>
      _HappyHourCheckoutScreenState();
}

class _HappyHourCheckoutScreenState extends State<HappyHourCheckoutScreen> {
  int _selectedPaymentMethod = 0;
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  double _deliveryFee() => 0;

  double _promoDiscount(double subtotal) {
    if ((_appliedPromoCode ?? '').toUpperCase() != 'SEPETPRO10') {
      return 0;
    }
    return math.min(40, subtotal * 0.10);
  }

  String _selectedPaymentLabel(SpetoAppState appState) {
    if (_selectedPaymentMethod == 0) {
      return 'Apple Pay';
    }
    final int index = _selectedPaymentMethod - 1;
    if (index >= 0 && index < appState.paymentCards.length) {
      final SpetoPaymentCard card = appState.paymentCards[index];
      return '${card.brand} •••• ${card.last4}';
    }
    return 'Apple Pay';
  }

  void _applyPromoCode() {
    final String code = _promoController.text.trim().toUpperCase();
    if (code == 'SEPETPRO10') {
      setState(() => _appliedPromoCode = code);
      SpetoToast.show(
        context,
        message: 'SEPETPRO10 indirimi uygulandı.',
        icon: Icons.discount_rounded,
      );
      return;
    }
    SpetoToast.show(
      context,
      message: 'Geçerli bir kampanya kodu girin.',
      icon: Icons.info_outline_rounded,
    );
  }

  String _pickupPointLabel(
    SpetoAppState appState,
    SpetoAddress? primaryAddress,
  ) {
    final List<SpetoCartItem> cartItems = appState.cartItems;
    if (cartItems.isEmpty) {
      return primaryAddress?.label ?? 'Gel-Al noktası';
    }

    final SpetoCartItem firstCartItem = cartItems.first;
    for (final SpetoHappyHourOffer offer in appState.happyHourOffers) {
      if ((offer.productId == firstCartItem.id ||
              offer.id == firstCartItem.id) &&
          offer.locationTitle.trim().isNotEmpty) {
        return offer.locationTitle;
      }
    }

    final String normalizedVendor = firstCartItem.vendor.trim().toLowerCase();
    for (final SpetoHappyHourOffer offer in appState.happyHourOffers) {
      if (offer.vendorName.trim().toLowerCase() == normalizedVendor &&
          offer.locationTitle.trim().isNotEmpty) {
        return offer.locationTitle;
      }
    }

    return primaryAddress?.label ?? 'Gel-Al noktası';
  }

  String _checkoutErrorMessage(Object error) {
    if (error is SpetoRemoteApiException) {
      final String backendMessage = _backendMessage(error);
      if (backendMessage.startsWith('Insufficient stock for ')) {
        return 'Stok yetersiz. Lütfen sepetini yeniden kontrol et.';
      }
      if (backendMessage.contains('Pickup point')) {
        return 'Gel-al noktası doğrulanamadı. Lütfen tekrar dene.';
      }
      if (backendMessage.startsWith('Product ')) {
        return 'Ürün doğrulanamadı. Lütfen sepeti yenileyip tekrar dene.';
      }
    }
    return 'Ödeme tamamlanamadı. Lütfen tekrar dene.';
  }

  String _backendMessage(SpetoRemoteApiException error) {
    final String body = error.body?.trim() ?? '';
    if (body.isEmpty) {
      return error.message;
    }
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        final Object? message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is List<Object?>) {
          for (final Object? item in message) {
            if (item is String && item.trim().isNotEmpty) {
              return item.trim();
            }
          }
        }
      }
    } catch (_) {
      return error.message;
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final List<SpetoCartItem> cartItems = appState.cartItems;
    final SpetoAddress? primaryAddress = appState.primaryAddress;
    final String pickupPointLabel = _pickupPointLabel(appState, primaryAddress);
    final bool hasCart = cartItems.isNotEmpty;
    final double subtotal = appState.cartSubtotal;
    final double deliveryFee = _deliveryFee();
    final double discountAmount = _promoDiscount(subtotal);
    final double checkoutTotal = subtotal + deliveryFee - discountAmount;
    final double earnedProPoints = appState.earnedProPointsForTotal(
      checkoutTotal,
    );
    return SpetoScreenScaffold(
      title: 'Sepetim',
      showBottomNav: true,
      activeNav: NavSection.basket,
      footer: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          color: Palette.base,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (hasCart)
                Row(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Genel Toplam',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Palette.muted),
                        ),
                        Text(
                          formatPrice(checkoutTotal),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${appState.cartCount} ürün',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Palette.orange,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              if (hasCart) const SizedBox(height: 8),
              if (hasCart)
                SpetoSecondaryButton(
                  label: 'Ana sayfaya dön',
                  onTap: () => openRootScreen(context, SpetoScreen.home),
                ),
              SpetoPrimaryButton(
                label: hasCart ? 'Ödemeyi Tamamla' : 'Keşfet ekranına dön',
                icon: Icons.arrow_forward_rounded,
                onTap: () async {
                  if (!hasCart) {
                    openRootScreen(context, SpetoScreen.home);
                    return;
                  }
                  try {
                    await appState.checkout(
                      deliveryMode: 'Gel-Al',
                      deliveryAddress: pickupPointLabel,
                      paymentMethod: _selectedPaymentLabel(appState),
                      promoCode: _appliedPromoCode ?? '',
                      deliveryFee: deliveryFee,
                      discountAmount: discountAmount,
                    );
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    SpetoToast.show(
                      context,
                      message: _checkoutErrorMessage(error),
                      icon: Icons.error_outline_rounded,
                    );
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  openScreen(context, SpetoScreen.orderTracking);
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: hasCart
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        CompactTimeChip(value: '01', label: 'Saat'),
                        SizedBox(width: 12),
                        Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 12),
                        CompactTimeChip(value: '45', label: 'Dak'),
                        SizedBox(width: 12),
                        Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 12),
                        CompactTimeChip(value: '22', label: 'Sn'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SpetoCard(
                    radius: 26,
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF221513), Color(0xFF121214)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Palette.red.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Palette.red,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Ödeme akışın hazır',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '${appState.cartCount} ürün, gel-al ve özel ödeme görünümü.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Palette.soft),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: CheckoutStepChip(
                                step: '1',
                                label: 'Adres',
                                onTap: () =>
                                    openScreen(context, SpetoScreen.addresses),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: CheckoutStepChip(
                                step: '2',
                                label: 'Gel-Al',
                                active: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CheckoutStepChip(
                                step: '3',
                                label: 'Ödeme',
                                onTap: () => openScreen(
                                  context,
                                  SpetoScreen.paymentMethods,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => openScreen(context, SpetoScreen.addresses),
                    child: SpetoCard(
                      radius: 18,
                      color: Palette.cardWarm,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Palette.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Palette.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Gel-Al Noktası',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$pickupPointLabel • Gel-Al noktası',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Palette.soft),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Palette.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Sipariş Modu',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Palette.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _deliveryModeCard(
                          context,
                          title: 'Gel-Al',
                          subtitle: '12 dk • hazır olduğunda bildir',
                          icon: Icons.store_mall_directory_outlined,
                          selected: true,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Text(
                        'Sepetim',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: appState.clearCart,
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cartItems.map(
                    (SpetoCartItem item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _checkoutItem(context, item, appState),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SpetoCard(
                    radius: 18,
                    color: Palette.cardWarm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kampanya Kodu',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Palette.muted,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Palette.base,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TextField(
                                  controller: _promoController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    hintText: 'Kampanya kodunu gir',
                                    border: InputBorder.none,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Palette.soft),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _applyPromoCode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _appliedPromoCode == null
                                      ? Palette.red
                                      : Palette.green,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _appliedPromoCode == null
                                      ? 'Uygula'
                                      : 'Uygulandı',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SpetoCard(
                    radius: 18,
                    color: Palette.cardWarm,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Palette.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Palette.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Pro Puan Bakiyesi',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Pro puanlar yalnızca etkinlik ve sosyal yaşam biletlerinde kullanılır.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Palette.muted),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              openRootScreen(context, SpetoScreen.proPoints),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Palette.base,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              formatPoints(appState.proPointsBalance),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Palette.orange,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Text(
                        'Ödeme Yöntemi',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Palette.muted),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            openScreen(context, SpetoScreen.paymentMethods),
                        child: const Text('Kart seç'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = 0),
                          child: _paymentMethodCard(
                            context,
                            'Apple Pay',
                            Icons.apple,
                            selected: _selectedPaymentMethod == 0,
                          ),
                        ),
                        ...appState.paymentCards.asMap().entries.map(
                          (MapEntry<int, SpetoPaymentCard> entry) => Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _selectedPaymentMethod = entry.key + 1,
                              ),
                              child: _paymentMethodCard(
                                context,
                                '•••• ${entry.value.last4}',
                                Icons.credit_card_rounded,
                                selected:
                                    _selectedPaymentMethod == entry.key + 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () =>
                              openScreen(context, SpetoScreen.paymentMethods),
                          child: Container(
                            width: 82,
                            decoration: BoxDecoration(
                              color: Palette.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SpetoCard(
                    radius: 18,
                    color: Palette.cardWarm,
                    child: Column(
                      children: <Widget>[
                        _summaryLine(
                          context,
                          label: 'Ara Toplam',
                          value: formatPrice(subtotal),
                        ),
                        if (discountAmount > 0) ...<Widget>[
                          const SizedBox(height: 10),
                          _summaryLine(
                            context,
                            label: 'Kampanya İndirimi',
                            value: '-${formatPrice(discountAmount)}',
                          ),
                        ],
                        const SizedBox(height: 10),
                        _summaryLine(
                          context,
                          label: 'Ödeme Yöntemi',
                          value: _selectedPaymentLabel(appState),
                        ),
                        const SizedBox(height: 10),
                        _summaryLine(
                          context,
                          label: 'Pro Puan',
                          value:
                              '${formatPointValue(earnedProPoints)} Pro Puan',
                        ),
                        const Divider(height: 24, color: Color(0x22FFFFFF)),
                        _summaryLine(
                          context,
                          label: 'Ödeme Toplamı',
                          value: formatPrice(checkoutTotal),
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : SpetoEmptyState(
                icon: Icons.shopping_bag_outlined,
                iconColor: Palette.red,
                title: 'Sepetin şimdilik boş',
                description:
                    'Happy Hour, restoran veya market ekranlarından ürün ekleyerek alışverişe devam edebilirsin.',
                primaryButtonLabel: 'Happy Hour Kampanyalarını Gör',
                primaryButtonIcon: Icons.local_fire_department_rounded,
                onPrimaryButtonTap: () =>
                    openRootScreen(context, SpetoScreen.happyHourList),
                secondaryButtonLabel: 'Ana sayfaya dön',
                onSecondaryButtonTap: () =>
                    openRootScreen(context, SpetoScreen.home),
              ),
      ),
    );
  }

  Widget _deliveryModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SpetoCard(
        radius: 20,
        color: selected ? Palette.cardWarm : Palette.card,
        borderColor: selected
            ? Palette.red.withValues(alpha: 0.24)
            : Colors.white.withValues(alpha: 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? Palette.red.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Palette.red : Palette.soft,
                  ),
                ),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? Palette.red : Palette.faint,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Palette.soft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutItem(
    BuildContext context,
    SpetoCartItem item,
    SpetoAppState appState,
  ) {
    return SpetoCard(
      radius: 20,
      color: Palette.card,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item.image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) =>
                      Container(width: 80, height: 80, color: Palette.cardWarm),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  item.vendor,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Palette.soft),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPrice(item.totalPrice),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Palette.red,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () =>
                    appState.updateCartItemQuantity(item.id, item.quantity + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Palette.cardWarm,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    appState.updateCartItemQuantity(item.id, item.quantity - 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Palette.cardWarm,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => appState.removeFromCart(item.id),
            child: const Icon(Icons.close_rounded, color: Palette.muted),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    BuildContext context, {
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    final TextStyle? style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyLarge?.copyWith(color: Palette.soft);
    return Row(
      children: <Widget>[
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }

  Widget _paymentMethodCard(
    BuildContext context,
    String label,
    IconData icon, {
    bool selected = false,
  }) {
    return Container(
      width: 144,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? Palette.cardWarm : Palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Palette.red : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? Palette.red : Palette.faint,
              size: 16,
            ),
          ),
          const Spacer(),
          Icon(icon, size: 26),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class CheckoutStepChip extends StatelessWidget {
  const CheckoutStepChip({
    super.key,
    required this.step,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String step;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Palette.red.withValues(alpha: 0.14) : Palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? Palette.red.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? Palette.red
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                step,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active ? Colors.white : Palette.soft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactTimeChip extends StatelessWidget {
  const CompactTimeChip({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Palette.cardWarm,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
}
