import 'package:flutter/material.dart';

import '../../src/core/models.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';

Future<void> showSupportComposerSheet(
  BuildContext context, {
  String initialSubject = '',
  String initialChannel = 'Canlı Destek',
}) async {
  final BuildContext rootContext = context;
  final SpetoAppState appState = SpetoAppScope.of(context);
  final TextEditingController subjectController = TextEditingController(
    text: initialSubject,
  );
  final TextEditingController messageController = TextEditingController();
  String channel = initialChannel;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return FractionallySizedBox(
            heightFactor: 0.8,
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
                          'Destek Talebi Oluştur',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 18),
                        LabeledField(
                          label: 'Konu',
                          icon: Icons.support_agent_rounded,
                          controller: subjectController,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'KANAL',
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
                              <String>[
                                    'Canlı Destek',
                                    'E-posta Desteği',
                                    'Sipariş İncelemesi',
                                  ]
                                  .map(
                                    (String item) => TabChip(
                                      label: item,
                                      active: item == channel,
                                      onTap: () =>
                                          setModalState(() => channel = item),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'MESAJ',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Palette.muted,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Palette.cardWarm,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            controller: messageController,
                            minLines: 4,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: 'Sorununuzu detaylı biçimde yazın...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SpetoPrimaryButton(
                          label: 'Talebi Gönder',
                          icon: Icons.send_rounded,
                          onTap: () async {
                            final String subject = subjectController.text
                                .trim();
                            final String message = messageController.text
                                .trim();
                            if (subject.isEmpty || message.isEmpty) {
                              SpetoToast.show(
                                rootContext,
                                message: 'Konu ve mesaj alanları gerekli.',
                                icon: Icons.info_outline_rounded,
                              );
                              return;
                            }
                            await appState.createSupportTicket(
                              subject: subject,
                              message: message,
                              channel: channel,
                            );
                            if (!rootContext.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            SpetoToast.show(
                              rootContext,
                              message:
                                  '$subject için destek talebi oluşturuldu.',
                              icon: Icons.support_agent_rounded,
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
  subjectController.dispose();
  messageController.dispose();
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final List<Map<String, Object>> quickTopics = <Map<String, Object>>[
      <String, Object>{
        'label': 'Sipariş',
        'description': 'Gel-al ve sipariş akışı',
        'icon': Icons.receipt_long_rounded,
        'screen': SpetoScreen.orderHistory,
      },
      <String, Object>{
        'label': 'Ödeme',
        'description': 'Kart ve ödeme adımları',
        'icon': Icons.credit_card_rounded,
        'screen': SpetoScreen.paymentMethods,
      },
      <String, Object>{
        'label': 'İptal & İade',
        'description': 'İptal ve iade süreci',
        'icon': Icons.refresh_rounded,
        'screen': SpetoScreen.orderReceipt,
      },
      <String, Object>{
        'label': 'Hesap',
        'description': 'Profil ve hesap desteği',
        'icon': Icons.person_outline_rounded,
        'screen': SpetoScreen.accountSettings,
      },
    ];
    final List<Map<String, String>> faqs = <Map<String, String>>[
      <String, String>{
        'title': 'Siparişim neden gecikti?',
        'body':
            'Yoğunluk, hava durumu veya mağaza tarafındaki hazırlık süresi nedeniyle gecikme yaşanabilir. Canlı destekten anlık durum alabilirsiniz.',
      },
      <String, String>{
        'title': 'Kartımı nasıl güncellerim?',
        'body':
            'Ödeme Yöntemleri ekranından yeni kart ekleyebilir, varsayılan kartı değiştirebilir veya mevcut kartlarınızı silebilirsiniz.',
      },
      <String, String>{
        'title': 'İptal ve iade süreci nasıl çalışır?',
        'body':
            'Sipariş hazırlanmadan önce iptal talebi açılabilir. Hazırlanan siparişlerde mağaza onayı gerekir. Duruma göre cüzdan veya karta iade yapılır.',
      },
    ];
    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, String>> filteredFaqs = faqs
        .where(
          (Map<String, String> faq) =>
              query.isEmpty ||
              faq['title']!.toLowerCase().contains(query) ||
              faq['body']!.toLowerCase().contains(query),
        )
        .toList();
    final List<SpetoSupportTicket> filteredTickets = appState.supportTickets
        .where(
          (SpetoSupportTicket ticket) =>
              query.isEmpty ||
              ticket.subject.toLowerCase().contains(query) ||
              ticket.message.toLowerCase().contains(query) ||
              ticket.channel.toLowerCase().contains(query),
        )
        .toList();
    return SpetoScreenScaffold(
      title: 'Yardım Merkezi',
      background: Palette.aubergine,
      showBottomNav: true,
      activeNav: NavSection.profile,
      footer: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(220, 0, 17, 16),
          child: SpetoPrimaryButton(
            label: 'Canlı Destek',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => showSupportComposerSheet(
              context,
              initialSubject: 'Canlı Destek Talebi',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Palette.cardWarm,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.search_rounded, color: Palette.soft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Bir sorununuz mu var? Arayın...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Palette.soft,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Popüler Konular',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickTopics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.55,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, int index) {
                final Map<String, Object> topic = quickTopics[index];
                final String label = topic['label']! as String;
                final String description = topic['description']! as String;
                final SpetoScreen screen = topic['screen']! as SpetoScreen;
                return GestureDetector(
                  onTap: () => openScreen(context, screen),
                  child: SpetoCard(
                    radius: 16,
                    color: Palette.cardWarm,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Palette.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                topic['icon']! as IconData,
                                color: Palette.red,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Palette.soft,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Destek Taleplerim',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (filteredTickets.isEmpty)
              SpetoCard(
                radius: 18,
                color: Palette.cardWarm,
                child: Text(
                  query.isEmpty
                      ? 'Henüz kayıtlı destek talebiniz yok. Canlı destek veya Bize Yaz ile yeni talep oluşturabilirsiniz.'
                      : 'Arama sonucunda destek talebi bulunamadı.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Palette.soft,
                    height: 1.6,
                  ),
                ),
              )
            else
              ...filteredTickets.map(
                (SpetoSupportTicket ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SpetoCard(
                    radius: 18,
                    color: Palette.cardWarm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                ticket.subject,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                ticket.status,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Palette.red,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${ticket.channel} • ${ticket.createdAtLabel}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Palette.muted),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ticket.message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Palette.soft, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 28),
            Text(
              'Sıkça Sorulanlar',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (filteredFaqs.isEmpty)
              SpetoCard(
                radius: 18,
                color: Palette.cardWarm,
                child: Text(
                  'Arama sonucunda eşleşen soru bulunamadı.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
                ),
              )
            else
              ...filteredFaqs.asMap().entries.map(
                (MapEntry<int, Map<String, String>> entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == filteredFaqs.length - 1 ? 0 : 12,
                  ),
                  child: FaqTile(
                    title: entry.value['title']!,
                    body: entry.value['body']!,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => showSupportComposerSheet(
                context,
                initialSubject: 'Genel Destek',
              ),
              child: SpetoCard(
                radius: 20,
                color: Palette.cardWarm,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Bizimle İletişime Geç',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sorununu doğrudan destek ekibine aktar. Ekran görüntüsü ve sipariş numarası ekleyebilirsin.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Palette.soft, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.red,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Bize Yaz',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
