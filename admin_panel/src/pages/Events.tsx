import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, Modal, PageHeader, Pagination, Panel, StatusBadge, TextArea, TextInput, Toast } from '../components/ui';
import { formatDate } from '../lib/formatters';
import type { AdminEvent, BusinessListItem, PagedResponse } from '../lib/types';

type EventDraft = {
  id?: string;
  vendorId: string;
  title: string;
  venue: string;
  district: string;
  imageUrl: string;
  startsAt: string;
  pointsCost: string;
  capacity: string;
  remainingCount: string;
  primaryTag: string;
  secondaryTag: string;
  description: string;
  organizer: string;
  isActive: boolean;
};

const EMPTY_EVENT_DRAFT: EventDraft = {
  vendorId: '',
  title: '',
  venue: '',
  district: '',
  imageUrl: '',
  startsAt: '',
  pointsCost: '0',
  capacity: '50',
  remainingCount: '50',
  primaryTag: '',
  secondaryTag: '',
  description: '',
  organizer: '',
  isActive: true,
};

export function Events() {
  const { request } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [events, setEvents] = useState<AdminEvent[]>([]);
  const [businesses, setBusinesses] = useState<BusinessListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState<EventDraft>(EMPTY_EVENT_DRAFT);

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const pageSize = 25;
  const query = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      isActive: searchParams.get('isActive') ?? '',
      page,
      pageSize,
    }),
    [page, searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [nextEvents, nextBusinesses] = await Promise.all([
        request<PagedResponse<AdminEvent>>('/admin/events', { query }),
        request<BusinessListItem[]>('/admin/businesses'),
      ]);
      setEvents(nextEvents.items);
      setTotal(nextEvents.total);
      setBusinesses(nextBusinesses);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Etkinlikler alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);

  function openCreateModal() {
    setDraft({
      ...EMPTY_EVENT_DRAFT,
      vendorId: businesses[0]?.id ?? '',
    });
    setModalOpen(true);
  }

  function openEditModal(event: AdminEvent) {
    setDraft({
      id: event.id,
      vendorId: event.vendorId,
      title: event.title,
      venue: event.venue,
      district: event.district,
      imageUrl: event.imageUrl,
      startsAt: event.startsAt.slice(0, 16),
      pointsCost: String(event.pointsCost),
      capacity: String(event.capacity),
      remainingCount: String(event.remainingCount),
      primaryTag: event.primaryTag,
      secondaryTag: event.secondaryTag,
      description: event.description,
      organizer: event.organizer,
      isActive: event.isActive,
    });
    setModalOpen(true);
  }

  async function saveEvent() {
    setSaving(true);
    setError('');
    try {
      const payload = {
        ...draft,
        pointsCost: Number(draft.pointsCost),
        capacity: Number(draft.capacity),
        remainingCount: Number(draft.remainingCount),
      };
      if (draft.id) {
        await request(`/admin/events/${draft.id}`, {
          method: 'PATCH',
          body: payload,
        });
      } else {
        await request('/admin/events', {
          method: 'POST',
          body: payload,
        });
      }
      setModalOpen(false);
      setDraft(EMPTY_EVENT_DRAFT);
      await load();
      setToast('Etkinlik kaydedildi.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Etkinlik kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function deleteEvent(event: AdminEvent) {
    if (!window.confirm(`${event.title} etkinliği silinecek. Onaylıyor musunuz?`)) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request(`/admin/events/${event.id}`, { method: 'DELETE' });
      await load();
      setToast('Etkinlik silindi.');
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : 'Etkinlik silinemedi.');
    } finally {
      setSaving(false);
    }
  }

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

  if (loading) {
    return <LoadingState label="Etkinlikler yükleniyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="Etkinlik & Puan"
        description="İşletmelerin etkinliklerini ve puan tüketim akışını yönetin."
        action={
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors"
            onClick={openCreateModal}
            type="button"
          >
            Yeni Etkinlik
          </button>
        }
      />

      <Panel title="Filtreler">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <TextInput
            label="Arama"
            onChange={(value) => updateParam('q', value)}
            value={searchParams.get('q') ?? ''}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Yayın</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('isActive', event.target.value)}
              value={searchParams.get('isActive') ?? ''}
            >
              <option value="">Tümü</option>
              <option value="true">Aktif</option>
              <option value="false">Pasif</option>
            </select>
          </label>
        </div>
      </Panel>

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <Panel title="Etkinlik Listesi">
        {events.length === 0 ? (
          <EmptyState message="Etkinlik bulunmuyor." />
        ) : (
          <div className="space-y-4">
            {events.map((event) => (
              <div className="rounded-2xl border border-slate-100 p-5" key={event.id}>
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-bold">{event.title}</h3>
                      <StatusBadge
                        label={event.isActive ? 'Aktif' : 'Pasif'}
                        tone={event.isActive ? 'success' : 'default'}
                      />
                    </div>
                    <p className="mt-2 text-sm text-slate-500">
                      {event.vendorName} · {event.venue} · {formatDate(event.startsAt)}
                    </p>
                    <p className="mt-3 text-sm text-slate-700">{event.description}</p>
                  </div>
                  <button
                    className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                    onClick={() => openEditModal(event)}
                    type="button"
                  >
                    Düzenle
                  </button>
                  <button
                    className="rounded-2xl border border-red-200 px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-50 disabled:opacity-60"
                    disabled={saving}
                    onClick={() => void deleteEvent(event)}
                    type="button"
                  >
                    Sil
                  </button>
                </div>
              </div>
            ))}
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

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={draft.id ? 'Etkinliği Düzenle' : 'Yeni Etkinlik'}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">İşletme</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) => setDraft((current) => ({ ...current, vendorId: event.target.value }))}
              value={draft.vendorId}
            >
              {businesses.map((business) => (
                <option key={business.id} value={business.id}>
                  {business.name}
                </option>
              ))}
            </select>
          </label>
          <TextInput
            label="Başlık"
            onChange={(value) => setDraft((current) => ({ ...current, title: value }))}
            value={draft.title}
          />
          <TextInput
            label="Mekan"
            onChange={(value) => setDraft((current) => ({ ...current, venue: value }))}
            value={draft.venue}
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
            label="Başlangıç"
            onChange={(value) => setDraft((current) => ({ ...current, startsAt: value }))}
            type="datetime-local"
            value={draft.startsAt}
          />
          <TextInput
            label="Puan Maliyeti"
            onChange={(value) => setDraft((current) => ({ ...current, pointsCost: value }))}
            type="number"
            value={draft.pointsCost}
          />
          <TextInput
            label="Kapasite"
            onChange={(value) => setDraft((current) => ({ ...current, capacity: value }))}
            type="number"
            value={draft.capacity}
          />
          <TextInput
            label="Kalan"
            onChange={(value) => setDraft((current) => ({ ...current, remainingCount: value }))}
            type="number"
            value={draft.remainingCount}
          />
          <TextInput
            label="Birincil Etiket"
            onChange={(value) => setDraft((current) => ({ ...current, primaryTag: value }))}
            value={draft.primaryTag}
          />
          <TextInput
            label="İkincil Etiket"
            onChange={(value) => setDraft((current) => ({ ...current, secondaryTag: value }))}
            value={draft.secondaryTag}
          />
          <TextInput
            label="Organizatör"
            onChange={(value) => setDraft((current) => ({ ...current, organizer: value }))}
            value={draft.organizer}
          />
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={draft.isActive}
              onChange={(event) => setDraft((current) => ({ ...current, isActive: event.target.checked }))}
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Etkinlik aktif</span>
          </label>
        </div>
        <div className="mt-5">
          <TextArea
            label="Açıklama"
            onChange={(value) => setDraft((current) => ({ ...current, description: value }))}
            value={draft.description}
          />
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveEvent()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Kaydet'}
          </button>
        </div>
      </Modal>
    </div>
  );
}
