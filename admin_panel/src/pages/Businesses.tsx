import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { EmptyState, LoadingState, Modal, PageHeader, Panel, StatusBadge, TextInput } from '../components/ui';
import { approvalLabel, approvalTone, formatDate } from '../lib/formatters';
import type { BusinessListItem, StorefrontType, VendorApprovalStatus } from '../lib/types';

type BusinessDraft = {
  name: string;
  storefrontType: StorefrontType;
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
  operatorPassword: 'Vendor123!',
  operatorDisplayName: '',
  operatorPhone: '',
  approvalStatus: 'APPROVED',
  isActive: true,
};

export function Businesses() {
  const navigate = useNavigate();
  const { request } = useAdminAuth();
  const [businesses, setBusinesses] = useState<BusinessListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState<BusinessDraft>(EMPTY_BUSINESS_DRAFT);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const next = await request<BusinessListItem[]>('/admin/businesses');
      setBusinesses(next);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'İşletmeler alınamadı.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function saveBusiness() {
    setSaving(true);
    setError('');
    try {
      await request('/admin/businesses', {
        method: 'POST',
        body: draft,
      });
      setModalOpen(false);
      setDraft(EMPTY_BUSINESS_DRAFT);
      await load();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'İşletme oluşturulamadı.');
    } finally {
      setSaving(false);
    }
  }

  async function quickUpdateBusiness(
    businessId: string,
    payload: Partial<Pick<BusinessListItem, 'approvalStatus' | 'isActive'>>,
  ) {
    await request(`/admin/businesses/${businessId}`, {
      method: 'PATCH',
      body: payload,
    });
    await load();
  }

  if (loading) {
    return <LoadingState label="İşletmeler hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="İşletmeler"
        description="Tüm restoran, market ve kafe operasyonlarını buradan denetleyin veya doğrudan işletme moduna geçin."
        action={
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
        }
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <Panel title="İşletme Kuyruğu">
        {businesses.length === 0 ? (
          <EmptyState message="İşletme kaydı bulunmuyor." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="text-xs uppercase tracking-wide text-slate-500">
                <tr>
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
                          İşletmeye Gir
                        </button>
                        <button
                          className="rounded-2xl border border-emerald-200 px-4 py-2 text-sm font-semibold text-emerald-700 hover:bg-emerald-50"
                          onClick={() =>
                            void quickUpdateBusiness(business.id, {
                              approvalStatus: 'APPROVED',
                              isActive: true,
                            })
                          }
                          type="button"
                        >
                          Onayla
                        </button>
                        <button
                          className="rounded-2xl border border-amber-200 px-4 py-2 text-sm font-semibold text-amber-700 hover:bg-amber-50"
                          onClick={() =>
                            void quickUpdateBusiness(business.id, {
                              approvalStatus: 'SUSPENDED',
                              isActive: false,
                            })
                          }
                          type="button"
                        >
                          Askıya Al
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Yeni İşletme">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="İşletme Adı"
            onChange={(value) => setDraft((current) => ({ ...current, name: value }))}
            value={draft.name}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Storefront Type</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setDraft((current) => ({
                  ...current,
                  storefrontType: event.target.value as StorefrontType,
                }))
              }
              value={draft.storefrontType}
            >
              <option value="MARKET">MARKET</option>
              <option value="RESTAURANT">RESTAURANT</option>
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
            label="Görsel URL"
            onChange={(value) => setDraft((current) => ({ ...current, imageUrl: value }))}
            value={draft.imageUrl}
          />
          <TextInput
            label="Pickup Etiketi"
            onChange={(value) => setDraft((current) => ({ ...current, pickupPointLabel: value }))}
            value={draft.pickupPointLabel}
          />
          <TextInput
            label="Pickup Adresi"
            onChange={(value) =>
              setDraft((current) => ({ ...current, pickupPointAddress: value }))
            }
            value={draft.pickupPointAddress}
          />
          <TextInput
            label="Operatör E-posta"
            onChange={(value) => setDraft((current) => ({ ...current, operatorEmail: value }))}
            value={draft.operatorEmail}
          />
          <TextInput
            label="Operatör Şifre"
            onChange={(value) => setDraft((current) => ({ ...current, operatorPassword: value }))}
            type="password"
            value={draft.operatorPassword}
          />
          <TextInput
            label="Operatör Adı"
            onChange={(value) =>
              setDraft((current) => ({ ...current, operatorDisplayName: value }))
            }
            value={draft.operatorDisplayName}
          />
          <TextInput
            label="Operatör Telefon"
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
              <option value="APPROVED">APPROVED</option>
              <option value="PENDING">PENDING</option>
              <option value="REJECTED">REJECTED</option>
              <option value="SUSPENDED">SUSPENDED</option>
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
