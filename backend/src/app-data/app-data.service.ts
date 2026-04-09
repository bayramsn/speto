import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  FulfillmentMode as PrismaFulfillmentMode,
  IntegrationHealth as PrismaIntegrationHealth,
  IntegrationType as PrismaIntegrationType,
  InventoryMovementType as PrismaInventoryMovementType,
  OrderStatus as PrismaOrderStatus,
  Prisma,
  Role as PrismaRole,
  SupportStatus as PrismaSupportStatus,
  SyncRunStatus as PrismaSyncRunStatus,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';

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

const DEFAULT_SESSION_EMAIL = 'bayram@example.com';
const TR_LOCALE = 'tr-TR';
const TIME_ZONE = 'Europe/Istanbul';

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
    displayName: 'Happy Hour Market Ops',
    phone: '+90 555 040 50 60',
    role: PrismaRole.VENDOR,
    vendorId: 'vendor-happy-hour-market',
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
    subtotal: 185,
    discountAmount: 0,
    totalAmount: 185,
    promoCode: '',
    paymentMethodId: 'pm_demo_001',
    createdAt: new Date('2026-10-24T18:20:00+03:00'),
    items: [
      {
        id: 'ord_demo_001_item_1',
        productId: 'mega-burger-menu',
        title: 'Mega Burger Menü',
        quantity: 1,
        unitPrice: 185,
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
    subtotal: 200,
    discountAmount: 10,
    totalAmount: 190,
    promoCode: 'KAMPUS10',
    paymentMethodId: 'pm_demo_001',
    createdAt: new Date('2026-10-23T21:10:00+03:00'),
    items: [
      {
        id: 'ord_demo_000_item_1',
        productId: 'pepperoni-pizza-slice',
        title: 'Pepperonili Pizza Dilimi',
        quantity: 2,
        unitPrice: 100,
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

type UserRecord = Prisma.UserGetPayload<{}>;
type OrderRecord = Prisma.OrderGetPayload<{ include: typeof orderInclude }>;
type StockRecord = Prisma.InventoryStockGetPayload<{ include: typeof stockInclude }>;
type MovementRecord = Prisma.InventoryMovementGetPayload<{ include: typeof movementInclude }>;
type IntegrationRecord = Prisma.IntegrationConnectionGetPayload<{
  include: typeof integrationInclude;
}>;
type TicketRecord = Prisma.TicketGetPayload<{ include: typeof ticketInclude }>;

@Injectable()
export class AppDataService {
  private currentUserEmail = DEFAULT_SESSION_EMAIL;
  private initializationPromise: Promise<void> | null = null;

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

    await this.prisma.user.create({
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

    this.currentUserEmail = normalizedEmail;
    return this.buildSessionResponse();
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

    this.currentUserEmail = normalizedEmail;
    return this.buildSessionResponse();
  }

  async requestPasswordReset(email: string) {
    await this.ensureInitialized();
    const user = await this.prisma.user.findUnique({
      where: { email: this.normalizeEmail(email) },
      select: { id: true },
    });
    return {
      exists: Boolean(user),
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

    await this.prisma.user.update({
      where: { email: normalizedEmail },
      data: { password },
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
    return {
      capabilities: this.getCapabilities(),
      featured: {
        restaurants: await this.listRestaurants(),
        events: await this.listEvents(),
      },
      snapshot: await this.getSnapshot(),
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

    this.currentUserEmail = nextEmail;
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
    this.currentUserEmail = replacementEmail;
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

  async listRestaurants() {
    await this.ensureInitialized();
    const vendors = await this.prisma.vendor.findMany({
      where: { category: 'Restaurant' },
      include: {
        pickupPoints: true,
        products: {
          where: { isArchived: false, isActive: true },
          orderBy: { createdAt: 'asc' },
          take: 1,
        },
        inventory: true,
      },
      orderBy: { name: 'asc' },
    });

    return vendors.map((vendor) => {
      const marketing = VENDOR_MARKETING[vendor.id] ?? {
        etaMin: 12,
        etaMax: 20,
        ratingValue: 4.7,
        promo: 'Speto Pick-Up',
        studentFriendly: true,
      };
      return {
        id: `restaurant-${vendor.slug}`,
        vendorId: vendor.id,
        title: vendor.name,
        image:
          vendor.products[0]?.imageUrl ??
          'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=1200&q=80',
        cuisine: vendor.products[0]?.kind ?? vendor.category,
        etaMin: marketing.etaMin,
        etaMax: marketing.etaMax,
        ratingValue: marketing.ratingValue,
        promo: marketing.promo,
        studentFriendly: marketing.studentFriendly,
        stockStatus: this.vendorStockStatusFromStocks(
          vendor.inventory.map((stock) => ({
            onHand: stock.onHand,
            reserved: stock.reserved,
            reorderLevel: 0,
            trackStock: true,
            isArchived: false,
          })),
        ),
      } satisfies RestaurantCatalogItem;
    });
  }

  async listEvents() {
    await this.ensureInitialized();
    const events = await this.prisma.event.findMany({
      orderBy: { startsAt: 'asc' },
    });
    return events.map((event) => this.toEventCatalogItem(event));
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
    const rewardPoints = Number((this.calculateCheckoutAmount(payload) * 0.01).toFixed(2));

    const order = await this.prisma.$transaction(async (tx) => {
      const productIds = [...new Set(payload.items.map((item) => item.productId))];
      const stocks = await tx.inventoryStock.findMany({
        where: { productId: { in: productIds } },
        include: stockInclude,
      });
      const stockByProductId = new Map(stocks.map((stock) => [stock.productId, stock]));

      for (const line of payload.items) {
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

      const firstStock = stockByProductId.get(firstLine.productId);
      if (!firstStock) {
        throw new NotFoundException(`Product ${firstLine.productId} not found`);
      }

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
          pickupPointId: payload.pickupPointId,
          fulfillmentMode: PrismaFulfillmentMode.PICKUP,
          status: PrismaOrderStatus.CREATED,
          pickupCode: this.createPickupCode(),
          etaLabel: '12 dk',
          subtotal: this.calculateCheckoutAmount(payload),
          discountAmount: 0,
          totalAmount: this.calculateCheckoutAmount(payload),
          promoCode: payload.promoCode ?? '',
          paymentMethodId: paymentMethod?.id,
          items: {
            create: payload.items.map((item) => ({
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

      for (const line of payload.items) {
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

  async getWallet() {
    await this.ensureInitialized();
    const current = await this.requireCurrentUser();
    const [entries, tickets, favorites] = await Promise.all([
      this.prisma.walletLedgerEntry.findMany({
        where: { userId: current.id },
      }),
      this.prisma.ticket.findMany({
        where: { userId: current.id },
        include: ticketInclude,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.favorite.findMany({
        where: { userId: current.id },
      }),
    ]);

    return {
      balance: entries.reduce((sum, entry) => sum + entry.delta, 0),
      ownedTickets: tickets.map((ticket) => this.toEventTicket(ticket)),
      favoriteRestaurantIds: favorites
        .filter((favorite) => favorite.entityType === 'restaurant')
        .map((favorite) => favorite.entityId),
      favoriteEventIds: favorites
        .filter((favorite) => favorite.entityType === 'event')
        .map((favorite) => favorite.entityId),
      orderRatings: {},
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
    const vendorCount = await this.prisma.vendor.count();
    if (vendorCount > 0) {
      return;
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.vendor.createMany({
        data: DEMO_VENDORS.map((vendor) => ({
          id: vendor.id,
          name: vendor.name,
          slug: vendor.slug,
          category: vendor.category,
        })),
      });

      await tx.pickupPoint.createMany({
        data: DEMO_VENDORS.map((vendor) => ({
          id: vendor.pickupPointId,
          vendorId: vendor.id,
          label: vendor.pickupPointLabel,
          address: vendor.pickupPointLabel,
          isActive: true,
        })),
      });

      await tx.user.createMany({
        data: DEMO_USERS.map((user) => ({
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
        })),
      });

      await tx.savedPlace.createMany({
        data: DEMO_ADDRESSES.map((address) => ({
          id: address.id,
          userId: address.userId,
          label: address.label,
          address: address.address,
          iconKey: address.iconKey,
          isPrimary: address.isPrimary,
        })),
      });

      await tx.paymentMethod.createMany({
        data: DEMO_PAYMENT_METHODS.map((method) => ({
          id: method.id,
          userId: method.userId,
          provider: method.provider,
          providerToken: method.providerToken,
          brand: method.brand,
          last4: method.last4,
          expiryMonth: method.expiryMonth,
          expiryYear: method.expiryYear,
          holderName: method.holderName,
          isDefault: method.isDefault,
        })),
      });

      await tx.product.createMany({
        data: DEMO_PRODUCTS.map((product) => ({
          id: product.id,
          vendorId: product.vendorId,
          title: product.title,
          description: product.description,
          unitPrice: product.unitPrice,
          imageUrl: product.imageUrl,
          kind: product.category,
          sku: product.sku,
          barcode: product.barcode,
          externalCode: product.externalCode,
          trackStock: product.trackStock,
          reorderLevel: product.reorderLevel,
          isArchived: product.isArchived,
          isActive: !product.isArchived,
        })),
      });

      await tx.inventoryStock.createMany({
        data: DEMO_PRODUCTS.map((product) => ({
          productId: product.id,
          vendorId: product.vendorId,
          locationId: product.locationId,
          locationLabel: product.locationLabel,
          onHand: product.onHand,
          reserved: product.reserved,
        })),
      });

      await tx.inventoryMovement.createMany({
        data: DEMO_PRODUCTS.map((product) => ({
          id: `mv_seed_${product.id}`,
          productId: product.id,
          vendorId: product.vendorId,
          type: PrismaInventoryMovementType.RESTOCK,
          quantityDelta: product.onHand,
          previousOnHand: 0,
          nextOnHand: product.onHand,
          previousReserved: 0,
          nextReserved: product.reserved,
          createdAt: new Date('2026-04-08T09:00:00+03:00'),
          note: 'Initial opening balance',
        })),
      });

      await tx.integrationConnection.createMany({
        data: DEMO_INTEGRATIONS.map((connection) => ({
          id: connection.id,
          vendorId: connection.vendorId,
          name: connection.name,
          provider: connection.provider,
          type:
            connection.type === 'ERP'
              ? PrismaIntegrationType.ERP
              : PrismaIntegrationType.POS,
          baseUrl: connection.baseUrl,
          locationId: connection.locationId,
          health:
            connection.health === 'warning'
              ? PrismaIntegrationHealth.WARNING
              : PrismaIntegrationHealth.HEALTHY,
          skuMappings: connection.skuMappings,
        })),
      });

      await tx.integrationSyncRun.createMany({
        data: DEMO_INTEGRATIONS.map((connection) => ({
          connectionId: connection.id,
          status:
            connection.lastSync.status === 'failed'
              ? PrismaSyncRunStatus.FAILED
              : PrismaSyncRunStatus.SUCCESS,
          processedCount: connection.lastSync.processedCount,
          errorMessage: connection.lastSync.errorMessage || null,
          startedAt: connection.lastSync.startedAt,
          completedAt: connection.lastSync.completedAt,
        })),
      });

      await tx.event.createMany({
        data: DEMO_EVENTS.map((event) => ({
          id: event.id,
          vendorId: event.vendorId,
          title: event.title,
          venue: event.venue,
          district: event.district,
          imageUrl: event.imageUrl,
          startsAt: event.startsAt,
          pointsCost: event.pointsCost,
          capacity: event.capacity,
          remainingCount: event.remainingCount,
        })),
      });

      await tx.walletLedgerEntry.createMany({
        data: [...DEMO_WALLET_ENTRIES],
      });

      await tx.supportTicket.createMany({
        data: [...DEMO_SUPPORT_TICKETS],
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
    });
  }

  private async buildSessionResponse() {
    const user = await this.getProfile();
    return {
      user,
      tokens: {
        accessToken: `access-${user.id}`,
        refreshToken: `refresh-${user.id}`,
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

    const normalizedEmail = this.normalizeEmail(this.currentUserEmail);
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
    });
    if (user) {
      return user;
    }

    const fallback = await this.prisma.user.findUnique({
      where: { email: DEFAULT_SESSION_EMAIL },
    });
    if (!fallback) {
      throw new UnauthorizedException('No active session');
    }

    this.currentUserEmail = fallback.email;
    return fallback;
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

  private toAppUser(user: UserRecord): AppUser {
    const role = (user.role === PrismaRole.ADMIN
      ? 'ADMIN'
      : user.role === PrismaRole.VENDOR
        ? 'VENDOR'
        : 'CUSTOMER') satisfies UserRole;
    const vendorScopes =
      role === 'ADMIN'
        ? DEMO_VENDORS.map((vendor) => vendor.id)
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

  private toEventCatalogItem(event: {
    id: string;
    title: string;
    venue: string;
    district: string | null;
    imageUrl: string | null;
    startsAt: Date;
    pointsCost: number;
  }): EventCatalogItem {
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
    };
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
