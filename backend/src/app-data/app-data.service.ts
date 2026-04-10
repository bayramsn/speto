import {
  BadRequestException,
  ForbiddenException,
  InternalServerErrorException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  ContentBlockType as PrismaContentBlockType,
  FulfillmentMode as PrismaFulfillmentMode,
  IntegrationHealth as PrismaIntegrationHealth,
  IntegrationType as PrismaIntegrationType,
  InventoryMovementType as PrismaInventoryMovementType,
  OrderStatus as PrismaOrderStatus,
  Prisma,
  Role as PrismaRole,
  StorefrontType as PrismaStorefrontType,
  SupportStatus as PrismaSupportStatus,
  SyncRunStatus as PrismaSyncRunStatus,
} from '@prisma/client';
import { createHash, randomInt, randomUUID } from 'node:crypto';

import { RegisterDto } from '../auth/dto/register.dto';
import { FulfillmentMode } from '../common/enums/fulfillment-mode.enum';
import { CreateCheckoutSessionDto } from '../orders/dto/create-checkout-session.dto';
import { PrismaService } from '../prisma/prisma.service';
import { RequestContextService } from './request-context.service';
import { CreateAddressDto } from '../profile/dto/create-address.dto';
import { CreatePaymentMethodDto } from '../profile/dto/create-payment-method.dto';
import { UpdateProfileDto } from '../profile/dto/update-profile.dto';
import { CreateSupportTicketDto } from '../support/dto/create-support-ticket.dto';
import { RedeemTicketDto } from '../wallet/dto/redeem-ticket.dto';
import { loadCatalogManifest } from '../catalog/catalog-manifest';

export type UserRole = 'CUSTOMER' | 'ADMIN' | 'VENDOR';
export type OrderStatus = 'active' | 'completed' | 'cancelled';
export type OpsOrderStatus =
  | 'CREATED'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'COMPLETED'
  | 'CANCELLED';
export type InventoryMovementType =
  | 'SALE'
  | 'MANUAL_ADJUSTMENT'
  | 'RESTOCK'
  | 'POS_SYNC'
  | 'RESERVATION'
  | 'RELEASE';
export type IntegrationType = 'POS' | 'ERP';
export type IntegrationHealth = 'healthy' | 'warning' | 'failed';
export type SyncRunStatus = 'idle' | 'running' | 'success' | 'failed';

export interface AppUser {
  id: string;
  email: string;
  displayName: string;
  phone: string;
  studentVerified: boolean;
  notificationsEnabled: boolean;
  avatarUrl: string;
  role: UserRole;
  vendorScopes: string[];
}

export interface Address {
  id: string;
  label: string;
  address: string;
  iconKey: string;
  isPrimary: boolean;
}

export interface PaymentMethod {
  id: string;
  brand: string;
  last4: string;
  expiry: string;
  holderName: string;
  isDefault: boolean;
  token: string;
}

export interface OrderItem {
  id: string;
  productId: string;
  title: string;
  vendor: string;
  image: string;
  unitPrice: number;
  quantity: number;
}

export interface Order {
  id: string;
  vendorId: string;
  vendor: string;
  image: string;
  items: OrderItem[];
  placedAtLabel: string;
  etaLabel: string;
  status: OrderStatus;
  opsStatus: OpsOrderStatus;
  actionLabel: string;
  pickupCode: string;
  rewardPoints: number;
  deliveryMode: string;
  deliveryAddress: string;
  pickupPointId: string;
  paymentMethod: string;
  promoCode: string;
  deliveryFee: number;
  discountAmount: number;
}

export interface EventTicket {
  id: string;
  title: string;
  venue: string;
  dateLabel: string;
  timeLabel: string;
  zone: string;
  seat: string;
  gate: string;
  code: string;
  image: string;
  pointsCost: number;
}

export interface SupportTicket {
  id: string;
  subject: string;
  message: string;
  channel: string;
  createdAtLabel: string;
  status: string;
}

interface VendorRecord {
  id: string;
  name: string;
  slug: string;
  category: string;
  pickupPointId: string;
  pickupPointLabel: string;
}

interface ProductRecord {
  id: string;
  vendorId: string;
  vendorName: string;
  title: string;
  description: string;
  imageUrl: string;
  category: string;
  unitPrice: number;
  sku: string;
  barcode: string;
  externalCode: string;
  locationId: string;
  locationLabel: string;
  trackStock: boolean;
  reorderLevel: number;
  isArchived: boolean;
  onHand: number;
  reserved: number;
}

interface InventoryMovement {
  id: string;
  productId: string;
  productTitle: string;
  vendorId: string;
  vendorName: string;
  type: InventoryMovementType;
  quantityDelta: number;
  previousOnHand: number;
  nextOnHand: number;
  previousReserved: number;
  nextReserved: number;
  createdAtLabel: string;
  note: string;
  orderId: string;
}

interface IntegrationSyncRun {
  connectionId: string;
  status: SyncRunStatus;
  startedAtLabel: string;
  completedAtLabel: string;
  processedCount: number;
  errorMessage: string;
}

interface IntegrationConnection {
  id: string;
  vendorId: string;
  vendorName: string;
  name: string;
  provider: string;
  type: IntegrationType;
  baseUrl: string;
  locationId: string;
  health: IntegrationHealth;
  lastSync: IntegrationSyncRun;
  skuMappings: Record<string, string>;
}

interface EventCatalogItem {
  id: string;
  title: string;
  venue: string;
  district: string;
  dateLabel: string;
  timeLabel: string;
  image: string;
  pointsCost: number;
}

interface RestaurantCatalogItem {
  id: string;
  vendorId: string;
  title: string;
  image: string;
  cuisine: string;
  etaMin: number;
  etaMax: number;
  ratingValue: number;
  promo: string;
  studentFriendly: boolean;
  stockStatus?: StockStatusPayload;
}

interface StockStatusPayload {
  isInStock: boolean;
  availableQuantity: number;
  lowStock: boolean;
  canPurchase: boolean;
}

interface AccountDomainState {
  addresses: Address[];
  paymentMethods: PaymentMethod[];
  activeOrders: Order[];
  historyOrders: Order[];
  supportTickets: SupportTicket[];
  ownedTickets: EventTicket[];
  walletBalance: number;
  favoriteRestaurantIds: string[];
  favoriteEventIds: string[];
  favoriteMarketIds: string[];
  followedOrganizerIds: string[];
  orderRatings: Record<string, number>;
}

interface InventoryDashboard {
  items: Array<ReturnType<AppDataService['toInventoryItemPayload']>>;
  totalItems: number;
  lowStockCount: number;
  outOfStockCount: number;
  openOrdersCount: number;
  integrationErrorCount: number;
  pendingSyncCount: number;
  totalAvailableUnits: number;
}

interface HappyHourOfferPayload {
  id: string;
  productId: string;
  vendorId: string;
  vendorName: string;
  vendorSubtitle: string;
  title: string;
  subtitle: string;
  description: string;
  imageUrl: string;
  badge: string;
  discountedPrice: number;
  discountedPriceText: string;
  originalPrice: number;
  originalPriceText: string;
  discountPercent: number;
  expiresInMinutes: number;
  rewardPoints: number;
  claimCount: number;
  locationTitle: string;
  locationSubtitle: string;
  sectionLabel: string;
  stockStatus: StockStatusPayload;
}

const TR_LOCALE = 'tr-TR';
const TIME_ZONE = 'Europe/Istanbul';
const DEFAULT_PASSWORD_RESET_TEST_CODE = '12345';

const VENDOR_MARKETING: Record<
  string,
  {
    etaMin: number;
    etaMax: number;
    ratingValue: number;
    promo: string;
    studentFriendly: boolean;
  }
> = {
  'vendor-burger-yiyelim': {
    etaMin: 15,
    etaMax: 25,
    ratingValue: 4.8,
    promo: 'Öğrenci Dostu',
    studentFriendly: true,
  },
  'vendor-pizza-bulls': {
    etaMin: 18,
    etaMax: 26,
    ratingValue: 4.7,
    promo: 'İnce Hamur',
    studentFriendly: true,
  },
  'vendor-happy-hour-market': {
    etaMin: 10,
    etaMax: 18,
    ratingValue: 4.9,
    promo: 'Happy Hour',
    studentFriendly: true,
  },
};

const DEMO_VENDORS: VendorRecord[] = [
  {
    id: 'vendor-burger-yiyelim',
    name: 'Burger Yiyelim',
    slug: 'burger-yiyelim',
    category: 'Restaurant',
    pickupPointId: 'pickup-burger-yiyelim',
    pickupPointLabel: 'Moda Gel-Al Noktası',
  },
  {
    id: 'vendor-pizza-bulls',
    name: 'Pizza Bulls',
    slug: 'pizza-bulls',
    category: 'Restaurant',
    pickupPointId: 'pickup-pizza-bulls',
    pickupPointLabel: 'Bostancı Gel-Al Noktası',
  },
  {
    id: 'vendor-happy-hour-market',
    name: 'Happy Hour Market',
    slug: 'happy-hour-market',
    category: 'Market',
    pickupPointId: 'pickup-happy-hour-market',
    pickupPointLabel: 'Kadıköy Gel-Al Noktası',
  },
];

const DEMO_PRODUCTS = [
  {
    id: 'mega-burger-menu',
    vendorId: 'vendor-burger-yiyelim',
    vendorName: 'Burger Yiyelim',
    title: 'Mega Burger Menü',
    description: 'Çifte köfte, cheddar ve patates ile hızlı pickup menü.',
    imageUrl:
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1200&q=80',
    category: 'Burger',
    unitPrice: 185,
    sku: 'BK-MEGA-001',
    barcode: '8690000000001',
    externalCode: 'EXT-BK-001',
    locationId: 'loc-kadikoy-front',
    locationLabel: 'Kadıköy Ön Tezgah',
    trackStock: true,
    reorderLevel: 5,
    isArchived: false,
    onHand: 18,
    reserved: 1,
  },
  {
    id: 'double-whopper-menu',
    vendorId: 'vendor-burger-yiyelim',
    vendorName: 'Burger Yiyelim',
    title: 'Double Whopper Menü',
    description: 'Duble köfte ve büyük içecek ile premium menü.',
    imageUrl:
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1200&q=80',
    category: 'Burger',
    unitPrice: 240,
    sku: 'BK-WHOP-002',
    barcode: '8690000000002',
    externalCode: 'EXT-BK-002',
    locationId: 'loc-kadikoy-front',
    locationLabel: 'Kadıköy Ön Tezgah',
    trackStock: true,
    reorderLevel: 4,
    isArchived: false,
    onHand: 7,
    reserved: 1,
  },
  {
    id: 'pepperoni-pizza-slice',
    vendorId: 'vendor-pizza-bulls',
    vendorName: 'Pizza Bulls',
    title: 'Pepperonili Pizza Dilimi',
    description: 'Öğrenci dostu dilim pizza.',
    imageUrl:
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=80',
    category: 'Pizza',
    unitPrice: 100,
    sku: 'PZ-PEP-010',
    barcode: '8690000000010',
    externalCode: 'EXT-PZ-010',
    locationId: 'loc-bostanci-hotline',
    locationLabel: 'Bostancı Sıcak Hat',
    trackStock: true,
    reorderLevel: 6,
    isArchived: false,
    onHand: 22,
    reserved: 2,
  },
  {
    id: 'market-bundle',
    vendorId: 'vendor-happy-hour-market',
    vendorName: 'Happy Hour Market',
    title: 'Market Happy Hour Paketi',
    description: 'Kahvaltılık ve atıştırmalık kombinasyonu.',
    imageUrl:
      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    category: 'Bundle',
    unitPrice: 164,
    sku: 'MR-BND-021',
    barcode: '8690000000021',
    externalCode: 'EXT-MR-021',
    locationId: 'loc-market-cold',
    locationLabel: 'Market Soğuk Depo',
    trackStock: true,
    reorderLevel: 6,
    isArchived: false,
    onHand: 11,
    reserved: 1,
  },
  {
    id: 'gunluk-sut',
    vendorId: 'vendor-happy-hour-market',
    vendorName: 'Happy Hour Market',
    title: 'Günlük Süt',
    description: 'Soğuk zincirde günlük süt.',
    imageUrl:
      'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=1200&q=80',
    category: 'Dairy',
    unitPrice: 42,
    sku: 'MR-MLK-032',
    barcode: '8690000000032',
    externalCode: 'EXT-MR-032',
    locationId: 'loc-market-cold',
    locationLabel: 'Market Soğuk Depo',
    trackStock: true,
    reorderLevel: 10,
    isArchived: false,
    onHand: 8,
    reserved: 0,
  },
  {
    id: 'paket-yogurt',
    vendorId: 'vendor-happy-hour-market',
    vendorName: 'Happy Hour Market',
    title: 'Paket Yoğurt',
    description: 'Tek kişilik yoğurt kasesi.',
    imageUrl:
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=1200&q=80',
    category: 'Dairy',
    unitPrice: 36,
    sku: 'MR-YGT-033',
    barcode: '8690000000033',
    externalCode: 'EXT-MR-033',
    locationId: 'loc-market-cold',
    locationLabel: 'Market Soğuk Depo',
    trackStock: true,
    reorderLevel: 8,
    isArchived: false,
    onHand: 4,
    reserved: 0,
  },
  {
    id: 'lor-peyniri',
    vendorId: 'vendor-happy-hour-market',
    vendorName: 'Happy Hour Market',
    title: 'Lor Peyniri',
    description: 'Kahvaltılık paket peynir.',
    imageUrl:
      'https://images.unsplash.com/photo-1452195100486-9cc805987862?auto=format&fit=crop&w=1200&q=80',
    category: 'Dairy',
    unitPrice: 58,
    sku: 'MR-CHE-034',
    barcode: '8690000000034',
    externalCode: 'EXT-MR-034',
    locationId: 'loc-market-cold',
    locationLabel: 'Market Soğuk Depo',
    trackStock: true,
    reorderLevel: 5,
    isArchived: false,
    onHand: 0,
    reserved: 0,
  },
] as const;

const DEMO_INTEGRATIONS = [
  {
    id: 'int-burger-001',
    vendorId: 'vendor-burger-yiyelim',
    vendorName: 'Burger Yiyelim',
    name: 'Burger POS Bridge',
    provider: 'Nebim POS',
    type: 'POS' as const,
    baseUrl: 'https://pos.burgeryiyelim.local',
    locationId: 'loc-kadikoy-front',
    health: 'healthy' as const,
    lastSync: {
      connectionId: 'int-burger-001',
      status: 'success' as const,
      startedAt: new Date('2026-04-09T11:10:00+03:00'),
      completedAt: new Date('2026-04-09T11:10:00+03:00'),
      processedCount: 2,
      errorMessage: '',
    },
    skuMappings: {
      'EXT-BK-001': 'BK-MEGA-001',
      'EXT-BK-002': 'BK-WHOP-002',
    },
  },
  {
    id: 'int-market-001',
    vendorId: 'vendor-happy-hour-market',
    vendorName: 'Happy Hour Market',
    name: 'Market ERP Feed',
    provider: 'Logo ERP',
    type: 'ERP' as const,
    baseUrl: 'https://erp.happyhourmarket.local',
    locationId: 'loc-market-cold',
    health: 'warning' as const,
    lastSync: {
      connectionId: 'int-market-001',
      status: 'failed' as const,
      startedAt: new Date('2026-04-09T10:45:00+03:00'),
      completedAt: new Date('2026-04-09T10:46:00+03:00'),
      processedCount: 1,
      errorMessage: 'Timeout during cold storage feed sync',
    },
    skuMappings: {
      'EXT-MR-021': 'MR-BND-021',
      'EXT-MR-032': 'MR-MLK-032',
      'EXT-MR-033': 'MR-YGT-033',
      'EXT-MR-034': 'MR-CHE-034',
    },
  },
] as const;

const DEMO_EVENTS = [
  {
    id: 'event-galata-jazz',
    vendorId: 'vendor-burger-yiyelim',
    title: "Galata'da Caz Gecesi",
    venue: 'Galata Sahnesi',
    district: 'Beyoğlu, İstanbul',
    imageUrl:
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
    startsAt: new Date('2026-10-24T19:00:00+03:00'),
    pointsCost: 650,
    capacity: 120,
    remainingCount: 78,
  },
  {
    id: 'event-pottery-workshop',
    vendorId: 'vendor-happy-hour-market',
    title: 'Seramik Atölyesi',
    venue: 'Bomontiada',
    district: 'Şişli, İstanbul',
    imageUrl:
      'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80',
    startsAt: new Date('2026-10-26T18:30:00+03:00'),
    pointsCost: 420,
    capacity: 50,
    remainingCount: 29,
  },
] as const;

const DEMO_USERS = [
  {
    id: 'usr_customer_001',
    email: 'bayram@example.com',
    password: 'password123',
    displayName: 'Bayram Senbay',
    phone: '+90 555 123 45 67',
    role: PrismaRole.CUSTOMER,
    vendorId: null,
    studentVerifiedAt: new Date('2026-04-01T09:00:00+03:00'),
    notificationsEnabled: true,
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
  },
  {
    id: 'usr_admin_001',
    email: 'admin@speto.app',
    password: 'admin123',
    displayName: 'Speto Admin',
    phone: '+90 555 000 11 22',
    role: PrismaRole.ADMIN,
    vendorId: null,
    studentVerifiedAt: null,
    notificationsEnabled: true,
    avatarUrl: 'https://i.pravatar.cc/150?img=32',
  },
  {
    id: 'usr_vendor_001',
    email: 'burger@speto.app',
    password: 'vendor123',
    displayName: 'Burger Yiyelim Operasyon',
    phone: '+90 555 010 20 30',
    role: PrismaRole.VENDOR,
    vendorId: 'vendor-burger-yiyelim',
    studentVerifiedAt: null,
    notificationsEnabled: true,
    avatarUrl: 'https://i.pravatar.cc/150?img=18',
  },
  {
    id: 'usr_vendor_002',
    email: 'market@speto.app',
    password: 'vendor123',
    displayName: 'Migros Jet Operasyon',
    phone: '+90 555 040 50 60',
    role: PrismaRole.VENDOR,
    vendorId: 'vendor-migros-jet',
    studentVerifiedAt: null,
    notificationsEnabled: true,
    avatarUrl: 'https://i.pravatar.cc/150?img=28',
  },
] as const;

const DEMO_SUPPORT_TICKETS = [
  {
    id: 'support-001',
    userId: 'usr_customer_001',
    subject: 'Gel-al hazırlık süresi hakkında bilgi',
    message: 'Siparişim için güncel hazırlık durumunu görmek istiyorum.',
    channel: 'Canlı Destek',
    status: PrismaSupportStatus.OPEN,
    createdAt: new Date('2026-10-24T18:42:00+03:00'),
  },
] as const;

const DEMO_ADDRESSES = [
  {
    id: 'address-home',
    userId: 'usr_customer_001',
    label: 'Ev',
    address: 'Cumhuriyet Mah. Çınar Sok. No:5, D:12, Kadıköy/İstanbul',
    iconKey: 'home',
    isPrimary: true,
  },
  {
    id: 'address-school',
    userId: 'usr_customer_001',
    label: 'Okul',
    address: 'Beşiktaş Kampüsü, Yıldız Mah., Beşiktaş/İstanbul',
    iconKey: 'school',
    isPrimary: false,
  },
] as const;

