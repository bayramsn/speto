import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { BulkBar, EmptyState, LoadingState, Modal, PageHeader, Pagination, Panel, StatusBadge, TextInput, Toast } from '../components/ui';
import { useLiveReload } from '../hooks/useLiveReload';
import { approvalLabel, approvalTone, formatDate } from '../lib/formatters';
import type { BusinessListItem, PagedResponse, StorefrontType, VendorApprovalStatus } from '../lib/types';

type BusinessStorefrontType = StorefrontType | 'OTHER_HAPPY_HOUR';

type BusinessDraft = {
  name: string;
  storefrontType: BusinessStorefrontType;
  category: string;
  city: string;
  district: string;
  subtitle: string;
  imageUrl: string;
  pickupPointLabel: string;
  pickupPointAddress: string;
  operatorEmail: string;
  operatorPassword: string;
  operatorDisplayName: string;
  operatorPhone: string;
  approvalStatus: VendorApprovalStatus;
  isActive: boolean;
};

function defaultCategoryForBusinessType(type: BusinessStorefrontType) {
  if (type === 'RESTAURANT') {
    return 'Restoran';
  }
  if (type === 'OTHER_HAPPY_HOUR') {
    return 'Happy Hour';
  }
  return 'Market';
}

const EMPTY_BUSINESS_DRAFT: BusinessDraft = {
  name: '',
  storefrontType: 'MARKET',
  category: 'Market',
  city: '',
  district: '',
  subtitle: '',
  imageUrl: '',
  pickupPointLabel: 'Ana teslim noktası',
  pickupPointAddress: '',
  operatorEmail: '',
  operatorPassword: '',
  operatorDisplayName: '',
  operatorPhone: '',
  approvalStatus: 'APPROVED',
  isActive: true,
};

