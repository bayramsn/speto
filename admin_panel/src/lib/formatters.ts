import type {
  CampaignStatus,
  NotificationStatus,
  OrderStatus,
  SupportStatus,
  VendorApprovalStatus,
} from './types';

export function formatCurrency(value: number) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatDate(value: string | null) {
  if (!value) {
    return '-';
  }
  return new Intl.DateTimeFormat('tr-TR', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

export function orderStatusLabel(status: OrderStatus) {
  switch (status) {
    case 'CREATED':
      return 'Yeni';
    case 'ACCEPTED':
      return 'Onaylandı';
    case 'PREPARING':
      return 'Hazırlanıyor';
    case 'READY':
      return 'Hazır';
    case 'COMPLETED':
      return 'Tamamlandı';
    case 'CANCELLED':
      return 'İptal';
  }
}

export function orderStatusTone(status: OrderStatus) {
  switch (status) {
    case 'COMPLETED':
      return 'success' as const;
    case 'CANCELLED':
      return 'danger' as const;
    case 'READY':
      return 'info' as const;
    case 'PREPARING':
    case 'ACCEPTED':
      return 'warning' as const;
    default:
      return 'default' as const;
  }
}

export function approvalLabel(status: VendorApprovalStatus) {
  switch (status) {
    case 'APPROVED':
      return 'Onaylı';
    case 'PENDING':
      return 'Bekliyor';
    case 'REJECTED':
      return 'Reddedildi';
    case 'SUSPENDED':
      return 'Askıda';
  }
}

export function approvalTone(status: VendorApprovalStatus) {
  switch (status) {
    case 'APPROVED':
      return 'success' as const;
    case 'PENDING':
      return 'warning' as const;
    case 'REJECTED':
    case 'SUSPENDED':
      return 'danger' as const;
  }
}

export function campaignStatusLabel(status: CampaignStatus) {
  switch (status) {
    case 'ACTIVE':
      return 'Aktif';
    case 'PAUSED':
      return 'Duraklatıldı';
    case 'COMPLETED':
      return 'Tamamlandı';
    case 'DRAFT':
      return 'Taslak';
  }
}

export function supportStatusLabel(status: SupportStatus) {
  switch (status) {
    case 'OPEN':
      return 'Açık';
    case 'IN_PROGRESS':
      return 'İşlemde';
    case 'RESOLVED':
      return 'Çözüldü';
    case 'CLOSED':
      return 'Kapalı';
  }
}

export function notificationStatusLabel(status: NotificationStatus) {
  switch (status) {
    case 'DRAFT':
      return 'Taslak';
    case 'SCHEDULED':
      return 'Planlandı';
    case 'SENT':
      return 'Gönderildi';
  }
}
