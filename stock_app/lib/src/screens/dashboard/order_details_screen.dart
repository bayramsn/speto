import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'order_ui.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final SpetoOpsOrder? order = controller.orders
        .where((SpetoOpsOrder item) => item.id == orderId)
        .cast<SpetoOpsOrder?>()
        .firstOrNull;
    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Text(
              'Sipariş bulunamadı.',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppColors.bodyText,
              ),
            ),
          ),
        ),
      );
    }

    final String fallbackAddress =
        controller.selectedVendor?.pickupPoints.isNotEmpty == true
        ? controller.selectedVendor!.pickupPoints.first.address
        : '';
    final bool isBusy = controller.isBusy('order:${order.id}');
    final SpetoOpsOrderStage? nextStage = nextOrderStage(order);
    final bool showCancelAction = canCancelOrder(order);
    final List<SpetoOpsOrderStage> timelineStages = orderTimelineStages(order);
    final String avatarUrl = order.image.trim().isNotEmpty
        ? order.image.trim()
        : controller.selectedVendor?.image.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Sipariş Detayları',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.27,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: <Widget>[
                  _OrderAvatar(imageUrl: avatarUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          orderPersonLabel(order),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderAddressLabel(
                            order,
                            fallbackAddress: fallbackAddress,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1E3E4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Sipariş Durumu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.27,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: orderDetailStatusBackground(order.opsStatus),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      orderDetailStatusLabel(order.opsStatus),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 0.35,
                        color: orderDetailStatusForeground(order.opsStatus),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Sipariş Detayı',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.27,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < order.items.length;
                      index++
                    ) ...<Widget>[
                      _OrderItemCard(item: order.items[index]),
                      if (index != order.items.length - 1)
                        const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    _SummaryRow(
                      label: 'Ara Toplam',
                      value: orderCurrency(order.totalPrice),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      label: 'Teslimat Ücreti',
                      value: order.deliveryFee > 0
                          ? orderCurrency(order.deliveryFee)
                          : 'Gel - Al (Ücretsiz)',
                      valueColor: order.deliveryFee > 0
                          ? AppColors.bodyText
                          : AppColors.primary,
                    ),
                    if (order.discountAmount > 0) ...<Widget>[
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'İndirim',
                        value: '-${orderCurrency(order.discountAmount)}',
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: const Color(0xFFBBCBBB).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      label: 'Toplam',
                      value: orderCurrency(order.payableTotal),
                      labelStyle: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.onSurface,
                      ),
                      valueStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.33,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sipariş Takibi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.55,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Stack(
                      children: <Widget>[
                        Positioned(
                          left: 9,
                          top: 8,
                          bottom: 8,
                          child: Container(
                            width: 2,
                            color: const Color(0xFFE1E3E4),
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            for (
                              int index = 0;
                              index < timelineStages.length;
                              index++
                            ) ...<Widget>[
                              _TimelineStep(
                                order: order,
                                stage: timelineStages[index],
                                timeLabel: orderPlacedTimeLabel(order),
                              ),
                              if (index != timelineStages.length - 1)
                                const SizedBox(height: 32),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (nextStage != null || showCancelAction) ...<Widget>[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Row(
                  children: <Widget>[
                    if (showCancelAction)
                      Expanded(
                        child: _SecondaryActionButton(
                          label: 'İptal Et',
                          onTap: isBusy
                              ? null
                              : () async {
                                  await controller.updateOrderStatus(
                                    order.id,
                                    SpetoOpsOrderStage.cancelled,
                                  );
                                },
                          isBusy: isBusy,
                        ),
                      ),
                    if (showCancelAction && nextStage != null)
                      const SizedBox(width: 12),
                    if (nextStage != null)
                      Expanded(
                        child: _PrimaryActionButton(
                          label: orderPrimaryActionLabel(order),
                          backgroundColor: orderPrimaryActionBackground(order),
                          icon: orderPrimaryActionIcon(order),
                          onTap: isBusy
                              ? null
                              : () async {
                                  await controller.updateOrderStatus(
                                    order.id,
                                    nextStage,
                                  );
                                },
                          isBusy: isBusy,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderAvatar extends StatelessWidget {
  const _OrderAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFE1E3E4),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const Icon(
              Icons.person_outline_rounded,
              size: 34,
              color: AppColors.slate400,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? _) {
                    return const Icon(
                      Icons.person_outline_rounded,
                      size: 34,
                      color: AppColors.slate400,
                    );
                  },
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final SpetoCartItem item;

  @override
  Widget build(BuildContext context) {
    final List<String> detailLines = item.title
        .split(',')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    final String title = detailLines.isNotEmpty
        ? detailLines.first
        : item.title;
    final String subtitle = detailLines.length > 1
        ? detailLines.skip(1).join('\n')
        : 'Ek bilgi yok';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE1E3E4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: AppColors.bodyText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            orderCurrency(item.totalPrice),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.55,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolvedLabelStyle =
        labelStyle ??
        GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.43,
          color: AppColors.bodyText,
        );
    final TextStyle resolvedValueStyle =
        valueStyle ??
        GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.43,
          color: valueColor ?? AppColors.bodyText,
        );

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: resolvedLabelStyle)),
        const SizedBox(width: 12),
        Text(value, style: resolvedValueStyle),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.order,
    required this.stage,
    required this.timeLabel,
  });

  final SpetoOpsOrder order;
  final SpetoOpsOrderStage stage;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = orderTimelineStepIsCurrent(order, stage);
    final bool isComplete = orderTimelineStepIsComplete(order, stage);
    final Color dotColor = isCurrent || isComplete
        ? AppColors.success
        : const Color(0xFFE1E3E4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 20,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceContainerLow,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                orderTimelineTitle(stage),
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  height: 1.5,
                  color: AppColors.bodyText,
                ),
              ),
              if (isCurrent) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  orderTimelineDescription(stage),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    color: AppColors.bodyText,
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    timeLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.onTap,
    required this.isBusy,
  });

  final String label;
  final Future<void> Function()? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onTap == null ? null : () => onTap!(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onSurface,
                      ),
                    )
                  : const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: AppColors.onSurface,
                    ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.43,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
    required this.isBusy,
  });

  final String label;
  final Color backgroundColor;
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap == null ? null : () => onTap!(),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