const DEMO_PAYMENT_METHODS = [
  {
    id: 'pm_demo_001',
    userId: 'usr_customer_001',
    provider: 'demo',
    providerToken: 'pm_demo_001',
    brand: 'VISA',
    last4: '4242',
    expiryMonth: 12,
    expiryYear: 2027,
    holderName: 'Bayram Senbay',
    isDefault: true,
  },
] as const;

const DEMO_WALLET_ENTRIES = [
  {
    id: 'wallet_seed_customer',
    userId: 'usr_customer_001',
    delta: 1420,
    reason: 'Initial demo balance',
    referenceId: null as string | null,
    createdAt: new Date('2026-10-20T09:00:00+03:00'),
  },
] as const;

const DEMO_ORDERS = [
  {
    id: 'ord_demo_001',
    userId: 'usr_customer_001',
    vendorId: 'vendor-burger-yiyelim',
    pickupPointId: 'pickup-burger-yiyelim',
    status: PrismaOrderStatus.PREPARING,
    pickupCode: 'BK12',
    etaLabel: '12 dk',
    subtotal: 179,
    discountAmount: 0,
    totalAmount: 179,
    promoCode: '',
    paymentMethodId: 'pm_demo_001',
    createdAt: new Date('2026-10-24T18:20:00+03:00'),
    items: [
      {
        id: 'ord_demo_001_item_1',
        productId: 'product-restaurant-burger-yiyelim-double-whopper-menu',
        title: 'Double Whopper Menü',
        quantity: 1,
        unitPrice: 179,
      },
    ],
  },
  {
    id: 'ord_demo_000',
    userId: 'usr_customer_001',
    vendorId: 'vendor-pizza-bulls',
    pickupPointId: 'pickup-pizza-bulls',
    status: PrismaOrderStatus.COMPLETED,
    pickupCode: 'PZ88',
    etaLabel: 'Tamamlandı',
    subtotal: 219,
    discountAmount: 10,
    totalAmount: 209,
    promoCode: 'KAMPUS10',
    paymentMethodId: 'pm_demo_001',
    createdAt: new Date('2026-10-23T21:10:00+03:00'),
    items: [
      {
        id: 'ord_demo_000_item_1',
        productId: 'product-restaurant-pizza-bulls-pepperoni-pizza',
        title: 'Pepperoni Pizza',
        quantity: 1,
        unitPrice: 219,
      },
    ],
  },
] as const;

const orderInclude = {
  vendor: true,
  pickupPoint: true,
  paymentMethod: true,
  items: {
    include: {
      product: true,
    },
  },
} satisfies Prisma.OrderInclude;

const stockInclude = {
  product: true,
  vendor: true,
} satisfies Prisma.InventoryStockInclude;

const movementInclude = {
  product: true,
  vendor: true,
} satisfies Prisma.InventoryMovementInclude;

const integrationInclude = {
  vendor: true,
  syncRuns: {
    orderBy: {
      startedAt: 'desc' as const,
    },
    take: 1,
  },
} satisfies Prisma.IntegrationConnectionInclude;

const ticketInclude = {
  event: true,
} satisfies Prisma.TicketInclude;

const publicCatalogProductWhere = {
  isArchived: false,
  isActive: true,
  isVisibleInApp: true,
};

const catalogVendorInclude = {
  pickupPoints: {
    where: { isActive: true },
    orderBy: { createdAt: 'asc' as const },
  },
  operators: {
    where: { role: PrismaRole.VENDOR },
    orderBy: { createdAt: 'asc' as const },
  },
  inventory: {
    include: {
      product: true,
    },
  },
  highlights: {
    orderBy: { displayOrder: 'asc' as const },
  },
  sections: {
    where: { isActive: true },
    orderBy: { displayOrder: 'asc' as const },
    include: {
      products: {
        where: publicCatalogProductWhere,
        orderBy: [{ displayOrder: 'asc' as const }, { createdAt: 'asc' as const }],
      },
    },
  },
} satisfies Prisma.VendorInclude;

type UserRecord = Prisma.UserGetPayload<{}>;
type OrderRecord = Prisma.OrderGetPayload<{ include: typeof orderInclude }>;
type StockRecord = Prisma.InventoryStockGetPayload<{ include: typeof stockInclude }>;
type MovementRecord = Prisma.InventoryMovementGetPayload<{ include: typeof movementInclude }>;
type IntegrationRecord = Prisma.IntegrationConnectionGetPayload<{
  include: typeof integrationInclude;
}>;
type TicketRecord = Prisma.TicketGetPayload<{ include: typeof ticketInclude }>;
type CatalogVendorRecord = Prisma.VendorGetPayload<{ include: typeof catalogVendorInclude }>;
type ContentBlockRecord = Prisma.ContentBlockGetPayload<{}>;

@Injectable()
export class AppDataService {
  private initializationPromise: Promise<void> | null = null;
  private readonly passwordResetOtpTestMode =
    (process.env.OTP_TEST_MODE ?? 'true').trim().toLowerCase() === 'true';
  private readonly passwordResetOtpTestCode = this.normalizeOtpCode(
    process.env.OTP_TEST_CODE,
  );
  private readonly resendApiKey = (process.env.RESEND_API_KEY ?? '').trim();
  private readonly resendApiBaseUrl = (
    process.env.RESEND_API_BASE_URL ?? 'https://api.resend.com'
  ).trim();
  private readonly resendFromEmail = (
    process.env.RESEND_FROM_EMAIL ?? 'Speto <onboarding@resend.dev>'
  ).trim();

  constructor(
    private readonly prisma: PrismaService,
    private readonly requestContext: RequestContextService,
  ) {}

  async register(payload: RegisterDto) {
    await this.ensureInitialized();
    const normalizedEmail = this.normalizeEmail(payload.email);
    const existing = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    if (existing) {
      throw new BadRequestException('Email already registered');
    }

    const user = await this.prisma.user.create({
      data: {
        email: normalizedEmail,
        password: payload.password,
        displayName: payload.displayName,
        phone: payload.phone,
        role: PrismaRole.CUSTOMER,
        studentVerifiedAt: payload.studentEmail ? new Date() : null,
        notificationsEnabled: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
      },
    });
    return this.buildSessionResponse(user);
  }

