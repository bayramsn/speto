import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../theme/app_colors.dart';

const Color orderBlue = Color(0xFF3B82F6);
const Color orderBlueSoft = Color(0xFFDBEAFE);
const Color orderBlueText = Color(0xFF2563EB);
const Color orderAmber = Color(0xFFF59E0B);
const Color orderAmberSoft = Color(0xFFFFFBEB);
const Color orderAmberText = Color(0xFFD97706);
const Color orderOrangeText = Color(0xFFEA580C);
const Color orderCancelRed = Color(0xFFE74C3C);
const Color orderDetailCreatedBackground = Color(0xFF6BFE9C);
const Color orderDetailCreatedForeground = Color(0xFF005228);

const List<SpetoOpsOrderStage> _orderTimelineStages = <SpetoOpsOrderStage>[
  SpetoOpsOrderStage.created,
  SpetoOpsOrderStage.accepted,
  SpetoOpsOrderStage.preparing,
  SpetoOpsOrderStage.ready,
  SpetoOpsOrderStage.completed,
];

List<SpetoOpsOrderStage> orderTimelineStages(SpetoOpsOrder order) {
  if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
    return <SpetoOpsOrderStage>[
      ..._orderTimelineStages,
      SpetoOpsOrderStage.cancelled,
    ];
  }
  return _orderTimelineStages;
}

DateTime? parseOrderPlacedAt(SpetoOpsOrder order) {
  final Match? match = RegExp(
    r'(\d{2})\.(\d{2})\.(\d{4})\s*•\s*(\d{2}):(\d{2})',
  ).firstMatch(order.placedAtLabel);
  if (match == null) {
    return null;
  }
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

String orderCurrency(double value) {
  return '₺${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String orderTitle(SpetoOpsOrder order) {
  final String code = order.pickupCode.trim();
  if (code.isNotEmpty) {
    return 'Sipariş #${code.toUpperCase()}';
  }
  return 'Sipariş #${order.id.split('-').last.toUpperCase()}';
}

String orderItemsPreview(SpetoOpsOrder order) {
  if (order.items.isEmpty) {
    return 'Sipariş içeriği bekleniyor';
  }
  return order.items
      .map((SpetoCartItem item) => item.title.trim())
      .where((String title) => title.isNotEmpty)
      .join(' + ');
}

String orderPersonLabel(SpetoOpsOrder order) {
  final String vendor = order.vendor.trim();
  if (vendor.isNotEmpty) {
    return vendor;
  }
  final String paymentMethod = order.paymentMethod.trim();
  if (paymentMethod.isNotEmpty) {
    return paymentMethod;
  }
  final String deliveryMode = order.deliveryMode.trim();
  if (deliveryMode.isNotEmpty) {
    return deliveryMode;
  }
  return 'Müşteri bilgisi yok';
}

String orderMetaLine(SpetoOpsOrder order) {
  final String code = order.pickupCode.trim();
  if (code.isNotEmpty) {
    return '${order.deliveryMode} • ${code.toUpperCase()}';
  }
  return '${order.deliveryMode} • ${order.paymentMethod}';
}

String orderAddressLabel(SpetoOpsOrder order, {String? fallbackAddress}) {
  final String address = order.deliveryAddress.trim();
  if (address.isNotEmpty) {
    return address;
  }
  final String fallback = fallbackAddress?.trim() ?? '';
  if (fallback.isNotEmpty) {
    return fallback;
  }
  return 'Adres bilgisi paylaşılmadı';
}

String orderRelativeTimeLabel(SpetoOpsOrder order) {
  final DateTime? placedAt = parseOrderPlacedAt(order);
  if (placedAt != null) {
    final Duration difference = DateTime.now().difference(placedAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes.clamp(1, 59)} dk önce';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    }
    return '${difference.inDays} gün önce';
  }
  return order.etaLabel;
}

String orderPlacedTimeLabel(SpetoOpsOrder order) {
  final DateTime? placedAt = parseOrderPlacedAt(order);
  if (placedAt == null) {
    return order.etaLabel;
  }
  final String hour = placedAt.hour.toString().padLeft(2, '0');
  final String minute = placedAt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool isPreparingOrder(SpetoOpsOrder order) {
  return order.opsStatus == SpetoOpsOrderStage.accepted ||
      order.opsStatus == SpetoOpsOrderStage.preparing;
}

bool isTerminalOrder(SpetoOpsOrder order) {
  return order.opsStatus == SpetoOpsOrderStage.completed ||
      order.opsStatus == SpetoOpsOrderStage.cancelled;
}

bool canCancelOrder(SpetoOpsOrder order) {
  return !isTerminalOrder(order);
}

int orderStageRank(SpetoOpsOrder order) {
  return switch (order.opsStatus) {
    SpetoOpsOrderStage.created => 0,
    SpetoOpsOrderStage.accepted || SpetoOpsOrderStage.preparing => 1,
    SpetoOpsOrderStage.ready => 2,
    SpetoOpsOrderStage.completed => 3,
    SpetoOpsOrderStage.cancelled => 4,
  };
}

SpetoOpsOrderStage? nextOrderStage(SpetoOpsOrder order) {
  return switch (order.opsStatus) {
    SpetoOpsOrderStage.created => SpetoOpsOrderStage.accepted,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => SpetoOpsOrderStage.ready,
    SpetoOpsOrderStage.ready => SpetoOpsOrderStage.completed,
    SpetoOpsOrderStage.completed || SpetoOpsOrderStage.cancelled => null,
  };
}

String orderListStatusLabel(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'Yeni',
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => 'Hazırlanıyor',
    SpetoOpsOrderStage.ready => 'Hazır',
    SpetoOpsOrderStage.completed => 'Tamamlandı',
    SpetoOpsOrderStage.cancelled => 'İptal Edildi',
  };
}

String orderDetailStatusLabel(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'Yeni Sipariş',
    SpetoOpsOrderStage.accepted => 'Onaylandı',
    SpetoOpsOrderStage.preparing => 'Hazırlanıyor',
    SpetoOpsOrderStage.ready => 'Hazır',
    SpetoOpsOrderStage.completed => 'Tamamlandı',
    SpetoOpsOrderStage.cancelled => 'İptal Edildi',
  };
}

