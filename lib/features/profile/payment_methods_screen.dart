import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';

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

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      title: 'Ödeme Yöntemleri',
      actions: <Widget>[
        TextButton(
          onPressed: () => showPaymentCardFormSheet(context),
          child: const Text('Yeni Kart'),
        ),
      ],
      showBottomNav: true,
      activeNav: NavSection.profile,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'KAYITLI KARTLAR',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (appState.paymentCards.isEmpty)
              SpetoEmptyState(
                icon: Icons.credit_card_off_rounded,
                iconColor: Palette.red,
                title: 'Kayıtlı kart bulunmuyor',
                description:
                    'Yeni kart ekleyerek ödeme akışını gerçek verinle tamamlayabilirsin.',
                primaryButtonLabel: 'Kart Ekle',
                primaryButtonIcon: Icons.add_card_rounded,
                onPrimaryButtonTap: () => showPaymentCardFormSheet(context),
              )
            else
              ...appState.paymentCards.map(
                (SpetoPaymentCard card) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _paymentCard(context, appState: appState, card: card),
                ),
              ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => showPaymentCardFormSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.add_rounded),
                    const SizedBox(width: 10),
                    Text(
                      'Yeni Kart Ekle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 90),
            SpetoCard(
              radius: 18,
              color: Colors.transparent,
              borderColor: Palette.red.withValues(alpha: 0.4),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF1E1E1E), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Palette.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Palette.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Güvenli Ödeme',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ödeme bilgileriniz Masterpass altyapısı ile şifrelenerek saklanır.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Palette.soft, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0x22FFFFFF)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.credit_score_rounded,
                        color: Palette.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MASTERPASS İLE GÜVENDE',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: Palette.muted, letterSpacing: 1),
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

  Widget _paymentCard(
    BuildContext context, {
    required SpetoAppState appState,
    required SpetoPaymentCard card,
  }) {
    return Column(
      children: <Widget>[
        FlippablePaymentCard(
          brand: card.brand,
          digits: card.last4,
          expiry: card.expiry,
          holderName: card.holderName,
          defaultCard: card.isDefault,
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            TextButton(
              onPressed: () => showPaymentCardFormSheet(context, card: card),
              child: const Text('Düzenle'),
            ),
            if (!card.isDefault)
              TextButton(
                onPressed: () async {
                  await appState.setDefaultPaymentCard(card.id);
                  if (!context.mounted) {
                    return;
                  }
                  SpetoToast.show(
                    context,
                    message: '•••• ${card.last4} varsayılan kart oldu.',
                    icon: Icons.check_circle_outline_rounded,
                  );
                },
                child: const Text('Varsayılan Yap'),
              ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await appState.deletePaymentCard(card.id);
                if (!context.mounted) {
                  return;
                }
                SpetoToast.show(
                  context,
                  message: '•••• ${card.last4} kartı silindi.',
                  icon: Icons.delete_outline_rounded,
                );
              },
              child: const Text('Sil'),
            ),
          ],
        ),
      ],
    );
  }
}

class FlippablePaymentCard extends StatefulWidget {
  const FlippablePaymentCard({
    super.key,
    required this.brand,
    required this.digits,
    required this.expiry,
    required this.holderName,
    this.defaultCard = false,
  });

  final String brand;
  final String digits;
  final String expiry;
  final String holderName;
  final bool defaultCard;

  @override
  State<FlippablePaymentCard> createState() => FlippablePaymentCardState();
}

class FlippablePaymentCardState extends State<FlippablePaymentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (BuildContext context, Widget? child) {
          final double value = _flipController.value;
          final double angle = value * 3.14159;
          final bool isFront = value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? _buildFront(context)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildBack(context),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.defaultCard
              ? Palette.red.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
        gradient: widget.defaultCard
            ? const LinearGradient(
                colors: <Color>[Color(0xFF1E1E1E), Color(0xFF000000)],
              )
            : null,
        color: widget.defaultCard ? null : Palette.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.brand,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                widget.defaultCard
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: widget.defaultCard ? Palette.red : Colors.white24,
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            '•••• •••• •••• ${widget.digits}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SON KULLANMA',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Palette.muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                widget.expiry,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (widget.defaultCard)
                Text(
                  'Varsayılan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Palette.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: Palette.soft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.holderName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2A1A1A), Color(0xFF0D0D0D)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(child: Container(height: 36, color: Palette.cardWarm)),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CVV',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Kartın arka yüzü',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Palette.muted),
          ),
          const SizedBox(height: 6),
          Text(
            'Dokunarak çevirin',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Palette.soft),
          ),
        ],
      ),
    );
  }
}