export function Businesses() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const { request, downloadCsv } = useAdminAuth();
  const [businesses, setBusinesses] = useState<BusinessListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState<BusinessDraft>(EMPTY_BUSINESS_DRAFT);

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const pageSize = 25;
  const storefrontTypeFilter = searchParams.get('storefrontType') ?? '';
  const searchFilter = searchParams.get('q') ?? '';
  const backendStorefrontTypeFilter =
    storefrontTypeFilter === 'OTHER_HAPPY_HOUR' ? 'MARKET' : storefrontTypeFilter;
  const backendSearchFilter =
    storefrontTypeFilter === 'OTHER_HAPPY_HOUR' && !searchFilter.trim()
      ? 'Happy Hour'
      : searchFilter;
  const query = useMemo(
    () => ({
      q: backendSearchFilter,
      approvalStatus: searchParams.get('approvalStatus') ?? '',
      storefrontType: backendStorefrontTypeFilter,
      isActive: searchParams.get('isActive') ?? '',
      page,
      pageSize,
    }),
    [backendSearchFilter, backendStorefrontTypeFilter, page, searchParams],
  );
  const exportQuery = useMemo(
    () => ({
      q: backendSearchFilter,
      approvalStatus: searchParams.get('approvalStatus') ?? '',
      storefrontType: backendStorefrontTypeFilter,
      isActive: searchParams.get('isActive') ?? '',
    }),
    [backendSearchFilter, backendStorefrontTypeFilter, searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const next = await request<PagedResponse<BusinessListItem>>('/admin/businesses', {
        query,
      });
      setBusinesses(next.items);
      setTotal(next.total);
      setSelectedIds([]);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'İşletmeler alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);
  useLiveReload(load);

  function updateParam(key: string, value: string) {
    const next = new URLSearchParams(searchParams);
    if (value) {
      next.set(key, value);
    } else {
      next.delete(key);
    }
    next.set('page', '1');
    setSearchParams(next);
  }

  async function saveBusiness() {
    setSaving(true);
    setError('');
    try {
      const isOtherBusiness = draft.storefrontType === 'OTHER_HAPPY_HOUR';
      await request('/admin/businesses', {
        method: 'POST',
        body: {
          ...draft,
          storefrontType: isOtherBusiness ? 'MARKET' : draft.storefrontType,
          category: draft.category.trim() || defaultCategoryForBusinessType(draft.storefrontType),
        },
      });
      setModalOpen(false);
      setDraft(EMPTY_BUSINESS_DRAFT);
      await load();
      setToast('İşletme oluşturuldu.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'İşletme oluşturulamadı.');
    } finally {
      setSaving(false);
    }
  }

  async function bulkUpdate(payload: Partial<Pick<BusinessListItem, 'approvalStatus' | 'isActive'>> & { suspendedReason?: string }) {
    if (selectedIds.length === 0) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request('/admin/businesses/bulk', {
        method: 'POST',
        body: {
          vendorIds: selectedIds,
          patch: payload,
        },
      });
      await load();
      setToast('Toplu işletme işlemi tamamlandı.');
    } catch (bulkError) {
      setError(bulkError instanceof Error ? bulkError.message : 'Toplu işlem başarısız oldu.');
    } finally {
      setSaving(false);
    }
  }

  function toggleSelected(id: string, checked: boolean) {
    setSelectedIds((current) =>
      checked ? Array.from(new Set([...current, id])) : current.filter((item) => item !== id),
    );
  }

  if (loading) {
    return <LoadingState label="İşletmeler hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="İşletmeler"
        description="Tüm restoran, market ve kafe operasyonlarını buradan denetleyin veya doğrudan işletme moduna geçin."
        action={
          <div className="flex flex-wrap gap-2">
            <button
              className="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold hover:bg-slate-50 transition-colors"
              onClick={() => void downloadCsv('/admin/export/businesses', 'businesses.csv', exportQuery)}
              type="button"
            >
              CSV Export
            </button>
            <button
              className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors"
              onClick={() => {
                setDraft(EMPTY_BUSINESS_DRAFT);
                setModalOpen(true);
              }}
              type="button"
            >
              Yeni İşletme
            </button>
          </div>
        }
      />

      <Panel title="Filtreler">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Onay Durumu</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('approvalStatus', event.target.value)}
              value={searchParams.get('approvalStatus') ?? ''}
            >
              <option value="">Tümü</option>
              <option value="APPROVED">Onaylı</option>
              <option value="PENDING">Beklemede</option>
              <option value="REJECTED">Reddedildi</option>
              <option value="SUSPENDED">Askıya Alınmış</option>
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">İşletme Türü</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('storefrontType', event.target.value)}
              value={searchParams.get('storefrontType') ?? ''}
            >
              <option value="">Tümü</option>
              <option value="MARKET">Market</option>
              <option value="RESTAURANT">Restoran</option>
              <option value="OTHER_HAPPY_HOUR">Diğer İşletme (Happy Hour)</option>
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Yayın</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('isActive', event.target.value)}
              value={searchParams.get('isActive') ?? ''}
            >
              <option value="">Tümü</option>
              <option value="true">Yayında</option>
              <option value="false">Pasif</option>
            </select>
          </label>
          <TextInput
            label="Arama"
            onChange={(value) => updateParam('q', value)}
            value={searchParams.get('q') ?? ''}
          />
        </div>
      </Panel>

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <BulkBar count={selectedIds.length}>
        <button
          className="rounded-2xl bg-emerald-700 px-4 py-2 font-bold text-white disabled:opacity-60"
          disabled={saving}
          onClick={() => void bulkUpdate({ approvalStatus: 'APPROVED', isActive: true })}
          type="button"
        >
          Toplu Onayla
        </button>
        <button
          className="rounded-2xl bg-amber-600 px-4 py-2 font-bold text-white disabled:opacity-60"
          disabled={saving}
          onClick={() => void bulkUpdate({ approvalStatus: 'SUSPENDED', isActive: false, suspendedReason: 'Admin toplu askıya alma' })}
          type="button"
        >
          Toplu Askıya Al
        </button>
      </BulkBar>

      <Panel title="İşletme Kuyruğu">
        {businesses.length === 0 ? (
          <EmptyState message="İşletme kaydı bulunmuyor." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="py-3">
                    <input
                      checked={businesses.length > 0 && selectedIds.length === businesses.length}
                      onChange={(event) =>
                        setSelectedIds(event.target.checked ? businesses.map((business) => business.id) : [])
                      }
                      type="checkbox"
                    />
                  </th>
                  <th className="py-3">İşletme</th>
                  <th className="py-3">Tür</th>
                  <th className="py-3">Lokasyon</th>
                  <th className="py-3">Durum</th>
                  <th className="py-3">Kurulum</th>
                  <th className="py-3 text-right">Aksiyon</th>
                </tr>
              </thead>
              <tbody>
                {businesses.map((business) => (
                  <tr className="border-t border-slate-100" key={business.id}>
                    <td className="py-4">
                      <input
                        checked={selectedIds.includes(business.id)}
                        onChange={(event) => toggleSelected(business.id, event.target.checked)}
                        type="checkbox"
                      />
                    </td>
                    <td className="py-4">
                      <div>
                        <p className="font-semibold">{business.name}</p>
                        <p className="text-sm text-slate-500">
                          {business.category} · {business.productsCount} ürün
                        </p>
                      </div>
                    </td>
                    <td className="py-4">{business.storefrontType}</td>
                    <td className="py-4 text-slate-600">
                      {[business.district, business.city].filter(Boolean).join(', ') || '-'}
                    </td>
                    <td className="py-4">
                      <div className="flex flex-col gap-2">
                        <StatusBadge
                          label={approvalLabel(business.approvalStatus)}
                          tone={approvalTone(business.approvalStatus)}
                        />
                        <span className="text-xs text-slate-500">
                          {business.isActive ? 'Yayında' : 'Pasif'}
                        </span>
                      </div>
                    </td>
                    <td className="py-4 text-slate-600">{formatDate(business.createdAt)}</td>
                    <td className="py-4">
                      <div className="flex justify-end flex-wrap gap-2">
                        <button
                          className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                          onClick={() => navigate(`/businesses/${business.id}/overview`)}
                          type="button"
                        >
                          {business.approvalStatus === 'APPROVED'
                            ? 'İşletmeyi Görüntüle'
                            : 'İşletme Başvurusunu İncele'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <Pagination
          page={page}
          pageSize={pageSize}
          total={total}
          onPageChange={(nextPage) => {
            const next = new URLSearchParams(searchParams);
            next.set('page', String(nextPage));
            setSearchParams(next);
          }}
        />
      </Panel>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Yeni İşletme">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="İşletme Adı"
            onChange={(value) => setDraft((current) => ({ ...current, name: value }))}
            value={draft.name}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">İşletme Türü</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) => {
                const storefrontType = event.target.value as BusinessStorefrontType;
                setDraft((current) => ({
                  ...current,
                  storefrontType,
                  category: defaultCategoryForBusinessType(storefrontType),
                }));
              }}
              value={draft.storefrontType}
            >
              <option value="MARKET">Market</option>
              <option value="RESTAURANT">Restoran</option>
              <option value="OTHER_HAPPY_HOUR">Diğer İşletme (Happy Hour)</option>
            </select>
          </label>
          <TextInput
            label="Kategori"
            onChange={(value) => setDraft((current) => ({ ...current, category: value }))}
            value={draft.category}
          />
          <TextInput
            label="Alt Başlık"
            onChange={(value) => setDraft((current) => ({ ...current, subtitle: value }))}
            value={draft.subtitle}
          />
          <TextInput
            label="Şehir"
            onChange={(value) => setDraft((current) => ({ ...current, city: value }))}
            value={draft.city}
          />
          <TextInput
            label="İlçe"
            onChange={(value) => setDraft((current) => ({ ...current, district: value }))}
            value={draft.district}
          />
          <TextInput
            label="İşletme Profil Resmi URL"
            onChange={(value) => setDraft((current) => ({ ...current, imageUrl: value }))}
            value={draft.imageUrl}
          />
          <TextInput
            label="İşletme Adresi"
            onChange={(value) =>
              setDraft((current) => ({ ...current, pickupPointAddress: value }))
            }
            value={draft.pickupPointAddress}
          />
          <TextInput
            label="İşletme E-Posta"
            onChange={(value) => setDraft((current) => ({ ...current, operatorEmail: value }))}
            value={draft.operatorEmail}
          />
          <TextInput
            label="İşletme Şifre"
            onChange={(value) => setDraft((current) => ({ ...current, operatorPassword: value }))}
            type="password"
            value={draft.operatorPassword}
          />
          <TextInput
            label="İşletme Sahibinin Adı"
            onChange={(value) =>
              setDraft((current) => ({ ...current, operatorDisplayName: value }))
            }
            value={draft.operatorDisplayName}
          />
          <TextInput
            label="İşletme Telefon Numarası"
            onChange={(value) => setDraft((current) => ({ ...current, operatorPhone: value }))}
            value={draft.operatorPhone}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Onay Durumu</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setDraft((current) => ({
                  ...current,
                  approvalStatus: event.target.value as VendorApprovalStatus,
                }))
              }
              value={draft.approvalStatus}
            >
              <option value="APPROVED">Onaylı</option>
              <option value="PENDING">Beklemede</option>
              <option value="REJECTED">Reddedildi</option>
              <option value="SUSPENDED">Askıya Alınmış</option>
            </select>
          </label>
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={draft.isActive}
              onChange={(event) => setDraft((current) => ({ ...current, isActive: event.target.checked }))}
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">İşletme aktif başlasın</span>
          </label>
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveBusiness()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'İşletmeyi Oluştur'}
          </button>
        </div>
      </Modal>
    </div>
  );
}