String orderPrimaryActionLabel(SpetoOpsOrder order) {
  return switch (order.opsStatus) {
    SpetoOpsOrderStage.created => 'Sipariş Onayla',
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => 'Hazır Olarak İşaretle',
    SpetoOpsOrderStage.ready => 'Teslim İçin Kod',
    SpetoOpsOrderStage.completed => 'Tamamlandı',
    SpetoOpsOrderStage.cancelled => 'İptal Edildi',
  };
}

IconData orderPrimaryActionIcon(SpetoOpsOrder order) {
  return switch (order.opsStatus) {
    SpetoOpsOrderStage.created => Icons.check_circle_outline_rounded,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => Icons.check_rounded,
    SpetoOpsOrderStage.ready => Icons.qr_code_2_rounded,
    SpetoOpsOrderStage.completed => Icons.check_circle_rounded,
    SpetoOpsOrderStage.cancelled => Icons.block_rounded,
  };
}

Color orderPrimaryActionBackground(SpetoOpsOrder order) {
  return switch (order.opsStatus) {
    SpetoOpsOrderStage.created => AppColors.success,
    SpetoOpsOrderStage.accepted || SpetoOpsOrderStage.preparing => orderBlue,
    SpetoOpsOrderStage.ready => orderAmber,
    SpetoOpsOrderStage.completed ||
    SpetoOpsOrderStage.cancelled => AppColors.slate200,
  };
}

Color orderListStatusBackground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => AppColors.orange50,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => orderBlueSoft,
    SpetoOpsOrderStage.ready => orderAmberSoft,
    SpetoOpsOrderStage.completed => AppColors.emerald50,
    SpetoOpsOrderStage.cancelled => AppColors.red50,
  };
}

