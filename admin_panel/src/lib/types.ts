export type StorefrontType = 'RESTAURANT' | 'MARKET';
export type VendorApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';
export type OrderStatus =
  | 'CREATED'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'COMPLETED'
  | 'CANCELLED';
export type CampaignKind = 'HAPPY_HOUR' | 'DISCOUNT' | 'CLEARANCE' | 'BUNDLE';
export type CampaignStatus = 'DRAFT' | 'ACTIVE' | 'PAUSED' | 'COMPLETED';
export type UserRole = 'CUSTOMER' | 'ADMIN' | 'SUPPORT' | 'VENDOR';
export type SupportStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';
export type SupportPriority = 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
export type NotificationStatus = 'DRAFT' | 'SCHEDULED' | 'SENT';
export type NotificationAudience =
  | 'ALL_USERS'
  | 'ALL_BUSINESSES'
  | 'ALL_VENDORS'
  | 'CUSTOM';

export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  avatarUrl: string;
  role: 'SUPER_ADMIN';
  lastLoginAt: string | null;
  createdAt: string;
}

export interface AdminTokens {
  accessToken: string;
  accessTokenExpiresAt: string;
}

export interface AdminSession {
  user: AdminUser;
  tokens: AdminTokens;
}

export interface DashboardSummary {
  metrics: {
    grossVolume: number;
    totalBusinesses: number;
    activeBusinesses: number;
    pendingBusinesses: number;
    totalUsers: number;
    activeCampaigns: number;
    openSupportTickets: number;
  };
  recentBusinesses: BusinessListItem[];
  recentOrders: AdminOrder[];
  topCampaigns: AdminCampaign[];
}

export interface BusinessListItem {
  id: string;
  name: string;
  category: string;
  storefrontType: StorefrontType;
  city: string;
  district: string;
  imageUrl: string;
  isActive: boolean;
  approvalStatus: VendorApprovalStatus;
  suspendedReason: string;
  createdAt: string;
  operatorsCount: number;
  productsCount: number;
  ordersCount: number;
  activeCampaigns: number;
  eventsCount: number;
  pendingOrders: number;
}

export interface AdminOrder {
  id: string;
  vendorId: string;
  vendorName: string;
  userId: string;
  userName: string;
  userEmail: string;
  pickupCode: string;
  status: OrderStatus;
  totalAmount: number;
  createdAt: string;
  pickupPointLabel: string;
  itemCount: number;
  items: Array<{
    title: string;
    quantity: number;
  }>;
}