  async login(email: string, password: string) {
    await this.ensureInitialized();
    const normalizedEmail = this.normalizeEmail(email);
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
    });
    if (!user || user.password !== password) {
      throw new UnauthorizedException('Invalid email or password');
    }

    return this.buildSessionResponse(user);
  }

  async requestPasswordReset(email: string) {
    await this.ensureInitialized();
    const normalizedEmail = this.normalizeEmail(email);
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    if (user) {
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
      const otpCode = this.generatePasswordResetOtpCode();
      await this.prisma.passwordResetOtp.deleteMany({
        where: { email: normalizedEmail, purpose: 'PASSWORD_RESET' },
      });
      await this.prisma.passwordResetOtp.create({
        data: {
          email: normalizedEmail,
          purpose: 'PASSWORD_RESET',
          codeHash: this.hashOtpCode(otpCode),
          expiresAt,
        },
      });
      await this.deliverPasswordResetOtpEmail({
        email: normalizedEmail,
        code: otpCode,
        expiresAt,
      });
      return {
        exists: true,
        expiresAt: expiresAt.toISOString(),
        otpMode: this.passwordResetOtpTestMode ? 'test' : 'email',
        testCode: this.passwordResetOtpTestMode ? otpCode : null,
      };
    }
    return {
      exists: false,
      otpMode: this.passwordResetOtpTestMode ? 'test' : 'email',
    };
  }

  async accountExists(email: string) {
    await this.ensureInitialized();
    const normalizedEmail = this.normalizeEmail(email);
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    return {
      exists: user != null,
    };
  }

  async verifyPasswordResetOtp(email: string, code: string) {
    await this.ensureInitialized();
    const normalizedEmail = this.normalizeEmail(email);
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    if (!user) {
      return { verified: false };
    }

    const otp = await this.prisma.passwordResetOtp.findFirst({
      where: {
        email: normalizedEmail,
        purpose: 'PASSWORD_RESET',
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!otp || !this.isValidPasswordResetOtp(otp, code.trim())) {
      return { verified: false };
    }

    const consumedAt = otp.consumedAt ?? new Date();
    if (!otp.consumedAt) {
      await this.prisma.passwordResetOtp.update({
        where: { id: otp.id },
        data: { consumedAt },
      });
    }

    return {
      verified: true,
      expiresAt: otp.expiresAt.toISOString(),
    };
  }

  async updatePassword(email: string, password: string) {
    await this.ensureInitialized();
    const normalizedEmail = this.normalizeEmail(email);
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    if (!user) {
      return { success: false };
    }

    const verifiedOtp = await this.prisma.passwordResetOtp.findFirst({
      where: {
        email: normalizedEmail,
        purpose: 'PASSWORD_RESET',
        consumedAt: { not: null },
        expiresAt: { gt: new Date() },
      },
      orderBy: { consumedAt: 'desc' },
    });
    if (!verifiedOtp) {
      return { success: false };
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { email: normalizedEmail },
        data: { password },
      });
      await tx.passwordResetOtp.deleteMany({
        where: { email: normalizedEmail, purpose: 'PASSWORD_RESET' },
      });
    });

    return { success: true };
  }

  getCapabilities() {
    return {
      courierEnabled: false,
      pickupOnly: true,
      oauthProviders: ['google', 'apple'],
      roles: ['CUSTOMER', 'ADMIN', 'VENDOR'],
      stockAppEnabled: true,
    };
  }

  async getBootstrap() {
    await this.ensureInitialized();
    const current = await this.findUserFromAccessToken(this.requestContext.accessToken);
    return {
      capabilities: this.getCapabilities(),
      contentVersion: await this.getContentVersion(),
      home: await this.getHomeContent(),
      restaurants: await this.listRestaurants(),
      markets: await this.listMarkets(),
      events: await this.listEvents(),
      featured: {
        restaurants: (await this.listRestaurants()).slice(0, 4),
        events: (await this.listEvents()).slice(0, 4),
      },
      snapshot: current ? await this.getSnapshot() : null,
    };
  }

  async getProfile() {
    const user = await this.requireCurrentUser();
    return this.toAppUser(user);
  }

  async updateProfile(payload: UpdateProfileDto) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const nextEmail = payload.email
      ? this.normalizeEmail(payload.email)
      : current.email;

    if (nextEmail !== current.email) {
      const existing = await this.prisma.user.findUnique({
        where: { email: nextEmail },
        select: { id: true },
      });
      if (existing && existing.id !== current.id) {
        throw new BadRequestException('Email already registered');
      }
    }

    await this.prisma.user.update({
      where: { id: current.id },
      data: {
        email: nextEmail,
        displayName: payload.displayName ?? current.displayName,
        phone: payload.phone ?? current.phone,
        avatarUrl: payload.avatarUrl ?? current.avatarUrl,
        notificationsEnabled:
          payload.notificationsEnabled ?? current.notificationsEnabled,
      },
    });

    return this.getProfile();
  }

  async deleteAccount() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    await this.prisma.user.delete({
      where: { id: current.id },
    });

    const replacementEmail = `deleted-${randomUUID().slice(0, 8)}@speto.app`;
    await this.prisma.user.create({
      data: {
        email: replacementEmail,
        password: randomUUID(),
        displayName: 'Speto Kullanıcısı',
        phone: '',
        role: PrismaRole.CUSTOMER,
        notificationsEnabled: false,
        avatarUrl: '',
      },
    });
    return { success: true };
  }

  async listAddresses() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const addresses = await this.prisma.savedPlace.findMany({
      where: { userId: current.id },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
    });
    return addresses.map((address) => this.toAddress(address));
  }

  async saveAddress(payload: CreateAddressDto) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();

    if (payload.isPrimary) {
      await this.prisma.savedPlace.updateMany({
        where: { userId: current.id },
        data: { isPrimary: false },
      });
    }

    const isPrimary =
      payload.isPrimary ?? ((await this.prisma.savedPlace.count({
        where: { userId: current.id },
      })) === 0);

    const data = {
      userId: current.id,
      label: payload.label,
      address: payload.address,
      iconKey: payload.iconKey ?? 'location',
      isPrimary,
    };

    const address = payload.id
      ? await this.prisma.savedPlace.upsert({
          where: { id: payload.id },
          update: data,
          create: { id: payload.id, ...data },
        })
      : await this.prisma.savedPlace.create({
          data,
        });

    return this.toAddress(address);
  }

  async deleteAddress(id: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    await this.prisma.savedPlace.deleteMany({
      where: { id, userId: current.id },
    });

    const nextPrimary = await this.prisma.savedPlace.findFirst({
      where: { userId: current.id },
      orderBy: { createdAt: 'asc' },
    });
    if (nextPrimary) {
      await this.prisma.savedPlace.update({
        where: { id: nextPrimary.id },
        data: { isPrimary: true },
      });
    }

    return { success: true };
  }

  async listPaymentMethods() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const methods = await this.prisma.paymentMethod.findMany({
      where: { userId: current.id },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
    });
    return methods.map((method) => this.toPaymentMethod(method));
  }

  async savePaymentMethod(payload: CreatePaymentMethodDto) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();

    if (payload.isDefault) {
      await this.prisma.paymentMethod.updateMany({
        where: { userId: current.id },
        data: { isDefault: false },
      });
    }

    const existingCount = await this.prisma.paymentMethod.count({
      where: { userId: current.id },
    });
    const isDefault = payload.isDefault ?? existingCount === 0;
    const [expiryMonth, expiryYearSuffix] = payload.expiry.split('/');
    const expiryYear = Number(expiryYearSuffix?.length === 2 ? `20${expiryYearSuffix}` : expiryYearSuffix);

    const data = {
      userId: current.id,
      provider: payload.brand.toLowerCase(),
      providerToken: payload.token ?? payload.id ?? `pm_${randomUUID()}`,
      brand: payload.brand.toUpperCase(),
      last4: payload.last4,
      expiryMonth: Number(expiryMonth),
      expiryYear,
      holderName: payload.holderName,
      isDefault,
    };

    const method = payload.id
      ? await this.prisma.paymentMethod.upsert({
          where: { id: payload.id },
          update: data,
          create: { id: payload.id, ...data },
        })
      : await this.prisma.paymentMethod.create({
          data,
        });

    return this.toPaymentMethod(method);
  }

  async deletePaymentMethod(id: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    await this.prisma.paymentMethod.deleteMany({
      where: { id, userId: current.id },
    });

    const nextDefault = await this.prisma.paymentMethod.findFirst({
      where: { userId: current.id },
      orderBy: { createdAt: 'asc' },
    });
    if (nextDefault) {
      await this.prisma.paymentMethod.update({
        where: { id: nextDefault.id },
        data: { isDefault: true },
      });
    }

    return { success: true };
  }

  async getPreferences() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    return this.getPreferencePayload(current.id);
  }

  async updatePreference(entityType: string, entityId: string, enabled: boolean) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const normalizedType = this.normalizePreferenceEntityType(entityType);
    const normalizedEntityId = entityId.trim();

    if (!normalizedEntityId) {
      throw new BadRequestException('Preference entity id is required');
    }

    if (enabled) {
      await this.assertPreferenceEntityExists(normalizedType, normalizedEntityId);
      await this.prisma.favorite.upsert({
        where: {
          userId_entityType_entityId: {
            userId: current.id,
            entityType: normalizedType,
            entityId: normalizedEntityId,
          },
        },
        update: {},
        create: {
          userId: current.id,
          entityType: normalizedType,
          entityId: normalizedEntityId,
        },
      });
    } else {
      await this.prisma.favorite.deleteMany({
        where: {
          userId: current.id,
          entityType: normalizedType,
          entityId: normalizedEntityId,
        },
      });
    }

    return this.getPreferencePayload(current.id);
  }

  async listRestaurants() {
    await this.ensureInitialized();
    const vendors = await this.prisma.vendor.findMany({
      where: {
        storefrontType: PrismaStorefrontType.RESTAURANT,
        isActive: true,
      },
      include: catalogVendorInclude,
      orderBy: [{ displayOrder: 'asc' }, { name: 'asc' }],
    });
    return vendors.map((vendor) => this.toRestaurantCatalogItem(vendor));
  }

  async listMarkets() {
    await this.ensureInitialized();
    const vendors = await this.prisma.vendor.findMany({
      where: {
        storefrontType: PrismaStorefrontType.MARKET,
        isActive: true,
      },
      include: catalogVendorInclude,
      orderBy: [{ displayOrder: 'asc' }, { name: 'asc' }],
    });
    return vendors.map((vendor) => this.toMarketCatalogItem(vendor));
  }

  async listEvents() {
    await this.ensureInitialized();
    const events = await this.prisma.event.findMany({
      where: { isActive: true },
      orderBy: [{ displayOrder: 'asc' }, { startsAt: 'asc' }],
    });
    return events.map((event) => this.toEventDetailPayload(event));
  }

  async listHappyHourOffers() {
    await this.ensureInitialized();
    const vendors = await this.prisma.vendor.findMany({
      where: { isActive: true },
      include: catalogVendorInclude,
      orderBy: [{ isFeatured: 'desc' }, { displayOrder: 'asc' }, { name: 'asc' }],
    });
    return this.buildHappyHourOffers(vendors);
  }

  async getHappyHourOfferDetail(offerId: string) {
    const offer = (await this.listHappyHourOffers()).find((item) => item.id === offerId);
    if (!offer) {
      throw new NotFoundException(`Happy hour offer ${offerId} not found`);
    }
    return offer;
  }

  async getVendorCatalog(vendorId: string) {
    await this.ensureInitialized();
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: catalogVendorInclude,
    });
    if (!vendor || !vendor.isActive) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }
    return this.toVendorDetailPayload(vendor);
  }

  async listVendorSections(vendorId: string) {
    const vendor = await this.requireCatalogVendor(vendorId);
    return vendor.sections.map((section) => this.toCatalogSectionPayload(section, vendor));
  }

  async listVendorProducts(vendorId: string) {
    const vendor = await this.requireCatalogVendor(vendorId);
    return vendor.sections.flatMap((section) =>
      section.products.map((product) => this.toCatalogProductPayload(product, vendor)),
    );
  }

  async getEventDetail(eventId: string) {
    await this.ensureInitialized();
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });
    if (!event || !event.isActive) {
      throw new NotFoundException(`Event ${eventId} not found`);
    }
    return this.toEventDetailPayload(event);
  }

  async listCatalogAdminVendors(vendorId?: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    const allowedVendorIds = await this.resolveVendorScope(current, vendorId);
    const vendors = await this.prisma.vendor.findMany({
      where: {
        id: { in: allowedVendorIds },
        storefrontType: { in: [PrismaStorefrontType.RESTAURANT, PrismaStorefrontType.MARKET] },
      },
      include: catalogVendorInclude,
      orderBy: [{ displayOrder: 'asc' }, { name: 'asc' }],
    });
    return vendors.map((vendor) => this.toVendorDetailPayload(vendor));
  }

  async createCatalogVendor(payload: Record<string, unknown>) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertAdminAccess(current);

    const name = typeof payload['name'] === 'string' ? payload['name'].trim() : '';
    if (!name) {
      throw new BadRequestException('Vendor adı zorunludur');
    }

    const slugBase = typeof payload['slug'] === 'string' && payload['slug'].trim().length > 0
      ? payload['slug']
      : name;
    const slug = this.slugify(slugBase);
    const vendorId =
      typeof payload['vendorId'] === 'string' && payload['vendorId'].trim().length > 0
        ? payload['vendorId'].trim()
        : `vendor-${slug}`;
    const storefrontType =
      payload['storefrontType'] === 'MARKET'
        ? PrismaStorefrontType.MARKET
        : PrismaStorefrontType.RESTAURANT;
    const category =
      typeof payload['category'] === 'string' && payload['category'].trim().length > 0
        ? payload['category'].trim()
        : storefrontType === PrismaStorefrontType.MARKET
          ? 'Market'
          : 'Restoran';
    const pickupPointLabel =
      typeof payload['pickupPointLabel'] === 'string' && payload['pickupPointLabel'].trim().length > 0
        ? payload['pickupPointLabel'].trim()
        : `${name} teslim noktası`;
    const pickupPointAddress =
      typeof payload['pickupPointAddress'] === 'string' && payload['pickupPointAddress'].trim().length > 0
        ? payload['pickupPointAddress'].trim()
        : 'Adres bilgisi henüz girilmedi';
    const operatorEmail =
      typeof payload['operatorEmail'] === 'string' && payload['operatorEmail'].trim().length > 0
        ? this.normalizeEmail(payload['operatorEmail'])
        : `ops+${slug}@speto.app`;
    const operatorPassword =
      typeof payload['operatorPassword'] === 'string' && payload['operatorPassword'].trim().length > 0
        ? payload['operatorPassword'].trim()
        : 'vendor123';
    const operatorDisplayName =
      typeof payload['operatorDisplayName'] === 'string' &&
      payload['operatorDisplayName'].trim().length > 0
        ? payload['operatorDisplayName'].trim()
        : `${name} Operasyon`;
    const operatorPhone =
      typeof payload['operatorPhone'] === 'string' ? payload['operatorPhone'].trim() : '';
    const defaultSectionLabel =
      typeof payload['defaultSectionLabel'] === 'string' &&
      payload['defaultSectionLabel'].trim().length > 0
        ? payload['defaultSectionLabel'].trim()
        : 'Genel';

    const existingVendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      select: { id: true },
    });
    if (existingVendor) {
      throw new BadRequestException(`Vendor ${vendorId} zaten mevcut`);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.vendor.create({
        data: {
          id: vendorId,
          name,
          slug,
          category,
          storefrontId: vendorId,
          storefrontType,
          displayOrder:
            typeof payload['displayOrder'] === 'number'
              ? Math.max(0, Math.trunc(payload['displayOrder']))
              : 999,
          ...this.toCatalogVendorUpdateData(payload),
        },
      });
      await tx.pickupPoint.create({
        data: {
          vendorId,
          label: pickupPointLabel,
          address: pickupPointAddress,
        },
      });
      await tx.catalogSection.create({
        data: {
          vendorId,
          key: this.slugify(defaultSectionLabel),
          label: defaultSectionLabel,
          displayOrder: 0,
          isActive: true,
        },
      });
      await this.upsertVendorOperator(tx, {
        vendorId,
        email: operatorEmail,
        password: operatorPassword,
        displayName: operatorDisplayName,
        phone: operatorPhone,
      });
    });

    return this.getVendorCatalog(vendorId);
  }

  async updateCatalogVendor(
    vendorId: string,
    payload: Record<string, unknown>,
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    this.assertVendorAccess(current, vendorId);

    const existing = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        pickupPoints: {
          orderBy: { createdAt: 'asc' },
        },
        operators: {
          where: { role: PrismaRole.VENDOR },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    if (!existing) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.vendor.update({
        where: { id: vendorId },
        data: this.toCatalogVendorUpdateData(payload),
      });

      const pickupLabel =
        typeof payload['pickupPointLabel'] === 'string' ? payload['pickupPointLabel'].trim() : '';
      const pickupAddress =
        typeof payload['pickupPointAddress'] === 'string'
          ? payload['pickupPointAddress'].trim()
          : '';
      if (pickupLabel || pickupAddress) {
        const primaryPickupPoint = existing.pickupPoints[0];
        if (primaryPickupPoint) {
          await tx.pickupPoint.update({
            where: { id: primaryPickupPoint.id },
            data: {
              ...(pickupLabel ? { label: pickupLabel } : {}),
              ...(pickupAddress ? { address: pickupAddress } : {}),
            },
          });
        } else {
          await tx.pickupPoint.create({
            data: {
              vendorId,
              label: pickupLabel || `${existing.name} teslim noktası`,
              address: pickupAddress || 'Adres bilgisi henüz girilmedi',
            },
          });
        }
      }

      if (current.role === PrismaRole.ADMIN) {
        const operatorEmail =
          typeof payload['operatorEmail'] === 'string' ? payload['operatorEmail'].trim() : '';
        const operatorPassword =
          typeof payload['operatorPassword'] === 'string'
            ? payload['operatorPassword'].trim()
            : '';
        const operatorDisplayName =
          typeof payload['operatorDisplayName'] === 'string'
            ? payload['operatorDisplayName'].trim()
            : '';
        const operatorPhone =
          typeof payload['operatorPhone'] === 'string' ? payload['operatorPhone'].trim() : '';
        if (operatorEmail || operatorPassword || operatorDisplayName || operatorPhone) {
          await this.upsertVendorOperator(tx, {
            vendorId,
            existingOperatorId: existing.operators[0]?.id,
            email:
              operatorEmail ||
              existing.operators[0]?.email ||
              `ops+${existing.slug}@speto.app`,
            password: operatorPassword || existing.operators[0]?.password || 'vendor123',
            displayName:
              operatorDisplayName ||
              existing.operators[0]?.displayName ||
              `${existing.name} Operasyon`,
            phone: operatorPhone || existing.operators[0]?.phone || '',
          });
        }
      }
    });

    return this.getVendorCatalog(vendorId);
  }

  async listCatalogAdminSections(vendorId?: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    const allowedVendorIds = await this.resolveVendorScope(current, vendorId);
    const sections = await this.prisma.catalogSection.findMany({
      where: { vendorId: { in: allowedVendorIds } },
      include: {
        vendor: true,
        products: {
          where: publicCatalogProductWhere,
          orderBy: [{ displayOrder: 'asc' }, { createdAt: 'asc' }],
        },
      },
      orderBy: [{ displayOrder: 'asc' }, { label: 'asc' }],
    });
    return sections.map((section) => ({
      id: section.id,
      vendorId: section.vendorId,
      vendorName: section.vendor.name,
      key: section.key,
      label: section.label,
      displayOrder: section.displayOrder,
      isActive: section.isActive,
      productCount: section.products.length,
      products: section.products.map((product) => ({
        id: product.id,
        title: product.title,
        displayOrder: product.displayOrder,
      })),
    }));
  }

  async createCatalogSection(payload: Record<string, unknown>) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const vendorId = typeof payload['vendorId'] === 'string' ? payload['vendorId'].trim() : '';
    const label = typeof payload['label'] === 'string' ? payload['label'].trim() : '';
    if (!vendorId || !label) {
      throw new BadRequestException('vendorId ve label zorunludur');
    }
    this.assertVendorAccess(current, vendorId);

    const key =
      typeof payload['key'] === 'string' && payload['key'].trim().length > 0
        ? this.slugify(payload['key'])
        : this.slugify(label);

    await this.prisma.catalogSection.upsert({
      where: {
        vendorId_key: {
          vendorId,
          key,
        },
      },
      update: {
        label,
        displayOrder:
          typeof payload['displayOrder'] === 'number'
            ? Math.max(0, Math.trunc(payload['displayOrder']))
            : 0,
        isActive: typeof payload['isActive'] === 'boolean' ? payload['isActive'] : true,
      },
      create: {
        vendorId,
        key,
        label,
        displayOrder:
          typeof payload['displayOrder'] === 'number'
            ? Math.max(0, Math.trunc(payload['displayOrder']))
            : 0,
        isActive: typeof payload['isActive'] === 'boolean' ? payload['isActive'] : true,
      },
    });

    return this.listCatalogAdminSections(vendorId);
  }

  async updateCatalogSection(
    sectionId: string,
    payload: Record<string, unknown>,
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const existing = await this.prisma.catalogSection.findUnique({
      where: { id: sectionId },
    });
    if (!existing) {
      throw new NotFoundException(`Section ${sectionId} not found`);
    }
    this.assertVendorAccess(current, existing.vendorId);

    await this.prisma.catalogSection.update({
      where: { id: sectionId },
      data: {
        ...(typeof payload['label'] === 'string' ? { label: payload['label'] } : {}),
        ...(typeof payload['displayOrder'] === 'number'
          ? { displayOrder: Math.max(0, Math.trunc(payload['displayOrder'])) }
          : {}),
        ...(typeof payload['isActive'] === 'boolean' ? { isActive: payload['isActive'] } : {}),
      },
    });

    return this.listCatalogAdminSections(existing.vendorId);
  }

  async listCatalogAdminProducts(vendorId?: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    const allowedVendorIds = await this.resolveVendorScope(current, vendorId);
    const products = await this.prisma.product.findMany({
      where: {
        vendorId: { in: allowedVendorIds },
        catalogSectionId: { not: null },
        isArchived: false,
      },
      include: {
        vendor: true,
        catalogSection: true,
        inventory: true,
      },
      orderBy: [{ displayOrder: 'asc' }, { title: 'asc' }],
    });
    return products.map((product) => ({
      id: product.id,
      vendorId: product.vendorId,
      vendorName: product.vendor.name,
      sectionId: product.catalogSectionId,
      sectionLabel: product.catalogSection?.label ?? '',
      title: product.title,
      description: product.description ?? '',
      imageUrl: product.imageUrl ?? '',
      unitPrice: Number(product.unitPrice),
      category: product.kind,
      sku: product.sku,
      barcode: product.barcode ?? '',
      externalCode: product.externalCode ?? '',
      displaySubtitle: product.displaySubtitle ?? '',
      displayBadge: product.displayBadge ?? '',
      displayOrder: product.displayOrder,
      isVisibleInApp: product.isVisibleInApp,
      isFeatured: product.isFeatured,
      trackStock: product.trackStock,
      reorderLevel: product.reorderLevel,
      isArchived: product.isArchived,
      searchKeywords: this.toJsonStringArray(product.searchKeywords),
      legacyAliases: this.toJsonStringArray(product.legacyAliases),
      stockStatus: this.vendorStockStatusFromStocks(
        product.inventory.map((stock) => ({
          onHand: stock.onHand,
          reserved: stock.reserved,
          reorderLevel: product.reorderLevel,
          trackStock: product.trackStock,
          isArchived: product.isArchived,
        })),
      ),
    }));
  }

  async createCatalogProduct(payload: Record<string, unknown>) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const vendorId = typeof payload['vendorId'] === 'string' ? payload['vendorId'].trim() : '';
    const title = typeof payload['title'] === 'string' ? payload['title'].trim() : '';
    if (!vendorId || !title) {
      throw new BadRequestException('vendorId ve title zorunludur');
    }
    this.assertVendorAccess(current, vendorId);

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        pickupPoints: {
          where: { isActive: true },
          orderBy: { createdAt: 'asc' },
        },
        sections: {
          where: { isActive: true },
          orderBy: { displayOrder: 'asc' },
        },
      },
    });
    if (!vendor) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }

    let catalogSectionId =
      typeof payload['catalogSectionId'] === 'string' ? payload['catalogSectionId'].trim() : '';
    if (!catalogSectionId) {
      catalogSectionId = vendor.sections[0]?.id ?? '';
    }

    const resolvedSectionId = await this.resolveCatalogSectionId(
      vendorId,
      catalogSectionId,
      payload,
    );
    const skuBase =
      typeof payload['sku'] === 'string' && payload['sku'].trim().length > 0
        ? payload['sku'].trim()
        : `${vendor.slug}-${this.slugify(title)}`.toUpperCase();
    const locationId =
      typeof payload['locationId'] === 'string' && payload['locationId'].trim().length > 0
        ? payload['locationId'].trim()
        : this.seedLocationIdForVendor(vendorId);
    const locationLabel =
      typeof payload['locationLabel'] === 'string' && payload['locationLabel'].trim().length > 0
        ? payload['locationLabel'].trim()
        : vendor.pickupPoints[0]?.label ?? 'Ana depo';

    await this.prisma.$transaction(async (tx) => {
      const product = await tx.product.create({
        data: {
          vendorId,
          catalogSectionId: resolvedSectionId,
          title,
          description:
            typeof payload['description'] === 'string' ? payload['description'].trim() : '',
          unitPrice:
            typeof payload['unitPrice'] === 'number' ? Number(payload['unitPrice']) : 0,
          imageUrl: typeof payload['imageUrl'] === 'string' ? payload['imageUrl'].trim() : '',
          kind:
            typeof payload['category'] === 'string' && payload['category'].trim().length > 0
              ? payload['category'].trim()
              : vendor.category,
          sku: skuBase,
          barcode: typeof payload['barcode'] === 'string' ? payload['barcode'].trim() : '',
          externalCode:
            typeof payload['externalCode'] === 'string'
              ? payload['externalCode'].trim()
              : '',
          displaySubtitle:
            typeof payload['displaySubtitle'] === 'string'
              ? payload['displaySubtitle'].trim()
              : '',
          displayBadge:
            typeof payload['displayBadge'] === 'string'
              ? payload['displayBadge'].trim()
              : '',
          displayOrder:
            typeof payload['displayOrder'] === 'number'
              ? Math.max(0, Math.trunc(payload['displayOrder']))
              : 0,
          isFeatured: typeof payload['isFeatured'] === 'boolean' ? payload['isFeatured'] : false,
          isVisibleInApp:
            typeof payload['isVisibleInApp'] === 'boolean'
              ? payload['isVisibleInApp']
              : true,
          searchKeywords: this.toPayloadStringArray(payload['searchKeywords']),
          legacyAliases: this.toPayloadStringArray(payload['legacyAliases']),
          trackStock: typeof payload['trackStock'] === 'boolean' ? payload['trackStock'] : true,
          reorderLevel:
            typeof payload['reorderLevel'] === 'number'
              ? Math.max(0, Math.trunc(payload['reorderLevel']))
              : 3,
          isArchived: typeof payload['isArchived'] === 'boolean' ? payload['isArchived'] : false,
          isActive: true,
        },
      });

      await tx.inventoryStock.create({
        data: {
          productId: product.id,
          vendorId,
          locationId,
          locationLabel,
          onHand:
            typeof payload['onHand'] === 'number' ? Math.max(0, Math.trunc(payload['onHand'])) : 0,
          reserved: 0,
        },
      });
    });

    return this.getVendorCatalog(vendorId);
  }

  async updateCatalogProduct(
    productId: string,
    payload: Record<string, unknown>,
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const existing = await this.prisma.product.findUnique({
      where: { id: productId },
      include: { vendor: true },
    });
    if (!existing) {
      throw new NotFoundException(`Product ${productId} not found`);
    }
    this.assertVendorAccess(current, existing.vendorId);

    const catalogSectionId =
      typeof payload['catalogSectionId'] === 'string' ? payload['catalogSectionId'].trim() : '';
    const resolvedCatalogSectionId = catalogSectionId
      ? await this.resolveCatalogSectionId(existing.vendorId, catalogSectionId, payload)
      : '';

    await this.prisma.product.update({
      where: { id: productId },
      data: {
        ...(typeof payload['title'] === 'string' ? { title: payload['title'] } : {}),
        ...(typeof payload['description'] === 'string'
          ? { description: payload['description'] }
          : {}),
        ...(typeof payload['imageUrl'] === 'string' ? { imageUrl: payload['imageUrl'] } : {}),
        ...(typeof payload['displaySubtitle'] === 'string'
          ? { displaySubtitle: payload['displaySubtitle'] }
          : {}),
        ...(typeof payload['displayBadge'] === 'string'
          ? { displayBadge: payload['displayBadge'] }
          : {}),
        ...(typeof payload['unitPrice'] === 'number'
          ? { unitPrice: payload['unitPrice'] }
          : {}),
        ...(typeof payload['category'] === 'string' ? { kind: payload['category'] } : {}),
        ...(typeof payload['sku'] === 'string' ? { sku: payload['sku'] } : {}),
        ...(typeof payload['barcode'] === 'string' ? { barcode: payload['barcode'] } : {}),
        ...(typeof payload['externalCode'] === 'string'
          ? { externalCode: payload['externalCode'] }
          : {}),
        ...(typeof payload['displayOrder'] === 'number'
          ? { displayOrder: Math.max(0, Math.trunc(payload['displayOrder'])) }
          : {}),
        ...(typeof payload['isVisibleInApp'] === 'boolean'
          ? { isVisibleInApp: payload['isVisibleInApp'] }
          : {}),
        ...(typeof payload['isFeatured'] === 'boolean'
          ? { isFeatured: payload['isFeatured'] }
          : {}),
        ...(typeof payload['trackStock'] === 'boolean' ? { trackStock: payload['trackStock'] } : {}),
        ...(typeof payload['reorderLevel'] === 'number'
          ? { reorderLevel: Math.max(0, Math.trunc(payload['reorderLevel'])) }
          : {}),
        ...(typeof payload['isArchived'] === 'boolean' ? { isArchived: payload['isArchived'] } : {}),
        ...(payload['searchKeywords'] !== undefined
          ? { searchKeywords: this.toPayloadStringArray(payload['searchKeywords']) }
          : {}),
        ...(payload['legacyAliases'] !== undefined
          ? { legacyAliases: this.toPayloadStringArray(payload['legacyAliases']) }
          : {}),
        ...(resolvedCatalogSectionId
          ? { catalogSectionId: resolvedCatalogSectionId }
          : {}),
      },
    });

    return this.getVendorCatalog(existing.vendorId);
  }

  async listCatalogAdminEvents() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertAdminAccess(current);
    const events = await this.prisma.event.findMany({
      orderBy: [{ displayOrder: 'asc' }, { startsAt: 'asc' }],
    });
    return events.map((event) => this.toEventDetailPayload(event));
  }

  async updateCatalogEvent(
    eventId: string,
    payload: Record<string, unknown>,
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertAdminAccess(current);

    await this.prisma.event.update({
      where: { id: eventId },
      data: {
        ...(typeof payload['title'] === 'string' ? { title: payload['title'] } : {}),
        ...(typeof payload['venue'] === 'string' ? { venue: payload['venue'] } : {}),
        ...(typeof payload['district'] === 'string' ? { district: payload['district'] } : {}),
        ...(typeof payload['imageUrl'] === 'string' ? { imageUrl: payload['imageUrl'] } : {}),
        ...(typeof payload['description'] === 'string'
          ? { description: payload['description'] }
          : {}),
        ...(typeof payload['organizer'] === 'string' ? { organizer: payload['organizer'] } : {}),
        ...(typeof payload['primaryTag'] === 'string'
          ? { primaryTag: payload['primaryTag'] }
          : {}),
        ...(typeof payload['secondaryTag'] === 'string'
          ? { secondaryTag: payload['secondaryTag'] }
          : {}),
        ...(typeof payload['participantLabel'] === 'string'
          ? { participantLabel: payload['participantLabel'] }
          : {}),
        ...(typeof payload['ticketCategory'] === 'string'
          ? { ticketCategory: payload['ticketCategory'] }
          : {}),
        ...(typeof payload['locationTitle'] === 'string'
          ? { locationTitle: payload['locationTitle'] }
          : {}),
        ...(typeof payload['locationSubtitle'] === 'string'
          ? { locationSubtitle: payload['locationSubtitle'] }
          : {}),
        ...(typeof payload['pointsCost'] === 'number'
          ? { pointsCost: Math.max(0, Math.trunc(payload['pointsCost'])) }
          : {}),
        ...(typeof payload['capacity'] === 'number'
          ? { capacity: Math.max(0, Math.trunc(payload['capacity'])) }
          : {}),
        ...(typeof payload['remainingCount'] === 'number'
          ? { remainingCount: Math.max(0, Math.trunc(payload['remainingCount'])) }
          : {}),
        ...(typeof payload['isActive'] === 'boolean' ? { isActive: payload['isActive'] } : {}),
        ...(typeof payload['isFeatured'] === 'boolean'
          ? { isFeatured: payload['isFeatured'] }
          : {}),
      },
    });

    return this.getEventDetail(eventId);
  }

  async listCatalogContentBlocks(type?: PrismaContentBlockType) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertAdminAccess(current);
    const blocks = await this.prisma.contentBlock.findMany({
      where: {
        ...(type ? { type } : {}),
      },
      orderBy: [{ displayOrder: 'asc' }, { key: 'asc' }],
    });
    return blocks.map((block) => this.toContentBlockPayload(block));
  }

  async updateCatalogContentBlock(
    blockId: string,
    payload: Record<string, unknown>,
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertAdminAccess(current);

    await this.prisma.contentBlock.update({
      where: { id: blockId },
      data: {
        ...(typeof payload['title'] === 'string' ? { title: payload['title'] } : {}),
        ...(typeof payload['subtitle'] === 'string'
          ? { subtitle: payload['subtitle'] }
          : {}),
        ...(typeof payload['badge'] === 'string' ? { badge: payload['badge'] } : {}),
        ...(typeof payload['imageUrl'] === 'string' ? { imageUrl: payload['imageUrl'] } : {}),
        ...(typeof payload['actionLabel'] === 'string'
          ? { actionLabel: payload['actionLabel'] }
          : {}),
        ...(typeof payload['screen'] === 'string' ? { screen: payload['screen'] } : {}),
        ...(typeof payload['iconKey'] === 'string' ? { iconKey: payload['iconKey'] } : {}),
        ...(typeof payload['highlight'] === 'boolean'
          ? { highlight: payload['highlight'] }
          : {}),
        ...(typeof payload['displayOrder'] === 'number'
          ? { displayOrder: Math.max(0, Math.trunc(payload['displayOrder'])) }
          : {}),
        ...(typeof payload['isActive'] === 'boolean' ? { isActive: payload['isActive'] } : {}),
      },
    });

    return this.listCatalogContentBlocks();
  }

  async listOrders() {
    const current = await this.requireCurrentUser();
    const orders = await this.prisma.order.findMany({
      where: { userId: current.id },
      include: orderInclude,
      orderBy: { createdAt: 'desc' },
    });
    return orders.map((order) => this.toOrderPayload(order));
  }

  async listActiveOrders() {
    const orders = await this.listOrders();
    return orders.filter((order) => order.status === 'active');
  }

  async listHistoryOrders() {
    const orders = await this.listOrders();
    return orders.filter((order) => order.status !== 'active');
  }

  async getOrder(orderId: string) {
    const current = await this.requireCurrentUser();
    const order = await this.prisma.order.findFirst({
      where: {
        id: orderId,
        userId: current.id,
      },
      include: orderInclude,
    });
    if (!order) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    const payload = this.toOrderPayload(order);
    return {
      ...payload,
      timeline: [
        { code: 'CREATED', label: 'Sipariş alındı' },
        { code: 'PREPARING', label: 'Hazırlanıyor' },
        { code: 'READY', label: 'Gel-al noktasında hazır' },
        {
          code: payload.opsStatus,
          label: this.timelineLabelForStatus(payload.opsStatus),
        },
      ],
    };
  }

  createCheckoutSession(payload: CreateCheckoutSessionDto) {
    return {
      checkoutSessionId: `chk_${randomUUID()}`,
      fulfillmentMode: payload.fulfillmentMode,
      pickupPointId: payload.pickupPointId,
      paymentMethodToken: payload.paymentMethodToken,
      paymentMethodLabel: payload.paymentMethodLabel,
      amount: this.calculateCheckoutAmount(payload),
      currency: 'TRY',
      courierEnabled: false,
    };
  }

  async checkout(payload: CreateCheckoutSessionDto) {
    await this.ensureInitialized();
    if (payload.fulfillmentMode !== FulfillmentMode.PICKUP) {
      throw new BadRequestException('Only pickup fulfillment is supported');
    }

    const firstLine = payload.items[0];
    if (!firstLine) {
      throw new BadRequestException('At least one line item is required');
    }

    const current = await this.requireCurrentUser();
    let rewardPoints = Number((this.calculateCheckoutAmount(payload) * 0.01).toFixed(2));

    const order = await this.prisma.$transaction(async (tx) => {
      const resolvedItems = await Promise.all(
        payload.items.map((item) => this.resolveCheckoutLineItem(tx, item)),
      );
      const subtotal = this.calculateCheckoutAmountFromItems(resolvedItems);
      rewardPoints = Number((subtotal * 0.01).toFixed(2));
      const productIds = [...new Set(resolvedItems.map((item) => item.productId))];
      const stocks = await tx.inventoryStock.findMany({
        where: { productId: { in: productIds } },
        include: stockInclude,
      });
      const stockByProductId = new Map(stocks.map((stock) => [stock.productId, stock]));

      for (const line of resolvedItems) {
        const stock = stockByProductId.get(line.productId);
        if (!stock || !stock.product.trackStock) {
          continue;
        }
        const availableQuantity = this.availableQuantity({
          ...stock.product,
          onHand: stock.onHand,
          reserved: stock.reserved,
        });
        if (availableQuantity < line.quantity) {
          throw new BadRequestException(
            `Insufficient stock for ${stock.product.title}. Remaining ${availableQuantity}.`,
          );
        }
      }

      const firstResolvedLine = resolvedItems[0];
      const firstStock = firstResolvedLine
        ? stockByProductId.get(firstResolvedLine.productId)
        : undefined;
      if (!firstStock) {
        throw new NotFoundException(`Product ${firstLine.productId} not found`);
      }
      const pickupPoint = await this.resolveCheckoutPickupPoint(
        tx,
        firstStock.vendorId,
        payload.pickupPointId,
      );

      const paymentMethod =
        payload.paymentMethodToken
          ? await tx.paymentMethod.findFirst({
              where: {
                userId: current.id,
                OR: [
                  { id: payload.paymentMethodToken },
                  { providerToken: payload.paymentMethodToken },
                ],
              },
            })
          : await tx.paymentMethod.findFirst({
              where: { userId: current.id, isDefault: true },
            });

      const order = await tx.order.create({
        data: {
          userId: current.id,
          vendorId: firstStock.vendorId,
          pickupPointId: pickupPoint.id,
          fulfillmentMode: PrismaFulfillmentMode.PICKUP,
          status: PrismaOrderStatus.CREATED,
          pickupCode: this.createPickupCode(),
          etaLabel: '12 dk',
          subtotal,
          discountAmount: 0,
          totalAmount: subtotal,
          promoCode: payload.promoCode ?? '',
          paymentMethodId: paymentMethod?.id,
          items: {
            create: resolvedItems.map((item) => ({
              productId: item.productId,
              title: item.title ?? stockByProductId.get(item.productId)?.product.title ?? item.productId,
              quantity: item.quantity,
              unitPrice:
                item.unitPrice ?? Number(stockByProductId.get(item.productId)?.product.unitPrice ?? 90),
            })),
          },
        },
        include: orderInclude,
      });

      for (const line of resolvedItems) {
        const stock = stockByProductId.get(line.productId);
        if (!stock || !stock.product.trackStock) {
          continue;
        }
        await tx.inventoryStock.update({
          where: { id: stock.id },
          data: {
            reserved: stock.reserved + line.quantity,
          },
        });
        await tx.inventoryMovement.create({
          data: {
            productId: stock.productId,
            vendorId: stock.vendorId,
            type: PrismaInventoryMovementType.RESERVATION,
            quantityDelta: 0,
            previousOnHand: stock.onHand,
            nextOnHand: stock.onHand,
            previousReserved: stock.reserved,
            nextReserved: stock.reserved + line.quantity,
            orderId: order.id,
            note: 'Reserved for checkout',
          },
        });
      }

      await tx.walletLedgerEntry.create({
        data: {
          userId: current.id,
          delta: Math.round(rewardPoints),
          reason: 'Checkout reward',
          referenceId: order.id,
        },
      });

      return order;
    });

    return this.toOrderPayload(order);
  }

  async completeOrder(orderId: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, userId: true },
    });
    if (!order || order.userId !== current.id) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }
    return this.applyOrderStatusTransition(orderId, 'COMPLETED', {
      actor: current,
      skipOpsAccessCheck: true,
    });
  }

  async rateOrder(orderId: string, stars: number) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    if (!Number.isInteger(stars) || stars < 1 || stars > 5) {
      throw new BadRequestException('Rating must be between 1 and 5');
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, userId: true },
    });
    if (!order || order.userId !== current.id) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    return this.prisma.orderRating.upsert({
      where: {
        userId_orderId: {
          userId: current.id,
          orderId,
        },
      },
      update: { stars },
      create: {
        userId: current.id,
        orderId,
        stars,
      },
      select: {
        orderId: true,
        stars: true,
      },
    });
  }

  async getWallet() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const [entries, tickets, preferences] = await Promise.all([
      this.prisma.walletLedgerEntry.findMany({
        where: { userId: current.id },
      }),
      this.prisma.ticket.findMany({
        where: { userId: current.id },
        include: ticketInclude,
        orderBy: { createdAt: 'desc' },
      }),
      this.getPreferencePayload(current.id),
    ]);

    return {
      balance: entries.reduce((sum, entry) => sum + entry.delta, 0),
      ownedTickets: tickets.map((ticket) => this.toEventTicket(ticket)),
      ...preferences,
    };
  }

  async redeemEventTicket(eventId: string, payload?: RedeemTicketDto) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const ticket = await this.prisma.$transaction(async (tx) => {
      const event = await tx.event.findUnique({
        where: { id: eventId },
      });
      if (!event) {
        throw new NotFoundException(`Event ${eventId} not found`);
      }
      if (event.remainingCount <= 0) {
        throw new BadRequestException('Event sold out');
      }

      const entries = await tx.walletLedgerEntry.findMany({
        where: { userId: current.id },
        select: { delta: true },
      });
      const balance = entries.reduce((sum, entry) => sum + entry.delta, 0);
      if (balance < event.pointsCost) {
        throw new BadRequestException('Insufficient Speto Pro balance');
      }

      await tx.walletLedgerEntry.create({
        data: {
          userId: current.id,
          delta: -event.pointsCost,
          reason: 'Event ticket redemption',
          referenceId: event.id,
        },
      });

      await tx.event.update({
        where: { id: event.id },
        data: {
          remainingCount: event.remainingCount - 1,
        },
      });

      return tx.ticket.create({
        data: {
          userId: current.id,
          eventId: event.id,
          qrCode: `QR-${randomUUID().slice(0, 8).toUpperCase()}`,
          zone: payload?.zone ?? 'VIP',
          seat: payload?.seat ?? 'A12',
          gate: payload?.gate ?? 'G3',
        },
        include: ticketInclude,
      });
    });

    return this.toEventTicket(ticket);
  }

  async listTickets() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const tickets = await this.prisma.ticket.findMany({
      where: { userId: current.id },
      include: ticketInclude,
      orderBy: { createdAt: 'desc' },
    });
    return tickets.map((ticket) => this.toEventTicket(ticket));
  }

  async listSupportTickets() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const tickets = await this.prisma.supportTicket.findMany({
      where: { userId: current.id },
      orderBy: { createdAt: 'desc' },
    });
    return tickets.map((ticket) => this.toSupportTicket(ticket));
  }

  async createSupportTicket(payload: CreateSupportTicketDto) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const ticket = await this.prisma.supportTicket.create({
      data: {
        userId: current.id,
        subject: payload.subject,
        message: payload.message,
        channel: payload.channel,
        status: PrismaSupportStatus.OPEN,
      },
    });
    return this.toSupportTicket(ticket);
  }

  async getSnapshot() {
    const [
      profile,
      addresses,
      paymentMethods,
      activeOrders,
      historyOrders,
      supportTickets,
      wallet,
    ] = await Promise.all([
      this.getProfile(),
      this.listAddresses(),
      this.listPaymentMethods(),
      this.listActiveOrders(),
      this.listHistoryOrders(),
      this.listSupportTickets(),
      this.getWallet(),
    ]);

    return {
      profile,
      addresses,
      paymentMethods,
      activeOrders,
      historyOrders,
      supportTickets,
      wallet,
      capabilities: this.getCapabilities(),
    };
  }

  async getInventoryDashboard(vendorId?: string, query?: string): Promise<InventoryDashboard> {
    await this.ensureInitialized();
    const items = await this.queryInventoryItems(vendorId, query, true);
    const allVisibleItems = await this.queryInventoryItems(vendorId, undefined, true);
    const openOrdersCount = (await this.listOpsOrders(vendorId)).filter(
      (order) => order.status === 'active',
    ).length;
    const integrations = await this.listIntegrations(vendorId);

    return {
      items,
      totalItems: allVisibleItems.length,
      lowStockCount: allVisibleItems.filter((item) => item.stockStatus.lowStock).length,
      outOfStockCount: allVisibleItems.filter((item) => !item.stockStatus.isInStock).length,
      openOrdersCount,
      integrationErrorCount: integrations.filter(
        (connection) => connection.health === 'failed',
      ).length,
      pendingSyncCount: integrations.filter(
        (connection) => connection.lastSync.status === 'running',
      ).length,
      totalAvailableUnits: allVisibleItems.reduce(
        (sum, item) => sum + item.stockStatus.availableQuantity,
        0,
      ),
    };
  }

  async listInventoryItems(vendorId?: string, query?: string) {
    return this.queryInventoryItems(vendorId, query, true);
  }

  async getInventoryItem(itemId: string) {
    await this.ensureInitialized();
    const stock = await this.prisma.inventoryStock.findFirst({
      where: { productId: itemId },
      include: stockInclude,
    });
    if (!stock) {
      throw new NotFoundException(`Inventory item ${itemId} not found`);
    }
    return this.toInventoryItemPayload(stock);
  }

  async adjustInventory(itemId: string, quantityDelta: number, reason: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const stock = await this.requireInventoryStock(itemId);
    this.assertVendorAccess(current, stock.vendorId);

    const nextOnHand = stock.onHand + quantityDelta;
    if (nextOnHand < stock.reserved) {
      throw new BadRequestException('Cannot reduce stock below reserved quantity');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.inventoryStock.update({
        where: { id: stock.id },
        data: { onHand: nextOnHand },
      });
      await tx.inventoryMovement.create({
        data: {
          productId: stock.productId,
          vendorId: stock.vendorId,
          type: PrismaInventoryMovementType.MANUAL_ADJUSTMENT,
          quantityDelta: quantityDelta,
          previousOnHand: stock.onHand,
          nextOnHand,
          previousReserved: stock.reserved,
          nextReserved: stock.reserved,
          note: reason,
        },
      });
    });

    return this.getInventoryItem(itemId);
  }

  async restockInventory(itemId: string, quantity: number, note: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    if (quantity <= 0) {
      throw new BadRequestException('Restock quantity must be positive');
    }

    const stock = await this.requireInventoryStock(itemId);
    this.assertVendorAccess(current, stock.vendorId);
    const nextOnHand = stock.onHand + quantity;

    await this.prisma.$transaction(async (tx) => {
      await tx.inventoryStock.update({
        where: { id: stock.id },
        data: { onHand: nextOnHand },
      });
      await tx.inventoryMovement.create({
        data: {
          productId: stock.productId,
          vendorId: stock.vendorId,
          type: PrismaInventoryMovementType.RESTOCK,
          quantityDelta: quantity,
          previousOnHand: stock.onHand,
          nextOnHand,
          previousReserved: stock.reserved,
          nextReserved: stock.reserved,
          note,
        },
      });
    });

    return this.getInventoryItem(itemId);
  }

  async listInventoryMovements(vendorId?: string, productId?: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const allowedVendorIds = await this.resolveVendorScope(current, vendorId);
    const movements = await this.prisma.inventoryMovement.findMany({
      where: {
        vendorId: { in: allowedVendorIds },
        ...(productId ? { productId } : {}),
      },
      include: movementInclude,
      orderBy: { createdAt: 'desc' },
    });
    return movements.map((movement) => this.toInventoryMovement(movement));
  }

  async listOpsOrders(vendorId?: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const allowedVendorIds = await this.resolveVendorScope(current, vendorId);
    const orders = await this.prisma.order.findMany({
      where: {
        vendorId: { in: allowedVendorIds },
      },
      include: orderInclude,
      orderBy: { createdAt: 'desc' },
    });
    return orders.map((order) => this.toOrderPayload(order));
  }

  async updateOrderStatus(orderId: string, status: OpsOrderStatus) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    return this.applyOrderStatusTransition(orderId, status, {
      actor: current,
      skipOpsAccessCheck: false,
    });
  }

  async listIntegrations(vendorId?: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const allowedVendorIds = await this.resolveVendorScope(current, vendorId);
    const connections = await this.prisma.integrationConnection.findMany({
      where: {
        vendorId: { in: allowedVendorIds },
      },
      include: integrationInclude,
      orderBy: { updatedAt: 'desc' },
    });
    return connections.map((connection) => this.toIntegrationPayload(connection));
  }

  async createIntegration(payload: {
    vendorId: string;
    name: string;
    provider: string;
    type: IntegrationType;
    baseUrl: string;
    locationId: string;
    skuMappings: Record<string, string>;
  }) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);
    this.assertVendorAccess(current, payload.vendorId);

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: payload.vendorId },
    });
    if (!vendor) {
      throw new NotFoundException(`Vendor ${payload.vendorId} not found`);
    }

    const connection = await this.prisma.integrationConnection.create({
      data: {
        vendorId: payload.vendorId,
        name: payload.name,
        provider: payload.provider,
        type: payload.type === 'ERP' ? PrismaIntegrationType.ERP : PrismaIntegrationType.POS,
        baseUrl: payload.baseUrl,
        locationId: payload.locationId,
        health:
          payload.type === 'ERP'
            ? PrismaIntegrationHealth.WARNING
            : PrismaIntegrationHealth.HEALTHY,
        skuMappings: payload.skuMappings,
      },
      include: integrationInclude,
    });

    return this.toIntegrationPayload(connection);
  }

  async syncIntegration(connectionId: string) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const connection = await this.requireIntegration(connectionId);
    this.assertVendorAccess(current, connection.vendorId);
    const mappings = this.toSkuMappings(connection.skuMappings);
    const startedAt = new Date();

    const result = await this.prisma.$transaction(async (tx) => {
      let processedCount = 0;
      for (const [externalCode, internalSku] of Object.entries(mappings)) {
        const stock = await tx.inventoryStock.findFirst({
          where: {
            vendorId: connection.vendorId,
            product: { sku: internalSku },
          },
          include: stockInclude,
        });
        if (!stock) {
          continue;
        }

        const nextOnHand = stock.onHand + 2;
        await tx.inventoryStock.update({
          where: { id: stock.id },
          data: { onHand: nextOnHand },
        });
        await tx.inventoryMovement.create({
          data: {
            productId: stock.productId,
            vendorId: stock.vendorId,
            type: PrismaInventoryMovementType.POS_SYNC,
            quantityDelta: 2,
            previousOnHand: stock.onHand,
            nextOnHand,
            previousReserved: stock.reserved,
            nextReserved: stock.reserved,
            note: `Sync ${externalCode} -> ${internalSku}`,
          },
        });
        processedCount += 1;
      }

      const run = await tx.integrationSyncRun.create({
        data: {
          connectionId: connection.id,
          status: PrismaSyncRunStatus.SUCCESS,
          processedCount,
          startedAt,
          completedAt: new Date(),
        },
      });
      await tx.integrationConnection.update({
        where: { id: connection.id },
        data: { health: PrismaIntegrationHealth.HEALTHY },
      });
      return run;
    });

    return this.toSyncRunPayload(result, connectionId);
  }

  async receiveIntegrationWebhook(
    connectionId: string,
    payload: { records: Array<{ sku: string; quantity: number }> },
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    this.assertOpsAccess(current);

    const connection = await this.requireIntegration(connectionId);
    this.assertVendorAccess(current, connection.vendorId);
    const mappings = this.toSkuMappings(connection.skuMappings);
    const startedAt = new Date();

    const result = await this.prisma.$transaction(async (tx) => {
      let processedCount = 0;

      for (const record of payload.records) {
        const internalSku = mappings[record.sku] ?? record.sku;
        const stock = await tx.inventoryStock.findFirst({
          where: {
            vendorId: connection.vendorId,
            product: { sku: internalSku },
          },
          include: stockInclude,
        });
        if (!stock) {
          continue;
        }

        const nextOnHand = Math.max(record.quantity, stock.reserved);
        await tx.inventoryStock.update({
          where: { id: stock.id },
          data: { onHand: nextOnHand },
        });
        await tx.inventoryMovement.create({
          data: {
            productId: stock.productId,
            vendorId: stock.vendorId,
            type: PrismaInventoryMovementType.POS_SYNC,
            quantityDelta: nextOnHand - stock.onHand,
            previousOnHand: stock.onHand,
            nextOnHand,
            previousReserved: stock.reserved,
            nextReserved: stock.reserved,
            note:
              nextOnHand !== record.quantity
                ? `Webhook sync for ${record.sku} (clamped to reserved)`
                : `Webhook sync for ${record.sku}`,
          },
        });
        processedCount += 1;
      }

      const run = await tx.integrationSyncRun.create({
        data: {
          connectionId: connection.id,
          status: PrismaSyncRunStatus.SUCCESS,
          processedCount,
          startedAt,
          completedAt: new Date(),
        },
      });
      await tx.integrationConnection.update({
        where: { id: connection.id },
        data: { health: PrismaIntegrationHealth.HEALTHY },
      });
      return run;
    });

    return this.toSyncRunPayload(result, connectionId);
  }

  private async ensureInitialized() {
    if (this.initializationPromise) {
      return this.initializationPromise;
    }

    this.initializationPromise = this.seedDemoDataIfNeeded();
    try {
      await this.initializationPromise;
    } catch (error) {
      this.initializationPromise = null;
      throw error;
    }
  }

  private async seedDemoDataIfNeeded() {
    await this.prisma.$transaction(
      async (tx) => {
        await this.syncCatalogManifestSeed(tx);

        for (const user of DEMO_USERS) {
          await tx.user.upsert({
            where: { id: user.id },
            update: {
              email: user.email,
              password: user.password,
              displayName: user.displayName,
              phone: user.phone,
              role: user.role,
              vendorId: user.vendorId,
              studentVerifiedAt: user.studentVerifiedAt,
              notificationsEnabled: user.notificationsEnabled,
              avatarUrl: user.avatarUrl,
            },
            create: {
              id: user.id,
              email: user.email,
              password: user.password,
              displayName: user.displayName,
              phone: user.phone,
              role: user.role,
              vendorId: user.vendorId,
              studentVerifiedAt: user.studentVerifiedAt,
              notificationsEnabled: user.notificationsEnabled,
              avatarUrl: user.avatarUrl,
            },
          });
        }

        await this.ensureVendorOperatorAccounts(tx);

        for (const address of DEMO_ADDRESSES) {
          await tx.savedPlace.upsert({
            where: { id: address.id },
            update: {
              userId: address.userId,
              label: address.label,
              address: address.address,
              iconKey: address.iconKey,
              isPrimary: address.isPrimary,
            },
            create: { ...address },
          });
        }

        for (const method of DEMO_PAYMENT_METHODS) {
          await tx.paymentMethod.upsert({
            where: { id: method.id },
            update: { ...method },
            create: { ...method },
          });
        }

        for (const entry of DEMO_WALLET_ENTRIES) {
          await tx.walletLedgerEntry.upsert({
            where: { id: entry.id },
            update: { ...entry },
            create: { ...entry },
          });
        }

        for (const ticket of DEMO_SUPPORT_TICKETS) {
          await tx.supportTicket.upsert({
            where: { id: ticket.id },
            update: { ...ticket },
            create: { ...ticket },
          });
        }

        await tx.order.deleteMany({
          where: { id: { in: DEMO_ORDERS.map((order) => order.id) } },
        });

        for (const order of DEMO_ORDERS) {
          await tx.order.create({
            data: {
              id: order.id,
              userId: order.userId,
              vendorId: order.vendorId,
              pickupPointId: order.pickupPointId,
              fulfillmentMode: PrismaFulfillmentMode.PICKUP,
              status: order.status,
              pickupCode: order.pickupCode,
              etaLabel: order.etaLabel,
              subtotal: order.subtotal,
              discountAmount: order.discountAmount,
              totalAmount: order.totalAmount,
              promoCode: order.promoCode,
              paymentMethodId: order.paymentMethodId,
              createdAt: order.createdAt,
              updatedAt: order.createdAt,
              items: {
                create: order.items.map((item) => ({
                  id: item.id,
                  productId: item.productId,
                  title: item.title,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                })),
              },
            },
          });
        }

      const burgerSkus = await tx.product.findMany({
        where: {
          vendorId: 'vendor-burger-yiyelim',
          catalogSectionId: { not: null },
          isVisibleInApp: true,
        },
        orderBy: { displayOrder: 'asc' },
        select: { sku: true, externalCode: true },
        take: 3,
      });
      const migrosSkus = await tx.product.findMany({
        where: {
          vendorId: 'vendor-migros-jet',
          catalogSectionId: { not: null },
          isVisibleInApp: true,
        },
        orderBy: { displayOrder: 'asc' },
        select: { sku: true, externalCode: true },
        take: 4,
      });

      const integrations = [
        {
          id: 'int-burger-001',
          vendorId: 'vendor-burger-yiyelim',
          name: 'Burger POS Bridge',
          provider: 'Nebim POS',
          type: PrismaIntegrationType.POS,
          baseUrl: 'https://pos.burgeryiyelim.local',
          locationId: 'loc-burger-yiyelim-pickup',
          health: PrismaIntegrationHealth.HEALTHY,
          skuMappings: Object.fromEntries(
            burgerSkus.map((item) => [item.externalCode ?? item.sku, item.sku]),
          ),
          syncStatus: PrismaSyncRunStatus.SUCCESS,
          processedCount: burgerSkus.length,
          errorMessage: null as string | null,
        },
        {
          id: 'int-market-001',
          vendorId: 'vendor-migros-jet',
          name: 'Migros Jet ERP Feed',
          provider: 'Logo ERP',
          type: PrismaIntegrationType.ERP,
          baseUrl: 'https://erp.migrosjet.local',
          locationId: 'loc-migros-jet-pickup',
          health: PrismaIntegrationHealth.WARNING,
          skuMappings: Object.fromEntries(
            migrosSkus.map((item) => [item.externalCode ?? item.sku, item.sku]),
          ),
          syncStatus: PrismaSyncRunStatus.FAILED,
          processedCount: Math.max(1, migrosSkus.length - 1),
          errorMessage: 'Timeout during cold storage feed sync',
        },
      ];

      for (const integration of integrations) {
        await tx.integrationConnection.upsert({
          where: { id: integration.id },
          update: {
            vendorId: integration.vendorId,
            name: integration.name,
            provider: integration.provider,
            type: integration.type,
            baseUrl: integration.baseUrl,
            locationId: integration.locationId,
            health: integration.health,
            skuMappings: integration.skuMappings,
          },
          create: {
            id: integration.id,
            vendorId: integration.vendorId,
            name: integration.name,
            provider: integration.provider,
            type: integration.type,
            baseUrl: integration.baseUrl,
            locationId: integration.locationId,
            health: integration.health,
            skuMappings: integration.skuMappings,
          },
        });

        await tx.integrationSyncRun.upsert({
          where: { id: `sync-${integration.id}` },
          update: {
            connectionId: integration.id,
            status: integration.syncStatus,
            processedCount: integration.processedCount,
            errorMessage: integration.errorMessage,
            startedAt: new Date('2026-04-09T10:45:00+03:00'),
            completedAt: new Date('2026-04-09T10:46:00+03:00'),
          },
          create: {
            id: `sync-${integration.id}`,
            connectionId: integration.id,
            status: integration.syncStatus,
            processedCount: integration.processedCount,
            errorMessage: integration.errorMessage,
            startedAt: new Date('2026-04-09T10:45:00+03:00'),
            completedAt: new Date('2026-04-09T10:46:00+03:00'),
          },
        });
      }
      },
      {
        maxWait: 30_000,
        timeout: 30_000,
      },
    );
  }

  private async syncCatalogManifestSeed(tx: Prisma.TransactionClient) {
    const manifest = loadCatalogManifest();
    const storefrontVendors = [
      ...manifest.restaurants.map((restaurant) => ({
        id: restaurant.vendorId,
        storefrontId: restaurant.id,
        storefrontType: PrismaStorefrontType.RESTAURANT,
        name: restaurant.title,
        slug: restaurant.vendorId.replace('vendor-', ''),
        category: restaurant.cuisine,
        subtitle: `${restaurant.cuisine} • Gel-Al`,
        metaLabel: `${restaurant.cuisine} • ${restaurant.etaMin}-${restaurant.etaMax} dk hazır`,
        imageUrl: restaurant.image,
        badge: restaurant.promo,
        rewardLabel: 'Gel-Al',
        promoLabel: restaurant.promo,
        ratingValue: restaurant.ratingValue,
        distanceLabel: '1.2 km',
        etaMin: restaurant.etaMin,
        etaMax: restaurant.etaMax,
        workingHoursLabel: '10:00-23:00',
        reviewCountLabel: `${120 + restaurant.displayOrder * 12}`,
        announcement: `${restaurant.title} siparişleri hazır olduğunda uygulamada bildirilir.`,
        bundleTitle: '',
        bundleDescription: '',
        bundlePrice: '',
        heroTitle: `${restaurant.title} ile hızlı gel-al menüleri`,
        heroSubtitle: `${restaurant.cuisine} seçkisi öğrenci dostu fiyatlarla hızlı hazırlanır.`,
        displayOrder: restaurant.displayOrder,
        studentFriendly: restaurant.studentFriendly,
        isFeatured: restaurant.displayOrder <= 4,
        isActive: true,
        pickupPointId: `pickup-${restaurant.vendorId.replace('vendor-', '')}`,
      })),
      ...manifest.markets.map((market) => ({
        id: market.vendorId,
        storefrontId: market.id,
        storefrontType: PrismaStorefrontType.MARKET,
        name: market.title,
        slug: market.vendorId.replace('vendor-', ''),
        category: 'Market',
        subtitle: market.subtitle,
        metaLabel: market.meta,
        imageUrl: market.image,
        badge: market.badge,
        rewardLabel: market.rewardLabel,
        promoLabel: market.promoLabel,
        ratingValue: Number.parseFloat(market.ratingLabel),
        distanceLabel: market.distanceLabel,
        etaMin: this.parseLeadingInt(market.etaLabel),
        etaMax: this.parseLeadingInt(market.etaLabel),
        workingHoursLabel: market.workingHoursLabel,
        reviewCountLabel: market.reviewCountLabel,
        announcement: market.announcement,
        bundleTitle: market.bundleTitle,
        bundleDescription: market.bundleDescription,
        bundlePrice: market.bundlePrice,
        heroTitle: market.heroTitle,
        heroSubtitle: market.heroSubtitle,
        displayOrder: market.displayOrder + 100,
        studentFriendly: true,
        isFeatured: market.displayOrder <= 4,
        isActive: true,
        pickupPointId: `pickup-${market.id}`,
      })),
    ];
    const eventVendor = {
      id: 'vendor-events-hub',
      storefrontId: null,
      storefrontType: null,
      name: 'Speto Events Hub',
      slug: 'events-hub',
      category: 'Events',
      subtitle: 'Etkinlik deneyimleri',
      metaLabel: 'Speto etkinlik seçkisi',
      imageUrl:
        manifest.events[0]?.image ??
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
      badge: 'Events',
      rewardLabel: 'Pro',
      promoLabel: 'Etkinlik',
      ratingValue: 5,
      distanceLabel: 'İstanbul',
      etaMin: null,
      etaMax: null,
      workingHoursLabel: 'Etkinlik takvimine göre',
      reviewCountLabel: '',
      announcement: 'Speto etkinlik biletleri puanla açılır.',
      bundleTitle: '',
      bundleDescription: '',
      bundlePrice: '',
      heroTitle: 'Şehirde deneyim zamanı',
      heroSubtitle: 'Konser, tiyatro ve atölye seçkisi',
      displayOrder: 999,
      studentFriendly: true,
      isFeatured: false,
      isActive: false,
      pickupPointId: null as string | null,
    };

    for (const vendor of [...storefrontVendors, eventVendor]) {
      await tx.vendor.upsert({
        where: { id: vendor.id },
        update: {
          name: vendor.name,
          slug: vendor.slug,
          category: vendor.category,
          storefrontId: vendor.storefrontId,
          storefrontType: vendor.storefrontType,
          subtitle: vendor.subtitle,
          metaLabel: vendor.metaLabel,
          imageUrl: vendor.imageUrl,
          badge: vendor.badge,
          rewardLabel: vendor.rewardLabel,
          promoLabel: vendor.promoLabel,
          ratingValue: vendor.ratingValue,
          distanceLabel: vendor.distanceLabel,
          etaMin: vendor.etaMin,
          etaMax: vendor.etaMax,
          workingHoursLabel: vendor.workingHoursLabel,
          reviewCountLabel: vendor.reviewCountLabel,
          announcement: vendor.announcement,
          bundleTitle: vendor.bundleTitle,
          bundleDescription: vendor.bundleDescription,
          bundlePrice: vendor.bundlePrice,
          heroTitle: vendor.heroTitle,
          heroSubtitle: vendor.heroSubtitle,
          displayOrder: vendor.displayOrder,
          studentFriendly: vendor.studentFriendly,
          isFeatured: vendor.isFeatured,
          isActive: vendor.isActive,
        },
        create: {
          id: vendor.id,
          name: vendor.name,
          slug: vendor.slug,
          category: vendor.category,
          storefrontId: vendor.storefrontId,
          storefrontType: vendor.storefrontType,
          subtitle: vendor.subtitle,
          metaLabel: vendor.metaLabel,
          imageUrl: vendor.imageUrl,
          badge: vendor.badge,
          rewardLabel: vendor.rewardLabel,
          promoLabel: vendor.promoLabel,
          ratingValue: vendor.ratingValue,
          distanceLabel: vendor.distanceLabel,
          etaMin: vendor.etaMin,
          etaMax: vendor.etaMax,
          workingHoursLabel: vendor.workingHoursLabel,
          reviewCountLabel: vendor.reviewCountLabel,
          announcement: vendor.announcement,
          bundleTitle: vendor.bundleTitle,
          bundleDescription: vendor.bundleDescription,
          bundlePrice: vendor.bundlePrice,
          heroTitle: vendor.heroTitle,
          heroSubtitle: vendor.heroSubtitle,
          displayOrder: vendor.displayOrder,
          studentFriendly: vendor.studentFriendly,
          isFeatured: vendor.isFeatured,
          isActive: vendor.isActive,
        },
      });

      if (vendor.pickupPointId) {
        await tx.pickupPoint.upsert({
          where: { id: vendor.pickupPointId },
          update: {
            vendorId: vendor.id,
            label: `${vendor.name} Gel-Al Noktası`,
            address: `${vendor.name} Gel-Al Noktası`,
            isActive: true,
          },
          create: {
            id: vendor.pickupPointId,
            vendorId: vendor.id,
            label: `${vendor.name} Gel-Al Noktası`,
            address: `${vendor.name} Gel-Al Noktası`,
            isActive: true,
          },
        });
      }
    }

    const activeVendorIds = [...storefrontVendors.map((vendor) => vendor.id), eventVendor.id];
    await tx.vendor.updateMany({
      where: {
        id: { notIn: activeVendorIds },
        category: { in: ['Market', 'Restaurant'] },
      },
      data: { isActive: false },
    });

    for (const hero of manifest.home.heroes) {
      await tx.contentBlock.upsert({
        where: { key: hero.id },
        update: {
          type: PrismaContentBlockType.HOME_HERO,
          title: hero.title,
          subtitle: hero.subtitle,
          badge: hero.badge,
          imageUrl: hero.image,
          actionLabel: hero.actionLabel,
          screen: hero.screen,
          iconKey: null,
          highlight: false,
          displayOrder: hero.displayOrder,
          isActive: true,
          payload: {},
        },
        create: {
          id: hero.id,
          key: hero.id,
          type: PrismaContentBlockType.HOME_HERO,
          title: hero.title,
          subtitle: hero.subtitle,
          badge: hero.badge,
          imageUrl: hero.image,
          actionLabel: hero.actionLabel,
          screen: hero.screen,
          highlight: false,
          displayOrder: hero.displayOrder,
          isActive: true,
          payload: {},
        },
      });
    }

    for (const filter of manifest.home.quickFilters) {
      await tx.contentBlock.upsert({
        where: { key: filter.id },
        update: {
          type: PrismaContentBlockType.QUICK_FILTER,
          title: filter.label,
          subtitle: '',
          badge: null,
          imageUrl: null,
          actionLabel: null,
          screen: filter.screen,
          iconKey: filter.icon,
          highlight: filter.highlight,
          displayOrder: filter.displayOrder,
          isActive: true,
          payload: {},
        },
        create: {
          id: filter.id,
          key: filter.id,
          type: PrismaContentBlockType.QUICK_FILTER,
          title: filter.label,
          screen: filter.screen,
          iconKey: filter.icon,
          highlight: filter.highlight,
          displayOrder: filter.displayOrder,
          isActive: true,
          payload: {},
        },
      });
    }

    for (const filter of manifest.home.discoveryFilters) {
      await tx.contentBlock.upsert({
        where: { key: filter.id },
        update: {
          type: PrismaContentBlockType.DISCOVERY_FILTER,
          title: filter.label,
          subtitle: '',
          badge: null,
          imageUrl: null,
          actionLabel: null,
          screen: null,
          iconKey: null,
          highlight: false,
          displayOrder: filter.displayOrder,
          isActive: true,
          payload: {},
        },
        create: {
          id: filter.id,
          key: filter.id,
          type: PrismaContentBlockType.DISCOVERY_FILTER,
          title: filter.label,
          displayOrder: filter.displayOrder,
          isActive: true,
          payload: {},
        },
      });
    }

    for (const vendor of manifest.markets) {
      await tx.vendorHighlight.deleteMany({
        where: { vendorId: vendor.vendorId },
      });
      for (const highlight of vendor.highlights) {
        await tx.vendorHighlight.create({
          data: {
            id: highlight.id,
            vendorId: vendor.vendorId,
            label: highlight.label,
            iconKey: highlight.icon,
            displayOrder: highlight.displayOrder,
          },
        });
      }
    }

    for (const vendor of [...manifest.restaurants, ...manifest.markets]) {
      const locationId = this.seedLocationIdForVendor(vendor.vendorId);
      const locationLabel = `${vendor.title} Ön Tezgah`;
      for (const section of vendor.sections) {
        await tx.catalogSection.upsert({
          where: { id: section.id },
          update: {
            vendorId: vendor.vendorId,
            key: section.key,
            label: section.label,
            displayOrder: section.displayOrder,
            isActive: true,
          },
          create: {
            id: section.id,
            vendorId: vendor.vendorId,
            key: section.key,
            label: section.label,
            displayOrder: section.displayOrder,
            isActive: true,
          },
        });

        for (const product of section.products) {
          const sku = this.seedSkuForProduct(product.id);
          const externalCode = this.seedExternalCodeForProduct(product.id);
          const reorderLevel = this.seedReorderLevelForProduct(product.id);
          await tx.product.upsert({
            where: { id: product.id },
            update: {
              vendorId: vendor.vendorId,
              catalogSectionId: section.id,
              title: product.title,
              description: product.description,
              unitPrice: product.unitPrice,
              imageUrl: product.image,
              kind: section.label,
              sku,
              barcode: this.seedBarcodeForProduct(product.id),
              externalCode,
              displaySubtitle: product.description,
              displayBadge: section.label === 'Popüler' ? 'Popüler' : null,
              displayOrder: product.displayOrder,
              isFeatured: section.label === 'Popüler',
              isVisibleInApp: true,
              searchKeywords: [product.title, section.label, vendor.title],
              legacyAliases:
                vendor.vendorId.startsWith('vendor-restaurant')
                  ? []
                  : this.seedLegacyAliases(product.id, product.title, vendor.id),
              trackStock: true,
              reorderLevel,
              isArchived: false,
              isActive: true,
            },
            create: {
              id: product.id,
              vendorId: vendor.vendorId,
              catalogSectionId: section.id,
              title: product.title,
              description: product.description,
              unitPrice: product.unitPrice,
              imageUrl: product.image,
              kind: section.label,
              sku,
              barcode: this.seedBarcodeForProduct(product.id),
              externalCode,
              displaySubtitle: product.description,
              displayBadge: section.label === 'Popüler' ? 'Popüler' : null,
              displayOrder: product.displayOrder,
              isFeatured: section.label === 'Popüler',
              isVisibleInApp: true,
              searchKeywords: [product.title, section.label, vendor.title],
              legacyAliases: this.seedLegacyAliases(product.id, product.title, vendor.id),
              trackStock: true,
              reorderLevel,
              isArchived: false,
              isActive: true,
            },
          });

          const onHand = this.seedStockLevelForProduct(product.id);
          await tx.inventoryStock.upsert({
            where: {
              productId_locationId: {
                productId: product.id,
                locationId,
              },
            },
            update: {
              vendorId: vendor.vendorId,
              locationLabel,
              onHand,
              reserved: 0,
            },
            create: {
              productId: product.id,
              vendorId: vendor.vendorId,
              locationId,
              locationLabel,
              onHand,
              reserved: 0,
            },
          });

          await tx.inventoryMovement.upsert({
            where: { id: `mv_seed_${product.id}` },
            update: {
              productId: product.id,
              vendorId: vendor.vendorId,
              type: PrismaInventoryMovementType.RESTOCK,
              quantityDelta: onHand,
              previousOnHand: 0,
              nextOnHand: onHand,
              previousReserved: 0,
              nextReserved: 0,
              note: 'Initial manifest stock',
            },
            create: {
              id: `mv_seed_${product.id}`,
              productId: product.id,
              vendorId: vendor.vendorId,
              type: PrismaInventoryMovementType.RESTOCK,
              quantityDelta: onHand,
              previousOnHand: 0,
              nextOnHand: onHand,
              previousReserved: 0,
              nextReserved: 0,
              note: 'Initial manifest stock',
            },
          });
        }
      }
    }

    for (const event of manifest.events) {
      await tx.event.upsert({
        where: { id: event.id },
        update: {
          vendorId: eventVendor.id,
          title: event.title,
          venue: event.venue,
          district: event.district,
          imageUrl: event.image,
          startsAt: this.parseManifestEventDate(event.dateLabel, event.timeLabel),
          pointsCost: event.pointsCost,
          capacity: Math.max(120, event.pointsCost),
          remainingCount: Math.max(24, Math.floor(Math.max(120, event.pointsCost) * 0.65)),
          primaryTag: event.primaryTag,
          secondaryTag: event.secondaryTag,
          description: event.description,
          organizer: event.organizer,
          participantLabel: event.participantLabel,
          ticketCategory: event.ticketCategory,
          locationTitle: event.locationTitle,
          locationSubtitle: event.locationSubtitle,
          displayOrder: event.displayOrder,
          isFeatured: event.displayOrder <= 4,
          isActive: true,
        },
        create: {
          id: event.id,
          vendorId: eventVendor.id,
          title: event.title,
          venue: event.venue,
          district: event.district,
          imageUrl: event.image,
          startsAt: this.parseManifestEventDate(event.dateLabel, event.timeLabel),
          pointsCost: event.pointsCost,
          capacity: Math.max(120, event.pointsCost),
          remainingCount: Math.max(24, Math.floor(Math.max(120, event.pointsCost) * 0.65)),
          primaryTag: event.primaryTag,
          secondaryTag: event.secondaryTag,
          description: event.description,
          organizer: event.organizer,
          participantLabel: event.participantLabel,
          ticketCategory: event.ticketCategory,
          locationTitle: event.locationTitle,
          locationSubtitle: event.locationSubtitle,
          displayOrder: event.displayOrder,
          isFeatured: event.displayOrder <= 4,
          isActive: true,
        },
      });
    }
  }

  private seedLocationIdForVendor(vendorId: string) {
    return `loc-${vendorId.replace('vendor-', '')}-pickup`;
  }

  private seedSkuForProduct(productId: string) {
    return `SKU-${productId.replace(/[^a-zA-Z0-9]+/g, '-').toUpperCase()}`;
  }

  private seedExternalCodeForProduct(productId: string) {
    return `EXT-${productId.replace(/[^a-zA-Z0-9]+/g, '-').toUpperCase()}`;
  }

  private seedBarcodeForProduct(productId: string) {
    const checksum = productId
      .split('')
      .reduce((sum, character) => sum + character.charCodeAt(0), 0)
      .toString()
      .padStart(13, '0');
    return checksum.slice(-13);
  }

  private seedReorderLevelForProduct(productId: string) {
    return 4 + (productId.length % 4);
  }

  private seedStockLevelForProduct(productId: string) {
    const checksum = productId
      .split('')
      .reduce((sum, character) => sum + character.charCodeAt(0), 0);
    if (checksum % 11 === 0) {
      return 0;
    }
    if (checksum % 5 === 0) {
      return 3;
    }
    return 8 + (checksum % 12);
  }

  private seedLegacyAliases(productId: string, title: string, storefrontId: string) {
    const slug = this.slugify(title);
    return Array.from(
      new Set([
        productId,
        `detail-${slug}`,
        `${slug}-single`,
        `${slug}-double`,
        `${slug}-large`,
        `market-product-${storefrontId}-${slug}`,
      ]),
    );
  }

  private parseManifestEventDate(dateLabel: string, timeLabel: string) {
    const months: Record<string, number> = {
      Oca: 0,
      Şub: 1,
      Mar: 2,
      Nis: 3,
      May: 4,
      Haz: 5,
      Tem: 6,
      Ağu: 7,
      Eyl: 8,
      Eki: 9,
      Kas: 10,
      Ara: 11,
    };
    const [dayRaw, monthRaw, yearRaw] = dateLabel.split(' ');
    const [hoursRaw, minutesRaw] = timeLabel.split(':');
    const year = Number(yearRaw);
    const month = months[monthRaw] ?? 0;
    const day = Number(dayRaw);
    const hours = Number(hoursRaw);
    const minutes = Number(minutesRaw);
    return new Date(Date.UTC(year, month, day, hours - 3, minutes));
  }

  private parseLeadingInt(value: string) {
    const match = value.match(/\d+/);
    return match ? Number(match[0]) : 0;
  }

  private slugify(value: string) {
    return value
      .toLocaleLowerCase('tr-TR')
      .replace(/ç/g, 'c')
      .replace(/ğ/g, 'g')
      .replace(/ı/g, 'i')
      .replace(/ö/g, 'o')
      .replace(/ş/g, 's')
      .replace(/ü/g, 'u')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  private async resolveCheckoutLineItem(
    tx: Prisma.TransactionClient,
    item: CreateCheckoutSessionDto['items'][number],
  ) {
    const exactProduct = await tx.product.findUnique({
      where: { id: item.productId },
      select: {
        id: true,
        title: true,
        unitPrice: true,
      },
    });
    if (exactProduct) {
      return {
        ...item,
        productId: exactProduct.id,
        title: item.title ?? exactProduct.title,
        unitPrice: item.unitPrice ?? Number(exactProduct.unitPrice),
      };
    }

    const candidateVendorIds =
      item.vendor && item.vendor.trim().length > 0
        ? (await tx.vendor.findMany({
            where: {
              OR: [
                { name: { equals: item.vendor.trim(), mode: 'insensitive' } },
                { storefrontId: item.vendor.trim() },
                { slug: this.slugify(item.vendor) },
              ],
            },
            select: { id: true },
          })).map((vendor) => vendor.id)
        : [];

    const candidates = await tx.product.findMany({
      where: {
        isActive: true,
        isArchived: false,
        ...(candidateVendorIds.length > 0 ? { vendorId: { in: candidateVendorIds } } : {}),
      },
      select: {
        id: true,
        title: true,
        unitPrice: true,
        legacyAliases: true,
      },
    });

    const normalizedId = this.slugify(item.productId);
    const normalizedTitle = this.slugify(((item.title ?? '').split('•')[0] ?? '').trim());

    const resolved =
      candidates.find((candidate) =>
        this.toJsonStringArray(candidate.legacyAliases).some(
          (alias) => alias === item.productId || this.slugify(alias) === normalizedId,
        ),
      ) ??
      candidates.find((candidate) => this.slugify(candidate.title) == normalizedTitle) ??
      candidates.find((candidate) => normalizedId.includes(this.slugify(candidate.title)));

    if (!resolved) {
      throw new NotFoundException(`Product ${item.productId} not found`);
    }

    return {
      ...item,
      productId: resolved.id,
      title: item.title ?? resolved.title,
      unitPrice: item.unitPrice ?? Number(resolved.unitPrice),
    };
  }

  private async resolveCheckoutPickupPoint(
    tx: Prisma.TransactionClient,
    vendorId: string,
    pickupPointRef: string,
  ) {
    const vendor = await tx.vendor.findUnique({
      where: { id: vendorId },
      select: {
        name: true,
        pickupPoints: {
          orderBy: { createdAt: 'asc' },
          select: {
            id: true,
            label: true,
            address: true,
          },
        },
      },
    });
    if (!vendor) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }
    if (vendor.pickupPoints.length === 0) {
      throw new NotFoundException(
        `Pickup point for vendor ${vendor.name} not found`,
      );
    }

    const normalizedRef = pickupPointRef.trim().toLowerCase();
    return (
      vendor.pickupPoints.find(
        (pickupPoint) => pickupPoint.id === pickupPointRef.trim(),
      ) ??
      vendor.pickupPoints.find(
        (pickupPoint) => pickupPoint.label.trim().toLowerCase() === normalizedRef,
      ) ??
      vendor.pickupPoints.find(
        (pickupPoint) => pickupPoint.address.trim().toLowerCase() === normalizedRef,
      ) ??
      vendor.pickupPoints[0]
    );
  }

  private async buildSessionResponse(user: UserRecord) {
    const profile = await this.toAppUser(user);
    return {
      user: profile,
      tokens: {
        accessToken: `access-${profile.id}`,
        refreshToken: `refresh-${profile.id}`,
      },
    };
  }

  private async requireCurrentUser() {
    await this.ensureInitialized();
    const requestScopedUser = await this.findUserFromAccessToken(
      this.requestContext.accessToken,
    );
    if (requestScopedUser) {
      return requestScopedUser;
    }
    throw new UnauthorizedException('No active session');
  }

  private async findUserFromAccessToken(accessToken?: string) {
    if (!accessToken?.startsWith('access-')) {
      return null;
    }

    const userId = accessToken.slice('access-'.length).trim();
    if (!userId) {
      return null;
    }

    return this.prisma.user.findUnique({
      where: { id: userId },
    });
  }

  private async resolveVendorScope(user: UserRecord, vendorId?: string) {
    if (user.role === PrismaRole.ADMIN) {
      if (vendorId) {
        return [vendorId];
      }
      const vendors = await this.prisma.vendor.findMany({
        select: { id: true },
      });
      return vendors.map((vendor) => vendor.id);
    }

    if (user.role === PrismaRole.VENDOR) {
      if (!user.vendorId) {
        throw new ForbiddenException('Vendor scope mismatch');
      }
      if (vendorId && user.vendorId !== vendorId) {
        throw new ForbiddenException('Vendor scope mismatch');
      }
      return [vendorId ?? user.vendorId];
    }

    if (vendorId) {
      return [vendorId];
    }

    const vendors = await this.prisma.vendor.findMany({
      select: { id: true },
    });
    return vendors.map((vendor) => vendor.id);
  }

  private assertOpsAccess(user: UserRecord) {
    if (user.role === PrismaRole.CUSTOMER) {
      throw new ForbiddenException('Ops access required');
    }
  }

  private assertAdminAccess(user: UserRecord) {
    if (user.role !== PrismaRole.ADMIN) {
      throw new ForbiddenException('Admin access required');
    }
  }

  private assertVendorAccess(user: UserRecord, vendorId: string) {
    if (user.role === PrismaRole.ADMIN) {
      return;
    }
    if (user.role !== PrismaRole.VENDOR || user.vendorId !== vendorId) {
      throw new ForbiddenException('Vendor scope mismatch');
    }
  }

  private async queryInventoryItems(
    vendorId?: string,
    query?: string,
    enforceOpsScope?: boolean,
  ) {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();

    const allowedVendorIds =
      enforceOpsScope ? await this.resolveVendorScope(current, vendorId) : undefined;
    let stocks = await this.prisma.inventoryStock.findMany({
      where: {
        ...(allowedVendorIds
          ? { vendorId: { in: allowedVendorIds } }
          : vendorId
            ? { vendorId }
            : {}),
        product: {
          isArchived: false,
        },
      },
      include: stockInclude,
      orderBy: {
        updatedAt: 'desc',
      },
    });

    if (query && query.trim().length > 0) {
      const normalizedQuery = query.trim().toLowerCase();
      stocks = stocks.filter((stock) => {
        const haystack =
          `${stock.product.title} ${stock.product.sku} ${stock.vendor.name} ${stock.product.kind}`.toLowerCase();
        return haystack.includes(normalizedQuery);
      });
    }

    return stocks
      .map((stock) => this.toInventoryItemPayload(stock))
      .sort((left, right) => {
        if (left.stockStatus.canPurchase !== right.stockStatus.canPurchase) {
          return left.stockStatus.canPurchase ? 1 : -1;
        }
        if (left.stockStatus.lowStock !== right.stockStatus.lowStock) {
          return left.stockStatus.lowStock ? -1 : 1;
        }
        return left.title.localeCompare(right.title);
      });
  }

  private async requireInventoryStock(itemId: string) {
    const stock = await this.prisma.inventoryStock.findFirst({
      where: { productId: itemId },
      include: stockInclude,
    });
    if (!stock) {
      throw new NotFoundException(`Inventory item ${itemId} not found`);
    }
    return stock;
  }

  private async requireIntegration(connectionId: string) {
    const connection = await this.prisma.integrationConnection.findUnique({
      where: { id: connectionId },
      include: integrationInclude,
    });
    if (!connection) {
      throw new NotFoundException(`Integration ${connectionId} not found`);
    }
    return connection;
  }

  private async applyOrderStatusTransition(
    orderId: string,
    status: OpsOrderStatus,
    options: {
      actor: UserRecord;
      skipOpsAccessCheck: boolean;
    },
  ) {
    if (!options.skipOpsAccessCheck) {
      this.assertOpsAccess(options.actor);
    }

    const existing = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: orderInclude,
    });
    if (!existing) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    if (options.skipOpsAccessCheck) {
      if (existing.userId !== options.actor.id) {
        throw new NotFoundException(`Order ${orderId} not found`);
      }
    } else {
      this.assertVendorAccess(options.actor, existing.vendorId);
    }

    const targetStatus = this.toPrismaOrderStatus(status);
    if (this.isTerminal(existing.status) && existing.status !== targetStatus) {
      throw new BadRequestException('Order is already finalized');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: orderInclude,
      });
      if (!order) {
        throw new NotFoundException(`Order ${orderId} not found`);
      }

      if (targetStatus === PrismaOrderStatus.COMPLETED && !this.isTerminal(order.status)) {
        for (const line of order.items) {
          const stock = await tx.inventoryStock.findFirst({
            where: { productId: line.productId },
          });
          if (!stock) {
            continue;
          }
          const nextReserved = Math.max(0, stock.reserved - line.quantity);
          const nextOnHand = Math.max(0, stock.onHand - line.quantity);
          await tx.inventoryStock.update({
            where: { id: stock.id },
            data: {
              onHand: nextOnHand,
              reserved: nextReserved,
            },
          });
          await tx.inventoryMovement.create({
            data: {
              productId: line.productId,
              vendorId: order.vendorId,
              type: PrismaInventoryMovementType.SALE,
              quantityDelta: nextOnHand - stock.onHand,
              previousOnHand: stock.onHand,
              nextOnHand,
              previousReserved: stock.reserved,
              nextReserved,
              orderId: order.id,
              note: `Sale for order ${order.id}`,
            },
          });
        }
      }

      if (targetStatus === PrismaOrderStatus.CANCELLED && !this.isTerminal(order.status)) {
        for (const line of order.items) {
          const stock = await tx.inventoryStock.findFirst({
            where: { productId: line.productId },
          });
          if (!stock) {
            continue;
          }
          const nextReserved = Math.max(0, stock.reserved - line.quantity);
          await tx.inventoryStock.update({
            where: { id: stock.id },
            data: {
              reserved: nextReserved,
            },
          });
          await tx.inventoryMovement.create({
            data: {
              productId: line.productId,
              vendorId: order.vendorId,
              type: PrismaInventoryMovementType.RELEASE,
              quantityDelta: 0,
              previousOnHand: stock.onHand,
              nextOnHand: stock.onHand,
              previousReserved: stock.reserved,
              nextReserved,
              orderId: order.id,
              note: `Release for cancelled order ${order.id}`,
            },
          });
        }
      }

      return tx.order.update({
        where: { id: order.id },
        data: {
          status: targetStatus,
          etaLabel: this.etaLabelForStatus(status),
        },
        include: orderInclude,
      });
    });

    return this.toOrderPayload(updated);
  }

  private async toAppUser(user: UserRecord): Promise<AppUser> {
    const role = (user.role === PrismaRole.ADMIN
      ? 'ADMIN'
      : user.role === PrismaRole.VENDOR
        ? 'VENDOR'
        : 'CUSTOMER') satisfies UserRole;
    const vendorScopes =
      role === 'ADMIN'
        ? (await this.prisma.vendor.findMany({
            where: { isActive: true },
            select: { id: true },
            orderBy: { name: 'asc' },
          })).map((vendor) => vendor.id)
        : role === 'VENDOR' && user.vendorId
          ? [user.vendorId]
          : [];

    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      phone: user.phone ?? '',
      studentVerified: Boolean(user.studentVerifiedAt),
      notificationsEnabled: user.notificationsEnabled,
      avatarUrl: user.avatarUrl ?? '',
      role,
      vendorScopes,
    };
  }

  private toAddress(address: {
    id: string;
    label: string;
    address: string;
    iconKey: string;
    isPrimary: boolean;
  }): Address {
    return {
      id: address.id,
      label: address.label,
      address: address.address,
      iconKey: address.iconKey,
      isPrimary: address.isPrimary,
    };
  }

  private toPaymentMethod(method: {
    id: string;
    brand: string;
    last4: string;
    expiryMonth: number;
    expiryYear: number;
    holderName: string;
    isDefault: boolean;
    providerToken: string;
  }): PaymentMethod {
    return {
      id: method.id,
      brand: method.brand,
      last4: method.last4,
      expiry: `${method.expiryMonth.toString().padStart(2, '0')}/${method.expiryYear
        .toString()
        .slice(-2)}`,
      holderName: method.holderName,
      isDefault: method.isDefault,
      token: method.providerToken,
    };
  }

  private async getContentVersion() {
    const [vendor, product, event, block] = await Promise.all([
      this.prisma.vendor.findFirst({
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
      this.prisma.product.findFirst({
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
      this.prisma.event.findFirst({
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
      this.prisma.contentBlock.findFirst({
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
    ]);

    const timestamps = [vendor, product, event, block]
      .map((entry) => entry?.updatedAt)
      .filter((value): value is Date => Boolean(value));
    if (timestamps.length === 0) {
      return loadCatalogManifest().contentVersion;
    }
    return new Date(Math.max(...timestamps.map((value) => value.getTime()))).toISOString();
  }

  private async getHomeContent() {
    const blocks = await this.prisma.contentBlock.findMany({
      where: { isActive: true },
      orderBy: [{ displayOrder: 'asc' }, { key: 'asc' }],
    });
    return {
      heroes: blocks
        .filter((block) => block.type === PrismaContentBlockType.HOME_HERO)
        .map((block) => this.toContentBlockPayload(block)),
      quickFilters: blocks
        .filter((block) => block.type === PrismaContentBlockType.QUICK_FILTER)
        .map((block) => this.toContentBlockPayload(block)),
      discoveryFilters: blocks
        .filter((block) => block.type === PrismaContentBlockType.DISCOVERY_FILTER)
        .map((block) => this.toContentBlockPayload(block)),
    };
  }

  private async requireCatalogVendor(vendorId: string) {
    await this.ensureInitialized();
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: catalogVendorInclude,
    });
    if (!vendor || !vendor.isActive) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }
    return vendor;
  }

  private toRestaurantCatalogItem(vendor: CatalogVendorRecord) {
    return this.toVendorDetailPayload(vendor);
  }

  private toMarketCatalogItem(vendor: CatalogVendorRecord) {
    return this.toVendorDetailPayload(vendor);
  }

  private toVendorDetailPayload(vendor: CatalogVendorRecord) {
    const visibleStocks = vendor.inventory.filter(
      (stock) =>
        stock.product.catalogSectionId &&
        stock.product.isVisibleInApp &&
        !stock.product.isArchived &&
        stock.product.isActive,
    );
    const sections = vendor.sections.map((section) => this.toCatalogSectionPayload(section, vendor));
    return {
      id: vendor.storefrontId ?? vendor.id,
      vendorId: vendor.id,
      storefrontType:
        vendor.storefrontType === PrismaStorefrontType.MARKET ? 'MARKET' : 'RESTAURANT',
      title: vendor.name,
      subtitle: vendor.subtitle ?? '',
      meta: vendor.metaLabel ?? '',
      image:
        vendor.imageUrl ??
        sections[0]?.products[0]?.image ??
        'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=1200&q=80',
      badge: vendor.badge ?? '',
      rewardLabel: vendor.rewardLabel ?? 'Gel-Al',
      ratingLabel: (vendor.ratingValue ?? 4.7).toFixed(1),
      distanceLabel: vendor.distanceLabel ?? '1.2 km',
      etaLabel:
        vendor.etaMin != null && vendor.etaMax != null
          ? `${vendor.etaMin}-${vendor.etaMax} dk`
          : vendor.etaMin != null
            ? `${vendor.etaMin} dk`
            : '12 dk',
      promoLabel: vendor.promoLabel ?? '',
      workingHoursLabel: vendor.workingHoursLabel ?? '09:00-23:00',
      minOrderLabel: 'Yok',
      deliveryWindowLabel: 'Hazır olduğunda',
      reviewCountLabel: vendor.reviewCountLabel ?? '',
      announcement: vendor.announcement ?? '',
      bundleTitle: vendor.bundleTitle ?? '',
      bundleDescription: vendor.bundleDescription ?? '',
      bundlePrice: vendor.bundlePrice ?? '',
      heroTitle: vendor.heroTitle ?? vendor.name,
      heroSubtitle: vendor.heroSubtitle ?? vendor.subtitle ?? '',
      cuisine: vendor.category,
      etaMin: vendor.etaMin ?? 12,
      etaMax: vendor.etaMax ?? vendor.etaMin ?? 18,
      ratingValue: vendor.ratingValue ?? 4.7,
      promo: vendor.promoLabel ?? '',
      studentFriendly: vendor.studentFriendly,
      isFeatured: vendor.isFeatured,
      isActive: vendor.isActive,
      pickupPoints: vendor.pickupPoints.map((pickupPoint) => ({
        id: pickupPoint.id,
        label: pickupPoint.label,
        address: pickupPoint.address,
      })),
      highlights: vendor.highlights.map((highlight) => ({
        id: highlight.id,
        label: highlight.label,
        icon: highlight.iconKey,
        displayOrder: highlight.displayOrder,
      })),
      operatorAccounts: vendor.operators.map((operator) => ({
        id: operator.id,
        email: operator.email,
        displayName: operator.displayName,
        phone: operator.phone ?? '',
      })),
      sections,
      stockStatus: this.vendorStockStatusFromStocks(
        visibleStocks.map((stock) => ({
          onHand: stock.onHand,
          reserved: stock.reserved,
          reorderLevel: stock.product.reorderLevel,
          trackStock: stock.product.trackStock,
          isArchived: stock.product.isArchived,
        })),
      ),
    };
  }

  private toCatalogSectionPayload(
    section: CatalogVendorRecord['sections'][number],
    vendor: CatalogVendorRecord,
  ) {
    return {
      id: section.id,
      key: section.key,
      label: section.label,
      displayOrder: section.displayOrder,
      isActive: section.isActive,
      products: section.products.map((product) => this.toCatalogProductPayload(product, vendor)),
    };
  }

  private toCatalogProductPayload(
    product: CatalogVendorRecord['sections'][number]['products'][number],
    vendor: CatalogVendorRecord,
  ) {
    const section = vendor.sections.find((item) => item.id === product.catalogSectionId);
    return {
      id: product.id,
      vendorId: vendor.id,
      vendorName: vendor.name,
      sectionId: product.catalogSectionId ?? '',
      sectionLabel: section?.label ?? '',
      title: product.title,
      description: product.description ?? '',
      image: product.imageUrl ?? '',
      imageUrl: product.imageUrl ?? '',
      unitPrice: Number(product.unitPrice),
      priceText: `${Number(product.unitPrice).toFixed(0)} TL`,
      category: product.kind,
      sku: product.sku,
      barcode: product.barcode ?? '',
      externalCode: product.externalCode ?? '',
      displaySubtitle: product.displaySubtitle ?? '',
      displayBadge: product.displayBadge ?? '',
      displayOrder: product.displayOrder,
      isFeatured: product.isFeatured,
      isVisibleInApp: product.isVisibleInApp,
      trackStock: product.trackStock,
      reorderLevel: product.reorderLevel,
      isArchived: product.isArchived,
      stockStatus: this.toStockStatusPayloadForProduct(product.id, vendor.inventory),
      searchKeywords: this.toJsonStringArray(product.searchKeywords),
      legacyAliases: this.toJsonStringArray(product.legacyAliases),
    };
  }

  private toEventDetailPayload(event: {
    id: string;
    title: string;
    venue: string;
    district: string | null;
    imageUrl: string | null;
    startsAt: Date;
    pointsCost: number;
    primaryTag?: string | null;
    secondaryTag?: string | null;
    description?: string | null;
    organizer?: string | null;
    participantLabel?: string | null;
    ticketCategory?: string | null;
    locationTitle?: string | null;
    locationSubtitle?: string | null;
    remainingCount?: number;
    capacity?: number;
    isFeatured?: boolean;
    isActive?: boolean;
  }) {
    return {
      id: event.id,
      title: event.title,
      venue: event.venue,
      district: event.district ?? 'İstanbul',
      dateLabel: this.formatEventDateLabel(event.startsAt),
      timeLabel: this.formatClockLabel(event.startsAt),
      image:
        event.imageUrl ??
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
      pointsCost: event.pointsCost,
      primaryTag: event.primaryTag ?? 'Etkinlik',
      secondaryTag: event.secondaryTag ?? 'Genel Katılım',
      description: event.description ?? '',
      organizer: event.organizer ?? '',
      participantLabel: event.participantLabel ?? '',
      ticketCategory: event.ticketCategory ?? '',
      locationTitle: event.locationTitle ?? event.venue,
      locationSubtitle: event.locationSubtitle ?? event.district ?? 'İstanbul',
      remainingCount: event.remainingCount ?? 0,
      capacity: event.capacity ?? 0,
      isFeatured: event.isFeatured ?? false,
      isActive: event.isActive ?? true,
    };
  }

  private buildHappyHourOffers(vendors: CatalogVendorRecord[]): HappyHourOfferPayload[] {
    const candidates = vendors.flatMap((vendor) =>
      vendor.sections.flatMap((section) =>
        section.products.map((product) => ({
          vendor,
          section,
          product,
        })),
      ),
    );
    candidates.sort((left, right) => {
      const featuredDelta = Number(right.product.isFeatured) - Number(left.product.isFeatured);
      if (featuredDelta != 0) {
        return featuredDelta;
      }
      const vendorDelta = Number(right.vendor.isFeatured) - Number(left.vendor.isFeatured);
      if (vendorDelta != 0) {
        return vendorDelta;
      }
      if (left.vendor.displayOrder !== right.vendor.displayOrder) {
        return left.vendor.displayOrder - right.vendor.displayOrder;
      }
      if (left.section.displayOrder !== right.section.displayOrder) {
        return left.section.displayOrder - right.section.displayOrder;
      }
      return left.product.displayOrder - right.product.displayOrder;
    });

    return candidates
      .slice(0, 12)
      .map(({ vendor, section, product }, index) =>
        this.toHappyHourOfferPayload(product, vendor, section.label, index),
      );
  }

  private toHappyHourOfferPayload(
    product: CatalogVendorRecord['sections'][number]['products'][number],
    vendor: CatalogVendorRecord,
    sectionLabel: string,
    index: number,
  ): HappyHourOfferPayload {
    const discountedPrice = Number(product.unitPrice);
    const originalPrice = Math.max(
      discountedPrice + 20,
      Math.round(discountedPrice * 1.32),
    );
    const discountPercent = Math.max(
      10,
      Math.round((1 - discountedPrice / originalPrice) * 100),
    );
    const pickupPoint = vendor.pickupPoints[0];
    return {
      id: product.id,
      productId: product.id,
      vendorId: vendor.id,
      vendorName: vendor.name,
      vendorSubtitle: vendor.subtitle ?? vendor.category,
      title: product.title,
      subtitle:
        Boolean(product.displaySubtitle?.trim().length)
          ? product.displaySubtitle!.trim()
          : `${vendor.name} • ${sectionLabel}`,
      description:
        Boolean(product.description?.trim().length)
          ? product.description!.trim()
          : `${vendor.name} için hazırlanan ${sectionLabel.toLowerCase()} fırsatı.`,
      imageUrl:
        product.imageUrl ??
        vendor.imageUrl ??
        'https://images.unsplash.com/photo-1561758033-d89a9ad46330?auto=format&fit=crop&w=1200&q=80',
      badge: Boolean(product.displayBadge?.trim().length)
        ? product.displayBadge!.trim()
        : Boolean(vendor.promoLabel?.trim().length)
          ? vendor.promoLabel!.trim()
          : 'Happy Hour Özel',
      discountedPrice,
      discountedPriceText: `${discountedPrice.toFixed(0)} TL`,
      originalPrice,
      originalPriceText: `${originalPrice.toFixed(0)} TL`,
      discountPercent,
      expiresInMinutes: 35 + (index * 11) % 95,
      rewardPoints: 30 + index * 10,
      claimCount: 12 + index * 7,
      locationTitle: pickupPoint?.label ?? `${vendor.name} şubesi`,
      locationSubtitle:
        pickupPoint?.address ??
        `${vendor.distanceLabel ?? '1.2 km'} • ${vendor.workingHoursLabel ?? '09:00-23:00'}`,
      sectionLabel,
      stockStatus: this.toStockStatusPayloadForProduct(product.id, vendor.inventory),
    };
  }

  private toContentBlockPayload(block: ContentBlockRecord) {
    return {
      id: block.id,
      type: block.type,
      key: block.key,
      title: block.title,
      subtitle: block.subtitle ?? '',
      badge: block.badge ?? '',
      imageUrl: block.imageUrl ?? '',
      actionLabel: block.actionLabel ?? '',
      screen: block.screen ?? '',
      iconKey: block.iconKey ?? '',
      highlight: block.highlight,
      displayOrder: block.displayOrder,
      isActive: block.isActive,
      payload: block.payload ?? {},
    };
  }

  private async ensureVendorOperatorAccounts(tx: Prisma.TransactionClient) {
    const vendors = await tx.vendor.findMany({
      where: {
        storefrontType: { in: [PrismaStorefrontType.RESTAURANT, PrismaStorefrontType.MARKET] },
      },
      include: {
        operators: {
          where: { role: PrismaRole.VENDOR },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { name: 'asc' },
    });

    for (const vendor of vendors) {
      if (vendor.operators.length > 0) {
        continue;
      }
      await this.upsertVendorOperator(tx, {
        vendorId: vendor.id,
        email: `ops+${vendor.slug}@speto.app`,
        password: 'vendor123',
        displayName: `${vendor.name} Operasyon`,
        phone: '',
      });
    }
  }

  private async upsertVendorOperator(
    tx: Prisma.TransactionClient,
    payload: {
      vendorId: string;
      email: string;
      password: string;
      displayName: string;
      phone: string;
      existingOperatorId?: string;
    },
  ) {
    const normalizedEmail = this.normalizeEmail(payload.email);
    const existingByEmail = await tx.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (existingByEmail && existingByEmail.vendorId !== payload.vendorId) {
      throw new BadRequestException('Bu e-posta başka bir mağaza kullanıcısında kayıtlı');
    }

    if (payload.existingOperatorId) {
      await tx.user.update({
        where: { id: payload.existingOperatorId },
        data: {
          email: normalizedEmail,
          password: payload.password,
          displayName: payload.displayName,
          phone: payload.phone,
          role: PrismaRole.VENDOR,
          vendorId: payload.vendorId,
          notificationsEnabled: true,
        },
      });
      return;
    }

    if (existingByEmail) {
      await tx.user.update({
        where: { id: existingByEmail.id },
        data: {
          password: payload.password,
          displayName: payload.displayName,
          phone: payload.phone,
          role: PrismaRole.VENDOR,
          vendorId: payload.vendorId,
          notificationsEnabled: true,
        },
      });
      return;
    }

    await tx.user.create({
      data: {
        email: normalizedEmail,
        password: payload.password,
        displayName: payload.displayName,
        phone: payload.phone,
        role: PrismaRole.VENDOR,
        vendorId: payload.vendorId,
        notificationsEnabled: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=48',
      },
    });
  }

  private async resolveCatalogSectionId(
    vendorId: string,
    requestedSectionId: string,
    payload: Record<string, unknown>,
  ) {
    if (requestedSectionId) {
      const section = await this.prisma.catalogSection.findUnique({
        where: { id: requestedSectionId },
      });
      if (!section || section.vendorId !== vendorId) {
        throw new BadRequestException('Geçersiz section seçimi');
      }
      return section.id;
    }

    const sectionLabel =
      typeof payload['sectionLabel'] === 'string' && payload['sectionLabel'].trim().length > 0
        ? payload['sectionLabel'].trim()
        : 'Genel';
    const key = this.slugify(sectionLabel);
    const section = await this.prisma.catalogSection.upsert({
      where: {
        vendorId_key: {
          vendorId,
          key,
        },
      },
      update: {
        label: sectionLabel,
        isActive: true,
      },
      create: {
        vendorId,
        key,
        label: sectionLabel,
        displayOrder: 999,
        isActive: true,
      },
    });
    return section.id;
  }

  private toCatalogVendorUpdateData(payload: Record<string, unknown>) {
    return {
      ...(typeof payload['name'] === 'string' ? { name: payload['name'] } : {}),
      ...(typeof payload['subtitle'] === 'string' ? { subtitle: payload['subtitle'] } : {}),
      ...(typeof payload['meta'] === 'string' ? { metaLabel: payload['meta'] } : {}),
      ...(typeof payload['image'] === 'string' ? { imageUrl: payload['image'] } : {}),
      ...(typeof payload['imageUrl'] === 'string' ? { imageUrl: payload['imageUrl'] } : {}),
      ...(typeof payload['badge'] === 'string' ? { badge: payload['badge'] } : {}),
      ...(typeof payload['rewardLabel'] === 'string'
        ? { rewardLabel: payload['rewardLabel'] }
        : {}),
      ...(typeof payload['promoLabel'] === 'string'
        ? { promoLabel: payload['promoLabel'] }
        : {}),
      ...(typeof payload['distanceLabel'] === 'string'
        ? { distanceLabel: payload['distanceLabel'] }
        : {}),
      ...(typeof payload['workingHoursLabel'] === 'string'
        ? { workingHoursLabel: payload['workingHoursLabel'] }
        : {}),
      ...(typeof payload['reviewCountLabel'] === 'string'
        ? { reviewCountLabel: payload['reviewCountLabel'] }
        : {}),
      ...(typeof payload['announcement'] === 'string'
        ? { announcement: payload['announcement'] }
        : {}),
      ...(typeof payload['bundleTitle'] === 'string'
        ? { bundleTitle: payload['bundleTitle'] }
        : {}),
      ...(typeof payload['bundleDescription'] === 'string'
        ? { bundleDescription: payload['bundleDescription'] }
        : {}),
      ...(typeof payload['bundlePrice'] === 'string'
        ? { bundlePrice: payload['bundlePrice'] }
        : {}),
      ...(typeof payload['heroTitle'] === 'string' ? { heroTitle: payload['heroTitle'] } : {}),
      ...(typeof payload['heroSubtitle'] === 'string'
        ? { heroSubtitle: payload['heroSubtitle'] }
        : {}),
      ...(typeof payload['studentFriendly'] === 'boolean'
        ? { studentFriendly: payload['studentFriendly'] }
        : {}),
      ...(typeof payload['isFeatured'] === 'boolean'
        ? { isFeatured: payload['isFeatured'] }
        : {}),
      ...(typeof payload['isActive'] === 'boolean' ? { isActive: payload['isActive'] } : {}),
      ...(typeof payload['ratingValue'] === 'number'
        ? { ratingValue: Number(payload['ratingValue']) }
        : {}),
      ...(typeof payload['etaMin'] === 'number'
        ? { etaMin: Math.max(0, Math.trunc(payload['etaMin'])) }
        : {}),
      ...(typeof payload['etaMax'] === 'number'
        ? { etaMax: Math.max(0, Math.trunc(payload['etaMax'])) }
        : {}),
      ...(typeof payload['displayOrder'] === 'number'
        ? { displayOrder: Math.max(0, Math.trunc(payload['displayOrder'])) }
        : {}),
    };
  }

  private toPayloadStringArray(value: unknown) {
    if (Array.isArray(value)) {
      return value
        .map((entry) => String(entry).trim())
        .filter((entry) => entry.length > 0);
    }
    if (typeof value === 'string') {
      return value
        .split(',')
        .map((entry) => entry.trim())
        .filter((entry) => entry.length > 0);
    }
    return [];
  }

  private toJsonStringArray(value: Prisma.JsonValue | null | undefined) {
    if (!Array.isArray(value)) {
      return [];
    }
    return value.map((entry) => String(entry));
  }

  private toStockStatusPayloadForProduct(
    productId: string,
    stocks: Array<{
      productId: string;
      onHand: number;
      reserved: number;
      product: {
        reorderLevel: number;
        trackStock: boolean;
        isArchived: boolean;
      };
    }>,
  ): StockStatusPayload {
    const relatedStocks = stocks.filter((stock) => stock.productId === productId);
    if (relatedStocks.length === 0) {
      return {
        isInStock: false,
        availableQuantity: 0,
        lowStock: false,
        canPurchase: false,
      };
    }
    return this.vendorStockStatusFromStocks(
      relatedStocks.map((stock) => ({
        onHand: stock.onHand,
        reserved: stock.reserved,
        reorderLevel: stock.product.reorderLevel,
        trackStock: stock.product.trackStock,
        isArchived: stock.product.isArchived,
      })),
    );
  }

  private async getPreferencePayload(userId: string) {
    const [favorites, ratings] = await Promise.all([
      this.prisma.favorite.findMany({
        where: { userId },
      }),
      this.prisma.orderRating.findMany({
        where: { userId },
        select: { orderId: true, stars: true },
      }),
    ]);

    return {
      favoriteRestaurantIds: favorites
        .filter((favorite) => favorite.entityType === 'restaurant')
        .map((favorite) => favorite.entityId),
      favoriteEventIds: favorites
        .filter((favorite) => favorite.entityType === 'event')
        .map((favorite) => favorite.entityId),
      favoriteMarketIds: favorites
        .filter((favorite) => favorite.entityType === 'market')
        .map((favorite) => favorite.entityId),
      followedOrganizerIds: favorites
        .filter((favorite) => favorite.entityType === 'organizer')
        .map((favorite) => favorite.entityId),
      orderRatings: Object.fromEntries(
        ratings.map((rating) => [rating.orderId, rating.stars]),
      ) as Record<string, number>,
    };
  }

  private normalizePreferenceEntityType(entityType: string) {
    const normalized = entityType.trim().toLowerCase();
    switch (normalized) {
      case 'restaurant':
      case 'event':
      case 'market':
      case 'organizer':
        return normalized;
      default:
        throw new BadRequestException(`Unsupported preference entity type: ${entityType}`);
    }
  }

  private async assertPreferenceEntityExists(entityType: string, entityId: string) {
    if (entityType === 'organizer') {
      return;
    }

    if (entityType === 'event') {
      const event = await this.prisma.event.findUnique({
        where: { id: entityId },
        select: { id: true },
      });
      if (!event) {
        throw new NotFoundException(`Event ${entityId} not found`);
      }
      return;
    }

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: entityId },
      select: { id: true, storefrontType: true },
    });
    if (!vendor) {
      throw new NotFoundException(`Vendor ${entityId} not found`);
    }

    if (entityType === 'market' && vendor.storefrontType !== PrismaStorefrontType.MARKET) {
      throw new BadRequestException(`Vendor ${entityId} is not a market`);
    }
    if (
      entityType === 'restaurant' &&
      vendor.storefrontType !== PrismaStorefrontType.RESTAURANT
    ) {
      throw new BadRequestException(`Vendor ${entityId} is not a restaurant`);
    }
  }

  private hashOtpCode(code: string) {
    return createHash('sha256').update(code).digest('hex');
  }

  private normalizeOtpCode(rawCode?: string | null) {
    const normalizedDigits = (rawCode ?? '')
      .replaceAll(/[^0-9]/g, '')
      .trim();
    if (normalizedDigits.length >= 5) {
      return normalizedDigits.substring(0, 5);
    }
    return DEFAULT_PASSWORD_RESET_TEST_CODE;
  }

  private generatePasswordResetOtpCode() {
    if (this.passwordResetOtpTestMode) {
      return this.passwordResetOtpTestCode;
    }
    return String(randomInt(10000, 100000));
  }

  private async deliverPasswordResetOtpEmail(payload: {
    email: string;
    code: string;
    expiresAt: Date;
  }) {
    if (this.passwordResetOtpTestMode) {
      return;
    }
    if (!this.resendApiKey) {
      throw new InternalServerErrorException('Resend API key is not configured');
    }

    const expiresAtLabel = this.formatDateLabel(payload.expiresAt);
    const response = await fetch(`${this.resendApiBaseUrl}/emails`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: this.resendFromEmail,
        to: [payload.email],
        subject: 'Speto sifre sifirlama kodunuz',
        html: `
          <div style="font-family:Arial,sans-serif;line-height:1.6;color:#1f1720">
            <h2 style="margin:0 0 12px">Speto sifre sifirlama kodu</h2>
            <p style="margin:0 0 12px">Yeni sifre olusturmak icin asagidaki 5 haneli kodu kullanin:</p>
            <div style="font-size:32px;font-weight:700;letter-spacing:8px;margin:20px 0;color:#c4681a">
              ${payload.code}
            </div>
            <p style="margin:0 0 8px">Kodun gecerlilik suresi: 10 dakika</p>
            <p style="margin:0">Son gecerlilik zamani: ${expiresAtLabel}</p>
          </div>
        `,
        text: `Speto sifre sifirlama kodunuz: ${payload.code}. Kod 10 dakika gecerli. Son gecerlilik zamani: ${expiresAtLabel}`,
      }),
    });

    if (response.ok) {
      return;
    }

    const failureBody = await response.text();
    throw new InternalServerErrorException(
      `Resend email delivery failed: ${failureBody}`,
    );
  }

  private isValidPasswordResetOtp(
    otp: {
      codeHash: string;
      expiresAt: Date;
    },
    code: string,
  ) {
    if (!code || code.length < 5) {
      return false;
    }
    if (otp.expiresAt.getTime() <= Date.now()) {
      return false;
    }
    return otp.codeHash === this.hashOtpCode(code);
  }

  private toOrderPayload(order: OrderRecord): Order {
    const image =
      order.items[0]?.product.imageUrl ??
      'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=1200&q=80';
    return {
      id: order.id,
      vendorId: order.vendorId,
      vendor: order.vendor.name,
      image,
      items: order.items.map((item) => ({
        id: item.id,
        productId: item.productId,
        title: item.title,
        vendor: order.vendor.name,
        image: item.product.imageUrl ?? image,
        unitPrice: Number(item.unitPrice),
        quantity: item.quantity,
      })),
      placedAtLabel: this.formatDateLabel(order.createdAt),
      etaLabel: order.etaLabel,
      status: this.toClientOrderStatus(order.status),
      opsStatus: order.status as OpsOrderStatus,
      actionLabel: this.actionLabelForStatus(order.status as OpsOrderStatus),
      pickupCode: order.pickupCode,
      rewardPoints: Number((Number(order.totalAmount) * 0.01).toFixed(2)),
      deliveryMode: 'Gel-Al',
      deliveryAddress: order.pickupPoint.label,
      pickupPointId: order.pickupPointId,
      paymentMethod: order.paymentMethod
        ? `${order.paymentMethod.brand} •••• ${order.paymentMethod.last4}`
        : 'Apple Pay',
      promoCode: order.promoCode ?? '',
      deliveryFee: 0,
      discountAmount: Number(order.discountAmount),
    };
  }

  private toSupportTicket(ticket: {
    id: string;
    subject: string;
    message: string;
    channel: string;
    createdAt: Date;
    status: PrismaSupportStatus;
  }): SupportTicket {
    return {
      id: ticket.id,
      subject: ticket.subject,
      message: ticket.message,
      channel: ticket.channel,
      createdAtLabel: this.formatDateLabel(ticket.createdAt),
      status: this.translateSupportStatus(ticket.status),
    };
  }

  private toEventTicket(ticket: TicketRecord): EventTicket {
    return {
      id: ticket.id,
      title: ticket.event.title,
      venue: ticket.event.venue,
      dateLabel: this.formatEventDateLabel(ticket.event.startsAt),
      timeLabel: this.formatClockLabel(ticket.event.startsAt),
      zone: ticket.zone ?? 'VIP',
      seat: ticket.seat ?? 'A12',
      gate: ticket.gate ?? 'G3',
      code: ticket.qrCode,
      image:
        ticket.event.imageUrl ??
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
      pointsCost: ticket.event.pointsCost,
    };
  }

  private toInventoryItemPayload(stock: StockRecord) {
    const item: ProductRecord = {
      id: stock.productId,
      vendorId: stock.vendorId,
      vendorName: stock.vendor.name,
      title: stock.product.title,
      description: stock.product.description ?? '',
      imageUrl: stock.product.imageUrl ?? '',
      category: stock.product.kind,
      unitPrice: Number(stock.product.unitPrice),
      sku: stock.product.sku,
      barcode: stock.product.barcode ?? '',
      externalCode: stock.product.externalCode ?? '',
      locationId: stock.locationId,
      locationLabel: stock.locationLabel,
      trackStock: stock.product.trackStock,
      reorderLevel: stock.product.reorderLevel,
      isArchived: stock.product.isArchived,
      onHand: stock.onHand,
      reserved: stock.reserved,
    };

    return {
      id: item.id,
      vendorId: item.vendorId,
      vendorName: item.vendorName,
      title: item.title,
      description: item.description,
      imageUrl: item.imageUrl,
      category: item.category,
      unitPrice: item.unitPrice,
      sku: item.sku,
      barcode: item.barcode,
      locationId: item.locationId,
      locationLabel: item.locationLabel,
      trackStock: item.trackStock,
      reorderLevel: item.reorderLevel,
      isArchived: item.isArchived,
      onHand: item.onHand,
      reserved: item.reserved,
      stockStatus: {
        isInStock: this.availableQuantity(item) > 0,
        availableQuantity: this.availableQuantity(item),
        lowStock:
          item.trackStock &&
          this.availableQuantity(item) > 0 &&
          this.availableQuantity(item) <= item.reorderLevel,
        canPurchase: !item.isArchived && (!item.trackStock || this.availableQuantity(item) > 0),
      },
      externalCode: item.externalCode,
    };
  }

  private toInventoryMovement(movement: MovementRecord): InventoryMovement {
    return {
      id: movement.id,
      productId: movement.productId,
      productTitle: movement.product.title,
      vendorId: movement.vendorId,
      vendorName: movement.vendor.name,
      type: movement.type as InventoryMovementType,
      quantityDelta: movement.quantityDelta,
      previousOnHand: movement.previousOnHand,
      nextOnHand: movement.nextOnHand,
      previousReserved: movement.previousReserved,
      nextReserved: movement.nextReserved,
      createdAtLabel: this.formatDateLabel(movement.createdAt),
      note: movement.note ?? '',
      orderId: movement.orderId ?? '',
    };
  }

  private toIntegrationPayload(connection: IntegrationRecord): IntegrationConnection {
    return {
      id: connection.id,
      vendorId: connection.vendorId,
      vendorName: connection.vendor.name,
      name: connection.name,
      provider: connection.provider,
      type: connection.type as IntegrationType,
      baseUrl: connection.baseUrl,
      locationId: connection.locationId,
      health: this.toClientIntegrationHealth(connection.health),
      lastSync: connection.syncRuns[0]
        ? this.toSyncRunPayload(connection.syncRuns[0], connection.id)
        : {
            connectionId: connection.id,
            status: 'idle',
            startedAtLabel: '',
            completedAtLabel: '',
            processedCount: 0,
            errorMessage: '',
          },
      skuMappings: this.toSkuMappings(connection.skuMappings),
    };
  }

  private toSyncRunPayload(
    run: {
      status: PrismaSyncRunStatus;
      processedCount: number;
      startedAt: Date;
      completedAt: Date | null;
      errorMessage: string | null;
    },
    connectionId: string,
  ): IntegrationSyncRun {
    return {
      connectionId,
      status:
        run.status === PrismaSyncRunStatus.FAILED
          ? 'failed'
          : run.status === PrismaSyncRunStatus.RUNNING
            ? 'running'
            : run.status === PrismaSyncRunStatus.IDLE
              ? 'idle'
              : 'success',
      startedAtLabel: this.formatDateLabel(run.startedAt),
      completedAtLabel: run.completedAt ? this.formatDateLabel(run.completedAt) : '',
      processedCount: run.processedCount,
      errorMessage: run.errorMessage ?? '',
    };
  }

  private toClientOrderStatus(status: PrismaOrderStatus): OrderStatus {
    if (status === PrismaOrderStatus.COMPLETED) {
      return 'completed';
    }
    if (status === PrismaOrderStatus.CANCELLED) {
      return 'cancelled';
    }
    return 'active';
  }

  private toClientIntegrationHealth(health: PrismaIntegrationHealth): IntegrationHealth {
    if (health === PrismaIntegrationHealth.FAILED) {
      return 'failed';
    }
    if (health === PrismaIntegrationHealth.WARNING) {
      return 'warning';
    }
    return 'healthy';
  }

  private toSkuMappings(value: Prisma.JsonValue): Record<string, string> {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return {};
    }

    return Object.fromEntries(
      Object.entries(value).map(([key, entry]) => [key, String(entry)]),
    );
  }

  private toPrismaOrderStatus(status: OpsOrderStatus) {
    return status as PrismaOrderStatus;
  }

  private isTerminal(status: PrismaOrderStatus) {
    return status === PrismaOrderStatus.COMPLETED || status === PrismaOrderStatus.CANCELLED;
  }

  private etaLabelForStatus(status: OpsOrderStatus) {
    if (status === 'ACCEPTED') {
      return '10 dk';
    }
    if (status === 'PREPARING') {
      return '8 dk';
    }
    if (status === 'READY') {
      return 'Hazır';
    }
    if (status === 'COMPLETED') {
      return 'Tamamlandı';
    }
    if (status === 'CANCELLED') {
      return 'İptal';
    }
    return '12 dk';
  }

  private actionLabelForStatus(status: OpsOrderStatus) {
    if (status === 'READY') {
      return 'Gel-Al Kodunu Gör';
    }
    if (status === 'COMPLETED' || status === 'CANCELLED') {
      return 'Detayları Gör';
    }
    return 'Takibi Gör';
  }

  private timelineLabelForStatus(status: OpsOrderStatus) {
    if (status === 'COMPLETED') {
      return 'Teslim alındı';
    }
    if (status === 'CANCELLED') {
      return 'İptal edildi';
    }
    return 'Operasyon akışı devam ediyor';
  }

  private translateSupportStatus(status: PrismaSupportStatus) {
    if (status === PrismaSupportStatus.OPEN) {
      return 'Açık';
    }
    if (status === PrismaSupportStatus.IN_PROGRESS) {
      return 'İşlemde';
    }
    if (status === PrismaSupportStatus.RESOLVED) {
      return 'Çözüldü';
    }
    return 'Kapandı';
  }

  private vendorStockStatusFromStocks(
    stocks: Array<{
      onHand: number;
      reserved: number;
      reorderLevel: number;
      trackStock: boolean;
      isArchived: boolean;
    }>,
  ): StockStatusPayload {
    const availableQuantity = stocks.reduce(
      (sum, stock) => sum + (stock.trackStock ? Math.max(0, stock.onHand - stock.reserved) : 9999),
      0,
    );
    return {
      isInStock: stocks.some((stock) => !stock.isArchived && Math.max(0, stock.onHand - stock.reserved) > 0),
      availableQuantity,
      lowStock: stocks.some(
        (stock) =>
          stock.trackStock &&
          Math.max(0, stock.onHand - stock.reserved) > 0 &&
          Math.max(0, stock.onHand - stock.reserved) <= stock.reorderLevel,
      ),
      canPurchase: availableQuantity > 0,
    };
  }

  private calculateCheckoutAmount(payload: CreateCheckoutSessionDto) {
    return payload.items.reduce(
      (total, item) => total + item.quantity * (item.unitPrice ?? 90),
      0,
    );
  }

  private calculateCheckoutAmountFromItems(
    items: Array<{ quantity: number; unitPrice?: number }>,
  ) {
    return items.reduce(
      (total, item) => total + item.quantity * (item.unitPrice ?? 90),
      0,
    );
  }

  private availableQuantity(item: {
    trackStock: boolean;
    onHand: number;
    reserved: number;
  }) {
    if (!item.trackStock) {
      return 9999;
    }
    return Math.max(0, item.onHand - item.reserved);
  }

  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private createPickupCode() {
    return randomUUID().replace(/-/g, '').slice(0, 4).toUpperCase();
  }

  private formatDateLabel(date: Date) {
    const formatter = new Intl.DateTimeFormat(TR_LOCALE, {
      timeZone: TIME_ZONE,
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
    const parts = formatter.formatToParts(date);
    const pick = (type: Intl.DateTimeFormatPartTypes) =>
      parts.find((part) => part.type === type)?.value ?? '';
    return `${pick('day')}.${pick('month')}.${pick('year')} • ${pick('hour')}:${pick('minute')}`;
  }

  private formatEventDateLabel(date: Date) {
    return new Intl.DateTimeFormat(TR_LOCALE, {
      timeZone: TIME_ZONE,
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    }).format(date);
  }

  private formatClockLabel(date: Date) {
    return new Intl.DateTimeFormat(TR_LOCALE, {
      timeZone: TIME_ZONE,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(date);
  }
}
