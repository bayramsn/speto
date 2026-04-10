import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class EmailLinkCompleteScreen extends StatefulWidget {
  const EmailLinkCompleteScreen({super.key, this.initialLink});

  final String? initialLink;

  @override
  State<EmailLinkCompleteScreen> createState() => _EmailLinkCompleteScreenState();
}

class _EmailLinkCompleteScreenState extends State<EmailLinkCompleteScreen> {
  late final TextEditingController _linkController = TextEditingController(
    text: widget.initialLink ?? '',
  );
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String initialLink = widget.initialLink?.trim() ?? '';
      if (initialLink.isNotEmpty) {
        _submit(initialLink);
      }
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit([String? overrideLink]) async {
    if (_submitting) {
      return;
    }
    final String link = (overrideLink ?? _linkController.text).trim();
    if (link.isEmpty) {
      SpetoToast.show(
        context,
        message: 'Mail içindeki linki yapıştırman gerekiyor.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final SpetoEmailLinkCompletionFlow? flow = await SpetoAppScope.of(
        context,
      ).completeFirebaseEmailLink(link);
      if (!mounted) {
        return;
      }
      if (flow == null) {
        SpetoToast.show(
          context,
          message: 'Link doğrulanamadı. Linkin tamamını kopyalayıp tekrar dene.',
          icon: Icons.info_outline_rounded,
        );
        return;
      }
      if (flow == SpetoEmailLinkCompletionFlow.registration) {
        openRootScreen(context, SpetoScreen.home);
        return;
      }
      openScreen(context, SpetoScreen.resetPassword);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpetoScreenScaffold(
      title: 'E-posta Linkini Tamamla',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SpetoCard(
              radius: 24,
              color: Palette.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Linki yapıştır',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Maildeki doğrulama linkini komple kopyalayıp aşağıdaki alana yapıştır. Uygulama linki doğrulayıp akışı tamamlayacak.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Palette.soft,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _linkController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Firebase e-posta linki',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 64),
                        child: Icon(Icons.link_rounded),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SpetoPrimaryButton(
              label: _submitting ? 'DOĞRULANIYOR...' : 'LİNKİ DOĞRULA',
              icon: Icons.verified_rounded,
              onTap: () {
                if (_submitting) {
                  return;
                }
                _submit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
