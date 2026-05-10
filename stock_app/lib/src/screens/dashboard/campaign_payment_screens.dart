import 'dart:math' as math;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

const double _campaignPaymentAmountTl = 1000;
const String _campaignPaymentRecipient = 'SepetPro Yazılım ve Teknoloji A.Ş.';
const String _campaignPaymentIban = 'TR62 0006 4000 0000 1234 5678 90';
const String _campaignPaymentBank = 'Türkiye İş Bankası';

class CampaignPaymentIbanScreen extends StatefulWidget {
  const CampaignPaymentIbanScreen({
    super.key,
    this.amountTl = _campaignPaymentAmountTl,
  });

  final double amountTl;

  @override
  State<CampaignPaymentIbanScreen> createState() =>
      _CampaignPaymentIbanScreenState();
}

class _CampaignPaymentIbanScreenState extends State<CampaignPaymentIbanScreen> {
  Future<void> _openReceiptUpload() async {
    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const _CampaignReceiptUploadScreen(),
      ),
    );
    if (completed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _copyIban() async {
    await Clipboard.setData(const ClipboardData(text: _campaignPaymentIban));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('IBAN kopyalandı.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _CampaignFlowHeader(
              title: 'Kampanya Ödemesi',
              titleColor: AppColors.onSurface,
              backgroundColor: AppColors.surface,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Banka Havalesi / EFT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 28 / 20,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kampanyanızı başlatmak için lütfen aşağıda belirtilen\nhesap numarasına ödemenizi gerçekleştirin.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 22.75 / 14,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _CampaignPaymentAmountCard(amountTl: widget.amountTl),
                    const SizedBox(height: 32),
                    _CampaignPaymentDetailsCard(onCopyIban: _copyIban),
                    const SizedBox(height: 32),
                    _CampaignFlowButton(
                      label: 'Dekont Yükle',
                      icon: Icons.upload_file_rounded,
                      rightIcon: null,
                      onPressed: _openReceiptUpload,
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Ödemeniz tamamlandıktan sonra kampanyanız incelenerek\nkısa süre içinde yayına alınacaktır.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 16.5 / 11,
                          color: AppColors.bodyText,
                        ),
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

class _CampaignReceiptUploadScreen extends StatefulWidget {
  const _CampaignReceiptUploadScreen();

  @override
  State<_CampaignReceiptUploadScreen> createState() =>
      _CampaignReceiptUploadScreenState();
}

class _CampaignReceiptUploadScreenState
    extends State<_CampaignReceiptUploadScreen> {
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      _showSnack('Dosya boyutu 5MB sınırını aşıyor.');
      return;
    }

    setState(() => _selectedFile = file);
  }

  Future<void> _submitReceipt() async {
    if (_selectedFile == null) {
      _showSnack('Lütfen önce bir dekont dosyası seçin.');
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }
    _showSnack('Dekont gönderildi. İnceleme süreci başlatıldı.');
    Navigator.of(context).pop(true);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _CampaignFlowHeader(
              title: 'Dekont Yükle',
              titleColor: AppColors.primary,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              blurSigma: 12,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _CampaignInstructionCard(
                      text:
                          'Kampanya ödemenize ait banka\ndekontunu (Görsel veya PDF) buraya\nyükleyerek onay sürecini başlatabilirsiniz.',
                    ),
                    const SizedBox(height: 32),
                    _CampaignUploadDropzone(
                      onTap: _pickFile,
                      selectedFile: _selectedFile,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Yüklenen Dosya',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CampaignUploadedFileCard(selectedFile: _selectedFile),
                    const SizedBox(height: 39.875),
                    _CampaignFlowButton(
                      label: 'Dekontu Gönder ve Tamamla',
                      icon: null,
                      rightIcon: Icons.check_circle_outline_rounded,
                      onPressed: _isSubmitting ? null : _submitReceipt,
                      isLoading: _isSubmitting,
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

class _CampaignFlowHeader extends StatelessWidget {
  const _CampaignFlowHeader({
    required this.title,
    required this.titleColor,
    required this.backgroundColor,
    required this.onBack,
    this.blurSigma = 0,
    this.shadowColor,
  });

  final String title;
  final Color titleColor;
  final Color backgroundColor;
  final double blurSigma;
  final Color? shadowColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: shadowColor == null
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: shadowColor!,
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ],
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 30.4,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 18,
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 28 / 18,
                letterSpacing: -0.45,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(width: 30.4, height: 40),
        ],
      ),
    );

    if (blurSigma <= 0) {
      return child;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: child,
      ),
    );
  }
}