export interface AdminSection {
  id: string;
  key: string;
  label: string;
  displayOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AdminProduct {
  id: string;
  vendorId: string;
  title: string;
  description: string;
  unitPrice: number;
  imageUrl: string;
  category: string;
  sku: string;
  barcode: string;
  externalCode: string;
  displaySubtitle: string;
  displayBadge: string;
  displayOrder: number;
  isFeatured: boolean;
  isVisibleInApp: boolean;
  trackStock: boolean;
  reorderLevel: number;
  isArchived: boolean;
  sectionId: string;
  sectionLabel: string;
  availableQuantity: number;
  reservedQuantity: number;
}

export interface BusinessProductsResponse {
  businessId: string;
  sections: AdminSection[];
  categories: string[];
  products: AdminProduct[];
}

export interface AdminCampaign {
  id: string;
  vendorId: string;
  vendorName: string;
  storefrontType: StorefrontType;
  title: string;
  description: string;
  kind: CampaignKind;
  status: CampaignStatus;
  scheduleLabel: string;
  badgeLabel: string;
  discountPercent: number;
  discountedPrice: number;
  startsAt: string | null;
  endsAt: string | null;
  productIds: string[];
  productTitles: string[];
}

export interface BusinessProfileResponse {
  business: BusinessListItem;
  subtitle: string;
  city: string;
  district: string;
  imageUrl: string;
  announcement: string;
  workingHoursLabel: string;
  pickupPoints: Array<{
    id: string;
    label: string;
    address: string;
    isActive: boolean;
  }>;
  operators: Array<{
    id: string;
    email: string;
    displayName: string;
    phone: string;
    role: UserRole;
    notificationsEnabled: boolean;
    createdAt: string;
  }>;
  bankAccounts: Array<{
    id: string;
    holderName: string;
    bankName: string;
    iban: string;
    isDefault: boolean;
  }>;
}

export interface BusinessOverview {
  business: BusinessListItem;
  operators: BusinessProfileResponse['operators'];
  pickupPoints: BusinessProfileResponse['pickupPoints'];
  metrics: {
    grossRevenue: number;
    totalOrders: number;
    activeOrders: number;
    totalProducts: number;
    activeCampaigns: number;
    lowStockProducts: number;
  };
  recentOrders: AdminOrder[];
  lowStockProducts: AdminProduct[];
  bankAccounts: Array<{
    id: string;
    holderName: string;
    bankName: string;
    iban: string;
    isDefault: boolean;
  }>;
}

export interface AdminAppUser {
  id: string;
  email: string;
  displayName: string;
  phone: string;
  role: UserRole;
  vendorId: string | null;
  notificationsEnabled: boolean;
  isSuspended: boolean;
  suspendedReason: string;
  isBanned: boolean;
  bannedReason: string;
  marketingOptIn: boolean;
  createdAt: string;
  lastLoginAt: string | null;
  ordersCount: number;
}

export interface AdminEvent {
  id: string;
  vendorId: string;
  vendorName: string;
  title: string;
  venue: string;
  district: string;
  imageUrl: string;
  startsAt: string;
  pointsCost: number;
  capacity: number;
  remainingCount: number;
  primaryTag: string;
  secondaryTag: string;
  description: string;
  organizer: string;
  isActive: boolean;
  createdAt: string;
}

export interface FinanceSummary {
  grossVolume: number;
  completedOrders: number;
  totalPayouts: number;
  pendingPayouts: number;
  vendorBalances: Array<{
    vendorId: string;
    vendorName: string;
    availableBalance: number;
    pendingPayouts: number;
    lastPayoutAt: string | null;
  }>;
  recentPayouts: Array<{
    id: string;
    vendorId: string;
    vendorName: string;
    amount: number;
    status: string;
    requestedAt: string;
    completedAt: string | null;
    bankName: string;
    iban: string;
    note: string | null;
  }>;
}

export interface ReportsOverview {
  grossVolume: number;
  averageOrderValue: number;
  completedOrders: number;
  activeBusinesses: number;
  activeCampaigns: number;
  topProducts: Array<{
    productId: string;
    title: string;
    vendorName: string;
    quantity: number;
    revenue: number;
  }>;
  dailyRevenue: Array<{
    date: string;
    total: number;
  }>;
}

export interface AdminNotification {
  id: string;
  title: string;
  body: string;
  audience: NotificationAudience;
  status: NotificationStatus;
  scheduledAt: string | null;
  sentAt: string | null;
  createdAt: string;
  updatedAt: string;
  createdByName: string;
  createdByEmail: string;
  deliveryLogs: AdminNotificationDeliveryLog[];
}

export interface AdminSupportTicket {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  subject: string;
  message: string;
  channel: string;
  status: SupportStatus;
  priority: SupportPriority;
  assignedAdminId: string | null;
  assignedAdminName: string;
  assignedAdminEmail: string;
  createdAt: string;
  updatedAt: string;
}

export interface SupportTicketMessage {
  id: string;
  ticketId: string;
  authorId: string;
  authorName: string;
  authorEmail: string;
  authorRole: UserRole;
  body: string;
  isInternal: boolean;
  createdAt: string;
}

export interface AdminSupportTicketDetail extends AdminSupportTicket {
  messages: SupportTicketMessage[];
}

export interface AdminAuditLog {
  id: string;
  adminUserId: string;
  adminUserName: string;
  adminUserEmail: string;
  action: string;
  entityType: string;
  entityId: string;
  metadata: unknown;
  createdAt: string;
}

export interface AdminNotificationDeliveryLog {
  id: string;
  notificationId: string;
  provider: string;
  status: string;
  target: string | null;
  errorMessage: string | null;
  createdAt: string;
}

export interface PagedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface AdminSettings {
  maintenanceMode: boolean;
  supportEmail: string;
  supportPhone: string;
  announcementBanner: string;
  defaultCommissionRate: number;
  notificationsEnabled: boolean;
}
