import { useCallback, useEffect, useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import {
  EmptyState,
  LoadingState,
  Modal,
  PageHeader,
  Panel,
  StatusBadge,
  TextArea,
  TextInput,
} from '../components/ui';
import { useLiveReload } from '../hooks/useLiveReload';
import {
  approvalLabel,
  approvalTone,
  campaignStatusLabel,
  formatCurrency,
  formatDate,
  orderStatusLabel,
  orderStatusTone,
} from '../lib/formatters';
import type {
  AdminCampaign,
  AdminOrder,
  AdminProduct,
  BusinessOverview,
  BusinessProductsResponse,
  BusinessProfileResponse,
  CampaignKind,
  CampaignStatus,
  OrderStatus,
} from '../lib/types';

type ProductDraft = {
  id?: string;
  title: string;
  description: string;
  unitPrice: string;
  category: string;
  sectionId: string;
  imageUrl: string;
  displaySubtitle: string;
  displayBadge: string;
  initialStock: string;
  reorderLevel: string;
  isFeatured: boolean;
  isVisibleInApp: boolean;
  trackStock: boolean;
  isArchived: boolean;
};

type CampaignDraft = {
  id?: string;
  title: string;
  description: string;
  kind: CampaignKind;
  status: CampaignStatus;
  scheduleLabel: string;
  badgeLabel: string;
  discountPercent: string;
  discountedPrice: string;
  startsAt: string;
  endsAt: string;
  productIds: string[];
};

const EMPTY_PRODUCT_DRAFT: ProductDraft = {
  title: '',
  description: '',
  unitPrice: '0',
  category: '',
  sectionId: '',
  imageUrl: '',
  displaySubtitle: '',
  displayBadge: '',
  initialStock: '0',
  reorderLevel: '3',
  isFeatured: false,
  isVisibleInApp: true,
  trackStock: true,
  isArchived: false,
};

const EMPTY_CAMPAIGN_DRAFT: CampaignDraft = {
  title: '',
  description: '',
  kind: 'DISCOUNT',
  status: 'ACTIVE',
  scheduleLabel: '',
  badgeLabel: '',
  discountPercent: '0',
  discountedPrice: '0',
  startsAt: '',
  endsAt: '',
  productIds: [],
};

const TABS = [
  { id: 'overview', label: 'Genel Bakış' },
  { id: 'orders', label: 'Siparişler' },
  { id: 'products', label: 'Ürünler' },
  { id: 'campaigns', label: 'Kampanyalar' },
  { id: 'profile', label: 'Profil' },
] as const;

export function BusinessWorkspace() {
  const { businessId = '', tab = 'overview' } = useParams();
  const isValidTab = TABS.some((item) => item.id === tab);
  const { request } = useAdminAuth();
  const [overview, setOverview] = useState<BusinessOverview | null>(null);
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [productsData, setProductsData] = useState<BusinessProductsResponse | null>(null);
  const [campaigns, setCampaigns] = useState<AdminCampaign[]>([]);
  const [profile, setProfile] = useState<BusinessProfileResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [productModalOpen, setProductModalOpen] = useState(false);
  const [campaignModalOpen, setCampaignModalOpen] = useState(false);
  const [sectionLabel, setSectionLabel] = useState('');
  const [productDraft, setProductDraft] = useState<ProductDraft>(EMPTY_PRODUCT_DRAFT);
  const [campaignDraft, setCampaignDraft] = useState<CampaignDraft>(EMPTY_CAMPAIGN_DRAFT);
  const [profileDraft, setProfileDraft] = useState({
    name: '',
    subtitle: '',
    category: '',
    city: '',
    district: '',
    imageUrl: '',
    announcement: '',
    workingHoursLabel: '',
    pickupPointLabel: '',
    pickupPointAddress: '',
  });
  const [pickupDraft, setPickupDraft] = useState({ label: '', address: '' });
  const [operatorDraft, setOperatorDraft] = useState({
    email: '',
    displayName: '',
    phone: '',
    password: '',
  });
  const [bankDraft, setBankDraft] = useState({
    holderName: '',
    bankName: '',
    iban: '',
    isDefault: false,
  });

  const loadOverview = useCallback(async () => {
    const next = await request<BusinessOverview>(`/admin/businesses/${businessId}/overview`);
    setOverview(next);
  }, [businessId, request]);

  const loadOrders = useCallback(async () => {
    const next = await request<AdminOrder[]>(`/admin/businesses/${businessId}/orders`);
    setOrders(next);
  }, [businessId, request]);

  const loadProducts = useCallback(async () => {
    const next = await request<BusinessProductsResponse>(
      `/admin/businesses/${businessId}/products`,
    );
    setProductsData(next);
  }, [businessId, request]);

  const loadCampaigns = useCallback(async () => {
    const next = await request<AdminCampaign[]>(`/admin/businesses/${businessId}/campaigns`);
    setCampaigns(next);
  }, [businessId, request]);

  const loadProfile = useCallback(async () => {
    const next = await request<BusinessProfileResponse>(
      `/admin/businesses/${businessId}/profile`,
    );
    setProfile(next);
    setProfileDraft({
      name: next.business.name,
      subtitle: next.subtitle,
      category: next.business.category,
      city: next.city,
      district: next.district,
      imageUrl: next.imageUrl,
      announcement: next.announcement,
      workingHoursLabel: next.workingHoursLabel,
      pickupPointLabel: next.pickupPoints[0]?.label ?? '',
      pickupPointAddress: next.pickupPoints[0]?.address ?? '',
    });
  }, [businessId, request]);

  const loadCurrentTab = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      await loadProfile();
      if (tab === 'overview') {
        await loadOverview();
      } else if (tab === 'orders') {
        await loadOrders();
      } else if (tab === 'products') {
        await loadProducts();
      } else if (tab === 'campaigns') {
        await Promise.all([loadCampaigns(), loadProducts()]);
      }
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'İşletme verisi alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [loadCampaigns, loadOrders, loadOverview, loadProducts, loadProfile, tab]);

  useEffect(() => {
    if (!businessId || !isValidTab) {
      return;
    }
    void loadCurrentTab();
  }, [businessId, isValidTab, loadCurrentTab]);
  useLiveReload(loadCurrentTab, { enabled: Boolean(businessId) && isValidTab });

  async function updateOrderStatus(orderId: string, status: OrderStatus) {
    await request(`/admin/businesses/${businessId}/orders/${orderId}/status`, {
      method: 'PATCH',
      body: { status },
    });
    await loadOrders();
  }

  function openProductModal(product?: AdminProduct) {
    if (product) {
      setProductDraft({
        id: product.id,
        title: product.title,
        description: product.description,
        unitPrice: String(product.unitPrice),
        category: product.category,
        sectionId: product.sectionId,
        imageUrl: product.imageUrl,
        displaySubtitle: product.displaySubtitle,
        displayBadge: product.displayBadge,
        initialStock: String(product.availableQuantity + product.reservedQuantity),
        reorderLevel: String(product.reorderLevel),
        isFeatured: product.isFeatured,
        isVisibleInApp: product.isVisibleInApp,
        trackStock: product.trackStock,
        isArchived: product.isArchived,
      });
    } else {
      setProductDraft({
        ...EMPTY_PRODUCT_DRAFT,
        category: productsData?.categories[0] ?? overview?.business.category ?? 'Genel',
        sectionId: productsData?.sections[0]?.id ?? '',
      });
    }
    setProductModalOpen(true);
  }

  async function saveProduct() {
    if (!productDraft.title.trim()) {
      setError('Ürün adı zorunludur.');
      return;
    }
    if (Number(productDraft.unitPrice) <= 0) {
      setError('Ürün fiyatı sıfırdan büyük olmalıdır.');
      return;
    }
    if (productDraft.trackStock && Number(productDraft.initialStock) < 0) {
      setError('İlk stok negatif olamaz.');
      return;
    }
    if (Number(productDraft.reorderLevel) < 0) {
      setError('Reorder level negatif olamaz.');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const payload = {
        ...productDraft,
        unitPrice: Number(productDraft.unitPrice),
        initialStock: Number(productDraft.initialStock),
        reorderLevel: Number(productDraft.reorderLevel),
      };
      if (productDraft.id) {
        await request(`/admin/businesses/${businessId}/products/${productDraft.id}`, {
          method: 'PATCH',
          body: payload,
        });
      } else {
        await request(`/admin/businesses/${businessId}/products`, {
          method: 'POST',
          body: payload,
        });
      }
      setProductModalOpen(false);
      setProductDraft(EMPTY_PRODUCT_DRAFT);
      await loadProducts();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Ürün kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function createSection() {
    if (!sectionLabel.trim()) {
      return;
    }
    await request(`/admin/businesses/${businessId}/sections`, {
      method: 'POST',
      body: { label: sectionLabel },
    });
    setSectionLabel('');
    await loadProducts();
  }

  async function updateSection(
    sectionId: string,
    payload: { label?: string; isActive?: boolean; displayOrder?: number },
  ) {
    await request(`/admin/businesses/${businessId}/sections/${sectionId}`, {
      method: 'PATCH',
      body: payload,
    });
    await loadProducts();
  }

  async function archiveProduct(product: AdminProduct) {
    if (!window.confirm(`${product.title} ürünü arşivlenecek. Onaylıyor musunuz?`)) {
      return;
    }
    await request(`/admin/businesses/${businessId}/products/${product.id}`, {
      method: 'DELETE',
    });
    await loadProducts();
  }

  function openCampaignModal(campaign?: AdminCampaign) {
    if (campaign) {
      setCampaignDraft({
        id: campaign.id,
        title: campaign.title,
        description: campaign.description,
        kind: campaign.kind,
        status: campaign.status,
        scheduleLabel: campaign.scheduleLabel,
        badgeLabel: campaign.badgeLabel,
        discountPercent: String(campaign.discountPercent),
        discountedPrice: String(campaign.discountedPrice),
        startsAt: campaign.startsAt?.slice(0, 16) ?? '',
        endsAt: campaign.endsAt?.slice(0, 16) ?? '',
        productIds: campaign.productIds,
      });
    } else {
      setCampaignDraft(EMPTY_CAMPAIGN_DRAFT);
    }
    setCampaignModalOpen(true);
  }

  async function saveCampaign() {
    if (!campaignDraft.title.trim()) {
      setError('Kampanya başlığı zorunludur.');
      return;
    }
    if (
      campaignDraft.startsAt &&
      campaignDraft.endsAt &&
      new Date(campaignDraft.startsAt).getTime() > new Date(campaignDraft.endsAt).getTime()
    ) {
      setError('Kampanya bitiş tarihi başlangıç tarihinden önce olamaz.');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const payload = {
        ...campaignDraft,
        discountPercent: Number(campaignDraft.discountPercent),
        discountedPrice: Number(campaignDraft.discountedPrice),
        startsAt: campaignDraft.startsAt || null,
        endsAt: campaignDraft.endsAt || null,
      };
      if (campaignDraft.id) {
        await request(`/admin/businesses/${businessId}/campaigns/${campaignDraft.id}`, {
          method: 'PATCH',
          body: payload,
        });
      } else {
        await request(`/admin/businesses/${businessId}/campaigns`, {
          method: 'POST',
          body: payload,
        });
      }
      setCampaignModalOpen(false);
      setCampaignDraft(EMPTY_CAMPAIGN_DRAFT);
      await loadCampaigns();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Kampanya kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function toggleCampaign(campaignId: string) {
    await request(`/admin/businesses/${businessId}/campaigns/${campaignId}/toggle`, {
      method: 'POST',
      body: {},
    });
    await loadCampaigns();
  }

  async function deleteCampaign(campaign: AdminCampaign) {
    if (!window.confirm(`${campaign.title} kampanyası silinecek. Onaylıyor musunuz?`)) {
      return;
    }
    await request(`/admin/businesses/${businessId}/campaigns/${campaign.id}`, {
      method: 'DELETE',
    });
    await loadCampaigns();
  }

  async function saveProfile() {
    setSaving(true);
    setError('');
    try {
      await request(`/admin/businesses/${businessId}/profile`, {
        method: 'PATCH',
        body: profileDraft,
      });
      await loadProfile();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Profil kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function createPickupPoint() {
    setSaving(true);
    setError('');
    try {
      await request(`/admin/businesses/${businessId}/pickup-points`, {
        method: 'POST',
        body: pickupDraft,
      });
      setPickupDraft({ label: '', address: '' });
      await loadProfile();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Teslim noktası kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function updatePickupPoint(pointId: string, isActive: boolean) {
    await request(`/admin/businesses/${businessId}/pickup-points/${pointId}`, {
      method: 'PATCH',
      body: { isActive },
    });
    await loadProfile();
  }

  async function createOperator() {
    setSaving(true);
    setError('');
    try {
      await request(`/admin/businesses/${businessId}/operators`, {
        method: 'POST',
        body: operatorDraft,
      });
      setOperatorDraft({ email: '', displayName: '', phone: '', password: '' });
      await loadProfile();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Operatör kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function createBankAccount() {
    setSaving(true);
    setError('');
    try {
      await request(`/admin/businesses/${businessId}/bank-accounts`, {
        method: 'POST',
        body: bankDraft,
      });
      setBankDraft({ holderName: '', bankName: '', iban: '', isDefault: false });
      await loadProfile();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Banka hesabı kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  if (!isValidTab) {
    return <Navigate replace to={`/businesses/${businessId}/overview`} />;
  }

  if (loading) {
    return <LoadingState label="İşletme çalışma alanı hazırlanıyor..." />;
  }

  const title =
    overview?.business.name ||
    profile?.business.name ||
    productsData?.products[0]?.vendorId ||
    'İşletme';

  return (
    <div className="space-y-8">
      <div className="flex items-center gap-3 text-sm text-slate-500">
        <Link className="hover:text-primary" to="/businesses">
          İşletmeler
        </Link>
        <span>/</span>
        <span>{title}</span>
      </div>

      <PageHeader
        title={title}
        description="Admin god-mode ile işletme operasyonlarının içine inin ve veriyi doğrudan düzenleyin."
      />

      {overview?.business || profile?.business ? (
        <div className="flex flex-wrap items-center gap-3">
          <StatusBadge
            label={approvalLabel((overview?.business || profile?.business)!.approvalStatus)}
            tone={approvalTone((overview?.business || profile?.business)!.approvalStatus)}
          />
          <StatusBadge
            label={(overview?.business || profile?.business)!.isActive ? 'Yayında' : 'Pasif'}
            tone={(overview?.business || profile?.business)!.isActive ? 'success' : 'default'}
          />
        </div>
      ) : null}

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <div className="flex flex-wrap gap-2">
        {TABS.map((item) => (
          <Link
            className={`rounded-full px-4 py-2 text-sm font-semibold transition-colors ${
              tab === item.id
                ? 'bg-primary text-white'
                : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'
            }`}
            key={item.id}
            to={`/businesses/${businessId}/${item.id}`}
          >
            {item.label}
          </Link>
        ))}
      </div>

      {tab === 'overview' && overview ? (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-5 gap-5">
            <Panel>
              <div className="text-sm text-slate-500">Toplam Ciro</div>
              <div className="mt-3 text-3xl font-black font-headline">{formatCurrency(overview.metrics.grossRevenue)}</div>
            </Panel>
            <Panel>
              <div className="text-sm text-slate-500">Sipariş</div>
              <div className="mt-3 text-3xl font-black font-headline">{overview.metrics.totalOrders}</div>
            </Panel>
            <Panel>
              <div className="text-sm text-slate-500">Aktif Sipariş</div>
              <div className="mt-3 text-3xl font-black font-headline">{overview.metrics.activeOrders}</div>
            </Panel>
            <Panel>
              <div className="text-sm text-slate-500">Ürün</div>
              <div className="mt-3 text-3xl font-black font-headline">{overview.metrics.totalProducts}</div>
            </Panel>
            <Panel>
              <div className="text-sm text-slate-500">Düşük Stok</div>
              <div className="mt-3 text-3xl font-black font-headline">{overview.metrics.lowStockProducts}</div>
            </Panel>
          </div>

          <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <Panel title="Son Siparişler">
              {overview.recentOrders.length === 0 ? (
                <EmptyState message="Henüz sipariş bulunmuyor." />
              ) : (
                <div className="space-y-4">
                  {overview.recentOrders.map((order) => (
                    <div className="rounded-2xl border border-slate-100 p-4" key={order.id}>
                      <div className="flex items-center justify-between gap-4">
                        <div>
                          <p className="font-bold">{order.userName}</p>
                          <p className="text-sm text-slate-500">{formatDate(order.createdAt)}</p>
                        </div>
                        <StatusBadge
                          label={orderStatusLabel(order.status)}
                          tone={orderStatusTone(order.status)}
                        />
                      </div>
                      <p className="mt-3 text-sm text-slate-700">
                        {order.items.map((item) => `${item.title} x${item.quantity}`).join(', ')}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </Panel>
            <Panel title="Düşük Stoklu Ürünler">
              {overview.lowStockProducts.length === 0 ? (
                <EmptyState message="Düşük stok alarmı yok." />
              ) : (
                <div className="space-y-4">
                  {overview.lowStockProducts.map((product) => (
                    <div className="rounded-2xl border border-slate-100 p-4" key={product.id}>
                      <div className="flex items-center justify-between gap-4">
                        <div>
                          <p className="font-bold">{product.title}</p>
                          <p className="text-sm text-slate-500">{product.sectionLabel || product.category}</p>
                        </div>
                        <StatusBadge
                          label={`${product.availableQuantity} adet`}
                          tone={product.availableQuantity === 0 ? 'danger' : 'warning'}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Panel>
          </div>
        </div>
      ) : null}

      {tab === 'orders' ? (
        <Panel title="İşletme Siparişleri">
          {orders.length === 0 ? (
            <EmptyState message="Sipariş bulunmuyor." />
          ) : (
            <div className="space-y-4">
              {orders.map((order) => (
                <div className="rounded-2xl border border-slate-100 p-5" key={order.id}>
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                      <div className="flex items-center gap-3">
                        <h3 className="font-bold">{order.userName}</h3>
                        <StatusBadge
                          label={orderStatusLabel(order.status)}
                          tone={orderStatusTone(order.status)}
                        />
                      </div>
                      <p className="mt-2 text-sm text-slate-500">
                        {formatDate(order.createdAt)} · {order.pickupCode}
                      </p>
                      <p className="mt-3 text-sm text-slate-700">
                        {order.items.map((item) => `${item.title} x${item.quantity}`).join(', ')}
                      </p>
                    </div>
                    <div className="w-full max-w-xs">
                      <p className="text-sm font-bold text-right">{formatCurrency(order.totalAmount)}</p>
                      <select
                        className="mt-3 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
                        onChange={(event) =>
                          void updateOrderStatus(order.id, event.target.value as OrderStatus)
                        }
                        value={order.status}
                      >
                        {['CREATED', 'ACCEPTED', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED'].map((status) => (
                          <option key={status} value={status}>
                            {orderStatusLabel(status as OrderStatus)}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Panel>
      ) : null}

      {tab === 'products' ? (
        <div className="space-y-6">
          <Panel
            title="Kategori ve Bölüm"
            action={
              <button
                className="rounded-2xl bg-primary text-white px-4 py-2 text-sm font-bold hover:bg-emerald-700"
                onClick={() => openProductModal()}
                type="button"
              >
                Yeni Ürün
              </button>
            }
          >
            <div className="grid grid-cols-1 md:grid-cols-[1fr_auto] gap-4">
              <TextInput
                label="Yeni Bölüm Adı"
                onChange={setSectionLabel}
                value={sectionLabel}
              />
              <button
                className="rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold mt-8 hover:bg-slate-50"
                onClick={() => void createSection()}
                type="button"
              >
                Bölüm Oluştur
              </button>
            </div>
            <div className="mt-4 flex flex-wrap gap-2">
              {productsData?.sections.map((section) => (
                <div className="flex items-center gap-2 rounded-2xl border border-slate-100 px-3 py-2" key={section.id}>
                  <StatusBadge label={section.label} tone={section.isActive ? 'info' : 'default'} />
                  <button
                    className="text-xs font-bold text-slate-500 hover:text-primary"
                    onClick={() =>
                      void updateSection(section.id, {
                        isActive: !section.isActive,
                      })
                    }
                    type="button"
                  >
                    {section.isActive ? 'Pasifleştir' : 'Aktifleştir'}
                  </button>
                  <button
                    className="text-xs font-bold text-slate-500 hover:text-primary"
                    onClick={() => {
                      const label = window.prompt('Yeni bölüm adı', section.label);
                      if (label) {
                        void updateSection(section.id, { label });
                      }
                    }}
                    type="button"
                    >
                      Düzenle
                    </button>
                  <button
                    className="text-xs font-bold text-slate-500 hover:text-primary"
                    onClick={() =>
                      void updateSection(section.id, {
                        displayOrder: Math.max(0, section.displayOrder - 1),
                      })
                    }
                    type="button"
                  >
                    Yukarı
                  </button>
                  <button
                    className="text-xs font-bold text-slate-500 hover:text-primary"
                    onClick={() =>
                      void updateSection(section.id, {
                        displayOrder: section.displayOrder + 1,
                      })
                    }
                    type="button"
                  >
                    Aşağı
                  </button>
                </div>
              ))}
            </div>
          </Panel>

          <Panel title="Ürünler">
            {productsData?.products.length ? (
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                {productsData.products.map((product) => (
                  <div className="rounded-2xl border border-slate-100 p-5" key={product.id}>
                    <div className="flex gap-4">
                      <div className="w-24 h-24 rounded-2xl bg-slate-100 overflow-hidden shrink-0">
                        {product.imageUrl ? (
                          <img
                            alt={product.title}
                            className="w-full h-full object-cover"
                            src={product.imageUrl}
                          />
                        ) : null}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <p className="font-bold">{product.title}</p>
                            <p className="text-sm text-slate-500">
                              {product.sectionLabel || product.category}
                            </p>
                          </div>
                          <button
                            className="rounded-2xl border border-slate-200 px-3 py-2 text-sm font-semibold hover:bg-slate-50"
                            onClick={() => openProductModal(product)}
                            type="button"
                          >
                            Düzenle
                          </button>
                          <button
                            className="rounded-2xl border border-red-200 px-3 py-2 text-sm font-semibold text-red-700 hover:bg-red-50"
                            onClick={() => void archiveProduct(product)}
                            type="button"
                          >
                            Arşivle
                          </button>
                        </div>
                        <p className="mt-3 text-sm text-slate-700">{product.description}</p>
                        <div className="mt-4 flex flex-wrap items-center gap-3">
                          <StatusBadge
                            label={formatCurrency(product.unitPrice)}
                            tone="success"
                          />
                          <StatusBadge
                            label={`Stok ${product.availableQuantity}`}
                            tone={product.availableQuantity === 0 ? 'danger' : 'info'}
                          />
                          {product.displayBadge ? <StatusBadge label={product.displayBadge} tone="warning" /> : null}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState message="Ürün bulunmuyor." />
            )}
          </Panel>
        </div>
      ) : null}

      {tab === 'campaigns' ? (
        <Panel
          title="Kampanyalar"
          action={
            <button
              className="rounded-2xl bg-primary text-white px-4 py-2 text-sm font-bold hover:bg-emerald-700"
              onClick={() => openCampaignModal()}
              type="button"
            >
              Yeni Kampanya
            </button>
          }
        >
          {campaigns.length === 0 ? (
            <EmptyState message="Kampanya bulunmuyor." />
          ) : (
            <div className="space-y-4">
              {campaigns.map((campaign) => (
                <div className="rounded-2xl border border-slate-100 p-5" key={campaign.id}>
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                      <div className="flex items-center gap-3">
                        <h3 className="font-bold">{campaign.title}</h3>
                        <StatusBadge
                          label={campaignStatusLabel(campaign.status)}
                          tone={campaign.status === 'ACTIVE' ? 'success' : 'default'}
                        />
                      </div>
                      <p className="mt-2 text-sm text-slate-500">{campaign.scheduleLabel}</p>
                      <p className="mt-3 text-sm text-slate-700">{campaign.description}</p>
                      <p className="mt-3 text-sm text-slate-500">
                        {campaign.productTitles.join(', ') || 'Ürün bağlı değil'}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <button
                        className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                        onClick={() => openCampaignModal(campaign)}
                        type="button"
                      >
                        Düzenle
                      </button>
                      <button
                        className="rounded-2xl border border-amber-200 px-4 py-2 text-sm font-semibold text-amber-700 hover:bg-amber-50"
                        onClick={() => void toggleCampaign(campaign.id)}
                        type="button"
                      >
                        Toggle
                      </button>
                      <button
                        className="rounded-2xl border border-red-200 px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-50"
                        onClick={() => void deleteCampaign(campaign)}
                        type="button"
                      >
                        Sil
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Panel>
      ) : null}

      {tab === 'profile' ? (
        <Panel
          title="İşletme Profili"
          action={
            <button
              className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
              disabled={saving}
              onClick={() => void saveProfile()}
              type="button"
            >
              {saving ? 'Kaydediliyor...' : 'Profili Kaydet'}
            </button>
          }
        >
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <TextInput
              label="İşletme Adı"
              onChange={(value) => setProfileDraft((current) => ({ ...current, name: value }))}
              value={profileDraft.name}
            />
            <TextInput
              label="Alt Başlık"
              onChange={(value) => setProfileDraft((current) => ({ ...current, subtitle: value }))}
              value={profileDraft.subtitle}
            />
            <TextInput
              label="Kategori"
              onChange={(value) => setProfileDraft((current) => ({ ...current, category: value }))}
              value={profileDraft.category}
            />
            <TextInput
              label="Çalışma Saatleri"
              onChange={(value) =>
                setProfileDraft((current) => ({ ...current, workingHoursLabel: value }))
              }
              value={profileDraft.workingHoursLabel}
            />
            <TextInput
              label="Şehir"
              onChange={(value) => setProfileDraft((current) => ({ ...current, city: value }))}
              value={profileDraft.city}
            />
            <TextInput
              label="İlçe"
              onChange={(value) => setProfileDraft((current) => ({ ...current, district: value }))}
              value={profileDraft.district}
            />
            <TextInput
              label="Görsel URL"
              onChange={(value) => setProfileDraft((current) => ({ ...current, imageUrl: value }))}
              value={profileDraft.imageUrl}
            />
            <TextInput
              label="Pickup Etiketi"
              onChange={(value) =>
                setProfileDraft((current) => ({ ...current, pickupPointLabel: value }))
              }
              value={profileDraft.pickupPointLabel}
            />
            <TextInput
              label="Pickup Adresi"
              onChange={(value) =>
                setProfileDraft((current) => ({ ...current, pickupPointAddress: value }))
              }
              value={profileDraft.pickupPointAddress}
            />
          </div>
          <div className="mt-5">
            <TextArea
              label="Duyuru"
              onChange={(value) =>
                setProfileDraft((current) => ({ ...current, announcement: value }))
              }
              value={profileDraft.announcement}
            />
          </div>
          {profile ? (
            <div className="mt-8 space-y-6">
              <Panel title="Teslim Noktaları">
                <div className="space-y-3">
                  {profile.pickupPoints.map((point) => (
                    <div className="flex flex-col gap-3 rounded-2xl border border-slate-100 p-4 md:flex-row md:items-center md:justify-between" key={point.id}>
                      <div>
                        <p className="font-bold">{point.label}</p>
                        <p className="text-sm text-slate-500">{point.address}</p>
                      </div>
                      <button
                        className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold"
                        onClick={() => void updatePickupPoint(point.id, !point.isActive)}
                        type="button"
                      >
                        {point.isActive ? 'Pasifleştir' : 'Aktifleştir'}
                      </button>
                    </div>
                  ))}
                </div>
                <div className="mt-5 grid grid-cols-1 gap-4 md:grid-cols-[1fr_1fr_auto]">
                  <TextInput label="Yeni Etiket" onChange={(value) => setPickupDraft((current) => ({ ...current, label: value }))} value={pickupDraft.label} />
                  <TextInput label="Yeni Adres" onChange={(value) => setPickupDraft((current) => ({ ...current, address: value }))} value={pickupDraft.address} />
                  <button
                    className="mt-8 rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-white disabled:opacity-60"
                    disabled={saving || !pickupDraft.label || !pickupDraft.address}
                    onClick={() => void createPickupPoint()}
                    type="button"
                  >
                    Ekle
                  </button>
                </div>
              </Panel>
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
              <Panel title="Operatörler">
                {profile.operators.length === 0 ? (
                  <EmptyState message="Operatör bulunmuyor." />
                ) : (
                  <div className="space-y-4">
                    {profile.operators.map((operator) => (
                      <div className="rounded-2xl border border-slate-100 p-4" key={operator.id}>
                        <p className="font-bold">{operator.displayName}</p>
                        <p className="text-sm text-slate-500">{operator.email}</p>
                      </div>
                    ))}
                  </div>
                )}
                <div className="mt-5 grid grid-cols-1 gap-4 md:grid-cols-2">
                  <TextInput label="E-posta" onChange={(value) => setOperatorDraft((current) => ({ ...current, email: value }))} value={operatorDraft.email} />
                  <TextInput label="Ad Soyad" onChange={(value) => setOperatorDraft((current) => ({ ...current, displayName: value }))} value={operatorDraft.displayName} />
                  <TextInput label="Telefon" onChange={(value) => setOperatorDraft((current) => ({ ...current, phone: value }))} value={operatorDraft.phone} />
                  <TextInput label="Geçici Şifre" onChange={(value) => setOperatorDraft((current) => ({ ...current, password: value }))} type="password" value={operatorDraft.password} />
                </div>
                <div className="mt-4 flex justify-end">
                  <button
                    className="rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-white disabled:opacity-60"
                    disabled={saving || !operatorDraft.email || !operatorDraft.displayName || !operatorDraft.password}
                    onClick={() => void createOperator()}
                    type="button"
                  >
                    Operatör Ekle
                  </button>
                </div>
              </Panel>
              <Panel title="Banka Hesapları">
                {profile.bankAccounts.length === 0 ? (
                  <EmptyState message="Banka hesabı bulunmuyor." />
                ) : (
                  <div className="space-y-4">
                    {profile.bankAccounts.map((account) => (
                      <div className="rounded-2xl border border-slate-100 p-4" key={account.id}>
                        <div className="flex items-center justify-between gap-4">
                          <div>
                            <p className="font-bold">{account.bankName}</p>
                            <p className="text-sm text-slate-500">{account.iban}</p>
                          </div>
                          {account.isDefault ? <StatusBadge label="Varsayılan" tone="success" /> : null}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
                <div className="mt-5 grid grid-cols-1 gap-4 md:grid-cols-2">
                  <TextInput label="Hesap Sahibi" onChange={(value) => setBankDraft((current) => ({ ...current, holderName: value }))} value={bankDraft.holderName} />
                  <TextInput label="Banka" onChange={(value) => setBankDraft((current) => ({ ...current, bankName: value }))} value={bankDraft.bankName} />
                  <TextInput label="IBAN" onChange={(value) => setBankDraft((current) => ({ ...current, iban: value }))} value={bankDraft.iban} />
                  <label className="mt-8 flex items-center gap-3">
                    <input
                      checked={bankDraft.isDefault}
                      onChange={(event) => setBankDraft((current) => ({ ...current, isDefault: event.target.checked }))}
                      type="checkbox"
                    />
                    <span className="text-sm font-semibold text-slate-600">Varsayılan</span>
                  </label>
                </div>
                <div className="mt-4 flex justify-end">
                  <button
                    className="rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-white disabled:opacity-60"
                    disabled={saving || !bankDraft.holderName || !bankDraft.bankName || !bankDraft.iban}
                    onClick={() => void createBankAccount()}
                    type="button"
                  >
                    Banka Hesabı Ekle
                  </button>
                </div>
              </Panel>
              </div>
            </div>
          ) : null}
        </Panel>
      ) : null}

      <Modal
        open={productModalOpen}
        onClose={() => setProductModalOpen(false)}
        title={productDraft.id ? 'Ürünü Düzenle' : 'Yeni Ürün'}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="Ürün Adı"
            onChange={(value) => setProductDraft((current) => ({ ...current, title: value }))}
            value={productDraft.title}
          />
          <TextInput
            label="Fiyat"
            onChange={(value) => setProductDraft((current) => ({ ...current, unitPrice: value }))}
            type="number"
            value={productDraft.unitPrice}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Kategori</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setProductDraft((current) => ({ ...current, category: event.target.value }))
              }
              value={productDraft.category}
            >
              {(productsData?.categories ?? []).map((category) => (
                <option key={category} value={category}>
                  {category}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Bölüm</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setProductDraft((current) => ({ ...current, sectionId: event.target.value }))
              }
              value={productDraft.sectionId}
            >
              <option value="">Bölüm Yok</option>
              {(productsData?.sections ?? []).map((section) => (
                <option key={section.id} value={section.id}>
                  {section.label}
                </option>
              ))}
            </select>
          </label>
          <TextInput
            label="Alt Başlık"
            onChange={(value) =>
              setProductDraft((current) => ({ ...current, displaySubtitle: value }))
            }
            value={productDraft.displaySubtitle}
          />
          <TextInput
            label="Rozet"
            onChange={(value) => setProductDraft((current) => ({ ...current, displayBadge: value }))}
            value={productDraft.displayBadge}
          />
          <TextInput
            label="Görsel URL"
            onChange={(value) => setProductDraft((current) => ({ ...current, imageUrl: value }))}
            value={productDraft.imageUrl}
          />
          <p className="rounded-2xl border border-amber-100 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            Dosya yükleme provider-ready durumda. Şimdilik CDN veya güvenli public görsel URL'i girin.
          </p>
          <TextInput
            label="İlk Stok"
            onChange={(value) => setProductDraft((current) => ({ ...current, initialStock: value }))}
            type="number"
            value={productDraft.initialStock}
          />
          <TextInput
            label="Reorder Level"
            onChange={(value) => setProductDraft((current) => ({ ...current, reorderLevel: value }))}
            type="number"
            value={productDraft.reorderLevel}
          />
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={productDraft.isVisibleInApp}
              onChange={(event) =>
                setProductDraft((current) => ({
                  ...current,
                  isVisibleInApp: event.target.checked,
                }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Uygulamada görünür</span>
          </label>
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={productDraft.trackStock}
              onChange={(event) =>
                setProductDraft((current) => ({ ...current, trackStock: event.target.checked }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Stok takibi aktif</span>
          </label>
          <label className="flex items-center gap-3">
            <input
              checked={productDraft.isFeatured}
              onChange={(event) =>
                setProductDraft((current) => ({ ...current, isFeatured: event.target.checked }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Öne çıkan ürün</span>
          </label>
          <label className="flex items-center gap-3">
            <input
              checked={productDraft.isArchived}
              onChange={(event) =>
                setProductDraft((current) => ({ ...current, isArchived: event.target.checked }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Arşivlenmiş</span>
          </label>
        </div>
        <div className="mt-5">
          <TextArea
            label="Açıklama"
            onChange={(value) => setProductDraft((current) => ({ ...current, description: value }))}
            value={productDraft.description}
          />
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveProduct()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Kaydet'}
          </button>
        </div>
      </Modal>

      <Modal
        open={campaignModalOpen}
        onClose={() => setCampaignModalOpen(false)}
        title={campaignDraft.id ? 'Kampanyayı Düzenle' : 'Yeni Kampanya'}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="Başlık"
            onChange={(value) => setCampaignDraft((current) => ({ ...current, title: value }))}
            value={campaignDraft.title}
          />
          <TextInput
            label="Zaman"
            onChange={(value) =>
              setCampaignDraft((current) => ({ ...current, scheduleLabel: value }))
            }
            value={campaignDraft.scheduleLabel}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Tür</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setCampaignDraft((current) => ({ ...current, kind: event.target.value as CampaignKind }))
              }
              value={campaignDraft.kind}
            >
              {['HAPPY_HOUR', 'DISCOUNT', 'CLEARANCE', 'BUNDLE'].map((kind) => (
                <option key={kind} value={kind}>
                  {kind}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Durum</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setCampaignDraft((current) => ({ ...current, status: event.target.value as CampaignStatus }))
              }
              value={campaignDraft.status}
            >
              {['DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED'].map((status) => (
                <option key={status} value={status}>
                  {status}
                </option>
              ))}
            </select>
          </label>
          <TextInput
            label="İndirim %"
            onChange={(value) =>
              setCampaignDraft((current) => ({ ...current, discountPercent: value }))
            }
            type="number"
            value={campaignDraft.discountPercent}
          />
          <TextInput
            label="İndirimli Fiyat"
            onChange={(value) =>
              setCampaignDraft((current) => ({ ...current, discountedPrice: value }))
            }
            type="number"
            value={campaignDraft.discountedPrice}
          />
          <TextInput
            label="Rozet"
            onChange={(value) => setCampaignDraft((current) => ({ ...current, badgeLabel: value }))}
            value={campaignDraft.badgeLabel}
          />
          <TextInput
            label="Başlangıç"
            onChange={(value) => setCampaignDraft((current) => ({ ...current, startsAt: value }))}
            type="datetime-local"
            value={campaignDraft.startsAt}
          />
          <TextInput
            label="Bitiş"
            onChange={(value) => setCampaignDraft((current) => ({ ...current, endsAt: value }))}
            type="datetime-local"
            value={campaignDraft.endsAt}
          />
        </div>
        <div className="mt-5">
          <TextArea
            label="Açıklama"
            onChange={(value) => setCampaignDraft((current) => ({ ...current, description: value }))}
            value={campaignDraft.description}
          />
        </div>
        <div className="mt-5">
          <p className="text-sm font-semibold text-slate-600">Bağlı Ürünler</p>
          <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-3">
            {(productsData?.products ?? []).map((product) => (
              <label className="flex items-center gap-3 rounded-2xl border border-slate-100 px-4 py-3" key={product.id}>
                <input
                  checked={campaignDraft.productIds.includes(product.id)}
                  onChange={(event) =>
                    setCampaignDraft((current) => ({
                      ...current,
                      productIds: event.target.checked
                        ? [...current.productIds, product.id]
                        : current.productIds.filter((item) => item !== product.id),
                    }))
                  }
                  type="checkbox"
                />
                <span className="text-sm">{product.title}</span>
              </label>
            ))}
          </div>
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveCampaign()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Kaydet'}
          </button>
        </div>
      </Modal>
    </div>
  );
}