Color orderListStatusForeground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => orderOrangeText,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => orderBlueText,
    SpetoOpsOrderStage.ready => orderAmberText,
    SpetoOpsOrderStage.completed => AppColors.activeNavItemText,
    SpetoOpsOrderStage.cancelled => AppColors.red500,
  };
}

Color orderDetailStatusBackground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => orderDetailCreatedBackground,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => orderBlueSoft,
    SpetoOpsOrderStage.ready => orderAmberSoft,
    SpetoOpsOrderStage.completed => AppColors.emerald50,
    SpetoOpsOrderStage.cancelled => AppColors.red50,
  };
}

Color orderDetailStatusForeground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => orderDetailCreatedForeground,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => orderBlueText,
    SpetoOpsOrderStage.ready => orderAmberText,
    SpetoOpsOrderStage.completed => AppColors.primary,
    SpetoOpsOrderStage.cancelled => AppColors.red500,
  };
}

Color orderIconBackground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => AppColors.orange50,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => AppColors.emerald50,
    SpetoOpsOrderStage.ready => orderAmberSoft,
    SpetoOpsOrderStage.completed => AppColors.slate100,
    SpetoOpsOrderStage.cancelled => AppColors.red50,
  };
}

Color orderIconForeground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => orderOrangeText,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => AppColors.success,
    SpetoOpsOrderStage.ready => orderAmberText,
    SpetoOpsOrderStage.completed => AppColors.slate400,
    SpetoOpsOrderStage.cancelled => AppColors.red500,
  };
}

IconData orderLeadingIcon(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => Icons.shopping_bag_outlined,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => Icons.chat_bubble_outline_rounded,
    SpetoOpsOrderStage.ready => Icons.shopping_bag_outlined,
    SpetoOpsOrderStage.completed => Icons.check_rounded,
    SpetoOpsOrderStage.cancelled => Icons.close_rounded,
  };
}

double orderCardOpacity(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.completed || SpetoOpsOrderStage.cancelled => 0.75,
    _ => 1,
  };
}

int _orderTimelineCurrentIndex(SpetoOpsOrder order) {
  return switch (order.opsStatus) {
    SpetoOpsOrderStage.created => 0,
    SpetoOpsOrderStage.accepted => 1,
    SpetoOpsOrderStage.preparing => 2,
    SpetoOpsOrderStage.ready => 3,
    SpetoOpsOrderStage.completed => 4,
    SpetoOpsOrderStage.cancelled => orderTimelineStages(order).length - 1,
  };
}

bool orderTimelineStepIsCurrent(SpetoOpsOrder order, SpetoOpsOrderStage stage) {
  final List<SpetoOpsOrderStage> stages = orderTimelineStages(order);
  return stages.indexOf(stage) == _orderTimelineCurrentIndex(order);
}

bool orderTimelineStepIsComplete(
  SpetoOpsOrder order,
  SpetoOpsOrderStage stage,
) {
  if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
    return stage == SpetoOpsOrderStage.created;
  }
  final List<SpetoOpsOrderStage> stages = orderTimelineStages(order);
  return stages.indexOf(stage) < _orderTimelineCurrentIndex(order);
}

String orderTimelineTitle(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'Yeni Sipariş',
    SpetoOpsOrderStage.accepted => 'Onaylandı',
    SpetoOpsOrderStage.preparing => 'Hazırlanıyor',
    SpetoOpsOrderStage.ready => 'Hazır',
    SpetoOpsOrderStage.completed => 'Tamamlandı',
    SpetoOpsOrderStage.cancelled => 'İptal',
  };
}

String orderTimelineDescription(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'Sipariş sisteme düştü, onayınız bekleniyor.',
    SpetoOpsOrderStage.accepted =>
      'Sipariş onaylandı ve hazırlık hattına aktarıldı.',
    SpetoOpsOrderStage.preparing => 'Sipariş hazırlanıyor.',
    SpetoOpsOrderStage.ready => 'Sipariş teslim için hazırlandı.',
    SpetoOpsOrderStage.completed => 'Sipariş teslim edilerek tamamlandı.',
    SpetoOpsOrderStage.cancelled => 'Sipariş iptal edildi.',
  };
}