class _CampaignPaymentAmountCard extends StatelessWidget {
  const _CampaignPaymentAmountCard({required this.amountTl});

  final double amountTl;

  @override
  Widget build(BuildContext context) {
    final String amountLabel = _formatCampaignPaymentAmount(amountTl);
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            'ÖDENECEK TUTAR',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 16.5 / 11,
              letterSpacing: 1.1,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: amountLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 36 / 30,
                color: AppColors.primary,
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: ' TL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignPaymentDetailsCard extends StatelessWidget {
  const _CampaignPaymentDetailsCard({required this.onCopyIban});

  final VoidCallback onCopyIban;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEEEF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Sepet Pro İşletme Hesabı',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    _campaignPaymentBank,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CampaignPaymentLabel(label: 'ALICI ADI'),
                const SizedBox(height: 4),
                Text(
                  _campaignPaymentRecipient,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE1E3E4),
                ),
                const SizedBox(height: 16),
                _CampaignPaymentLabel(label: 'IBAN'),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'TR62 0006 4000 0000 1234\n5678 90',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 24 / 16,
                          letterSpacing: 0.4,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      splashRadius: 18,
                      onPressed: onCopyIban,
                      icon: const Icon(
                        Icons.content_copy_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _CampaignImportantNote(),
        ],
      ),
    );
  }
}

class _CampaignPaymentLabel extends StatelessWidget {
  const _CampaignPaymentLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16.5 / 11,
        letterSpacing: 0.55,
        color: AppColors.bodyText,
      ),
    );
  }
}

class _CampaignImportantNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.success, width: 4),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 19.5 / 13,
            color: AppColors.bodyText,
          ),
          children: <InlineSpan>[
            TextSpan(
              text: 'Önemli:',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 19.5 / 13,
                color: AppColors.onSurface,
              ),
            ),
            const TextSpan(
              text:
                  " Açıklama kısmına işletme adınızı\nveya kampanya ID'nizi yazmayı\nunutmayınız.",
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignInstructionCard extends StatelessWidget {
  const _CampaignInstructionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22.875, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.success, width: 4),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 24.38 / 15,
          color: AppColors.bodyText,
        ),
      ),
    );
  }
}

String _formatCampaignPaymentAmount(double value) {
  final String rounded = value.toStringAsFixed(0);
  return rounded.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match match) => '.',
  );
}

class _CampaignUploadDropzone extends StatelessWidget {
  const _CampaignUploadDropzone({
    required this.onTap,
    required this.selectedFile,
  });

  final VoidCallback onTap;
  final PlatformFile? selectedFile;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedRoundedRectPainter(),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 267,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEEEF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      selectedFile == null
                          ? Icons.cloud_upload_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 28,
                      color: AppColors.bodyText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dosya Seçin veya\nSürükleyin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 27 / 18,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedFile == null
                        ? 'Max 5MB, JPG, PNG veya PDF'
                        : '${selectedFile!.name} seçildi',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 21 / 14,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignUploadedFileCard extends StatelessWidget {
  const _CampaignUploadedFileCard({required this.selectedFile});

  final PlatformFile? selectedFile;

  @override
  Widget build(BuildContext context) {
    final String label = selectedFile?.name ?? 'Henüz dosya yüklenmedi';
    return Opacity(
      opacity: selectedFile == null ? 0.7 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.bodyText,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 22.5 / 15,
                  color: AppColors.bodyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignFlowButton extends StatelessWidget {
  const _CampaignFlowButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.rightIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? rightIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.95, -1),
          end: Alignment(0.95, 1),
          colors: <Color>[AppColors.primary, AppColors.success],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 56,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 24 / 16,
                            color: Colors.white,
                          ),
                        ),
                        if (rightIcon != null) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(rightIcon, size: 18, color: Colors.white),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x99BBCBBB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(12),
        ),
      );

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = math.min(distance + 8, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
