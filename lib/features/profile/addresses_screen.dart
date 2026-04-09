import 'package:flutter/material.dart';

import '../../core/navigation/screen_enum.dart';
import '../../src/core/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';

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

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      title: 'Adreslerim',
      showBottomNav: true,
      activeNav: NavSection.profile,
      footer: SafeArea(
        top: false,
        child: Container(
          color: Palette.aubergine,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: SpetoPrimaryButton(
            label: 'Yeni Adres Ekle',
            icon: Icons.add_rounded,
            onTap: () => showAddressFormSheet(context),
          ),
        ),
      ),
      background: Palette.aubergine,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: appState.addresses.isEmpty
            ? <Widget>[
                SpetoEmptyState(
                  icon: Icons.location_off_outlined,
                  iconColor: Palette.red,
                  title: 'Henüz kayıtlı adres yok',
                  description:
                      'Yeni bir kayıt ekleyerek favori gel-al noktalarını daha hızlı seçebilirsin.',
                  primaryButtonLabel: 'Adres Ekle',
                  primaryButtonIcon: Icons.add_location_alt_outlined,
                  onPrimaryButtonTap: () => showAddressFormSheet(context),
                ),
              ]
            : appState.addresses
                  .map(
                    (SpetoAddress address) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AddressCard(
                        address: address,
                        onEdit: () =>
                            showAddressFormSheet(context, address: address),
                        onDelete: () async {
                          await appState.deleteAddress(address.id);
                          if (!context.mounted) {
                            return;
                          }
                          SpetoToast.show(
                            context,
                            message: '${address.label} adresi silindi.',
                            icon: Icons.delete_outline_rounded,
                          );
                        },
                        onMakePrimary: address.isPrimary
                            ? null
                            : () async {
                                await appState.setPrimaryAddress(address.id);
                                if (!context.mounted) {
                                  return;
                                }
                                SpetoToast.show(
                                  context,
                                  message:
                                      '${address.label} varsayılan adres oldu.',
                                  icon: Icons.check_circle_outline_rounded,
                                );
                              },
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onMakePrimary,
  });

  final SpetoAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMakePrimary;

  @override
  Widget build(BuildContext context) {
    return SpetoCard(
      radius: 18,
      color: Palette.cardWarm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Palette.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _iconForAddressKey(address.iconKey),
              color: Palette.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      address.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (address.isPrimary) ...<Widget>[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Varsayılan',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Palette.red,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: onEdit,
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Palette.muted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Palette.soft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    if (onMakePrimary case final VoidCallback makePrimary)
                      TextButton(
                        onPressed: makePrimary,
                        child: const Text('Varsayılan Yap'),
                      ),
                    const Spacer(),
                    TextButton(onPressed: onDelete, child: const Text('Sil')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForAddressKey(String key) {
  switch (key) {
    case 'home':
      return Icons.home_outlined;
    case 'work':
      return Icons.work_outline;
    case 'school':
      return Icons.school_outlined;
    case 'favorite':
      return Icons.favorite_outline;
    default:
      return Icons.location_on_outlined;
  }
}
