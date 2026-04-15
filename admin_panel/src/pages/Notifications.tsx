import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, Modal, PageHeader, Pagination, Panel, StatusBadge, TextArea, TextInput, Toast } from '../components/ui';
import { useLiveReload } from '../hooks/useLiveReload';
import { formatDate, notificationStatusLabel } from '../lib/formatters';
import type {
  AdminNotification,
  NotificationAudience,
  NotificationStatus,
  PagedResponse,
} from '../lib/types';

type NotificationDraft = {
  id?: string;
  title: string;
  body: string;
  audience: NotificationAudience;
  status: NotificationStatus;
  scheduledAt: string;
};

const AUDIENCE_OPTIONS: NotificationAudience[] = [
  'ALL_USERS',
  'ALL_BUSINESSES',
  'ALL_VENDORS',
  'CUSTOM',
];

const STATUS_OPTIONS: NotificationStatus[] = ['DRAFT', 'SCHEDULED', 'SENT'];

const EMPTY_DRAFT: NotificationDraft = {
  title: '',
  body: '',
  audience: 'ALL_USERS',
  status: 'DRAFT',
  scheduledAt: '',
};

export function Notifications() {
  const { request } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState<NotificationDraft>(EMPTY_DRAFT);
  const [preview, setPreview] = useState<AdminNotification | null>(null);

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const pageSize = 25;
  const query = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      status: searchParams.get('status') ?? '',
      audience: searchParams.get('audience') ?? '',
      page,
      pageSize,
    }),
    [page, searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const next = await request<PagedResponse<AdminNotification>>('/admin/notifications', { query });
      setNotifications(next.items);
      setTotal(next.total);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Bildirimler alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);
  useLiveReload(load);

  function openCreateModal() {
    setDraft(EMPTY_DRAFT);
    setModalOpen(true);
  }

  function openEditModal(notification: AdminNotification) {
    setDraft({
      id: notification.id,
      title: notification.title,
      body: notification.body,
      audience: notification.audience,
      status: notification.status,
      scheduledAt: notification.scheduledAt?.slice(0, 16) ?? '',
    });
    setModalOpen(true);
  }

  async function saveNotification() {
    if (draft.status === 'SCHEDULED' && !draft.scheduledAt) {
      setError('Planlanan bildirimler için gönderim tarihi zorunludur.');
      return;
    }
    if (
      draft.status === 'SENT' &&
      !window.confirm('Bildirim hemen gönderilecek. Devam etmek istiyor musunuz?')
    ) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      const payload = {
        ...draft,
        scheduledAt: draft.scheduledAt || null,
      };
      if (draft.id) {
        await request(`/admin/notifications/${draft.id}`, {
          method: 'PATCH',
          body: payload,
        });
      } else {
        await request('/admin/notifications', {
          method: 'POST',
          body: payload,
        });
      }
      setModalOpen(false);
      setDraft(EMPTY_DRAFT);
      await load();
      setToast('Bildirim kaydedildi.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Bildirim kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function deleteNotification(notification: AdminNotification) {
    if (!window.confirm(`${notification.title} bildirimi silinecek. Onaylıyor musunuz?`)) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request(`/admin/notifications/${notification.id}`, { method: 'DELETE' });
      await load();
      setToast('Bildirim silindi.');
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : 'Bildirim silinemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function sendNow(notification: AdminNotification) {
    if (!window.confirm(`${notification.title} bildirimi hemen gönderilecek. Onaylıyor musunuz?`)) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request(`/admin/notifications/${notification.id}`, {
        method: 'PATCH',
        body: { status: 'SENT' },
      });
      await load();
      setToast('Bildirim gönderim kuyruğuna alındı.');
    } catch (sendError) {
      setError(sendError instanceof Error ? sendError.message : 'Bildirim gönderilemedi.');
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
    return <LoadingState label="Bildirim akışı hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="Bildirimler"
        description="Push ve duyuru akışlarını admin backend üzerinden planlayın ve gönderin."
        action={
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors"
            onClick={openCreateModal}
            type="button"
          >
            Yeni Bildirim
          </button>
        }
      />

      <Panel title="Filtreler">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <TextInput
            label="Arama"
            onChange={(value) => updateParam('q', value)}
            value={searchParams.get('q') ?? ''}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Durum</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('status', event.target.value)}
              value={searchParams.get('status') ?? ''}
            >
              <option value="">Tümü</option>
              {STATUS_OPTIONS.map((status) => (
                <option key={status} value={status}>
                  {notificationStatusLabel(status)}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Hedef Kitle</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('audience', event.target.value)}
              value={searchParams.get('audience') ?? ''}
            >
              <option value="">Tümü</option>
              {AUDIENCE_OPTIONS.map((audience) => (
                <option key={audience} value={audience}>
                  {audience}
                </option>
              ))}
            </select>
          </label>
        </div>
      </Panel>

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <Panel title="Bildirim Kayıtları">
        {notifications.length === 0 ? (
          <EmptyState message="Bildirim kaydı bulunmuyor." />
        ) : (
          <div className="space-y-4">
            {notifications.map((notification) => (
              <div className="rounded-2xl border border-slate-100 p-5" key={notification.id}>
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-bold">{notification.title}</h3>
                      <StatusBadge
                        label={notificationStatusLabel(notification.status)}
                        tone={
                          notification.status === 'SENT'
                            ? 'success'
                            : notification.status === 'SCHEDULED'
                              ? 'warning'
                              : 'default'
                        }
                      />
                    </div>
                    <p className="mt-2 text-sm text-slate-500">
                      {notification.audience} · {notification.createdByName}
                    </p>
                    <p className="mt-3 text-sm text-slate-700 whitespace-pre-wrap">{notification.body}</p>
                    {notification.deliveryLogs.length > 0 ? (
                      <div className="mt-3 flex flex-wrap gap-2">
                        {notification.deliveryLogs.map((log) => (
                          <StatusBadge
                            key={log.id}
                            label={`${log.provider}: ${log.status}`}
                            tone={log.status === 'QUEUED' ? 'info' : log.status === 'NOT_CONFIGURED' ? 'warning' : 'default'}
                          />
                        ))}
                      </div>
                    ) : null}
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-slate-500">{formatDate(notification.createdAt)}</p>
                    <button
                      className="mt-3 rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                      onClick={() => setPreview(notification)}
                      type="button"
                    >
                      Önizle
                    </button>
                    <button
                      className="mt-3 ml-2 rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                      onClick={() => openEditModal(notification)}
                      type="button"
                    >
                      Düzenle
                    </button>
                    {notification.status !== 'SENT' ? (
                      <button
                        className="mt-3 ml-2 rounded-2xl border border-emerald-200 px-4 py-2 text-sm font-semibold text-emerald-700 hover:bg-emerald-50 disabled:opacity-60"
                        disabled={saving}
                        onClick={() => void sendNow(notification)}
                        type="button"
                      >
                        Şimdi Gönder
                      </button>
                    ) : null}
                    <button
                      className="mt-3 ml-2 rounded-2xl border border-red-200 px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-50 disabled:opacity-60"
                      disabled={saving}
                      onClick={() => void deleteNotification(notification)}
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
        open={preview !== null}
        onClose={() => setPreview(null)}
        title={preview ? preview.title : 'Bildirim Önizleme'}
      >
        {preview ? (
          <div className="space-y-5">
            <div className="flex flex-wrap items-center gap-3">
              <StatusBadge
                label={notificationStatusLabel(preview.status)}
                tone={
                  preview.status === 'SENT'
                    ? 'success'
                    : preview.status === 'SCHEDULED'
                      ? 'warning'
                      : 'default'
                }
              />
              <StatusBadge label={preview.audience} tone="info" />
            </div>
            <div className="rounded-2xl border border-slate-100 bg-slate-50 p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                İçerik Önizleme
              </p>
              <p className="mt-3 whitespace-pre-wrap text-sm text-slate-700">{preview.body}</p>
            </div>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div className="rounded-2xl border border-slate-100 p-4">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Oluşturan</p>
                <p className="mt-2 text-sm font-semibold text-slate-800">{preview.createdByName}</p>
                <p className="text-sm text-slate-500">{preview.createdByEmail}</p>
              </div>
              <div className="rounded-2xl border border-slate-100 p-4">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Zamanlama</p>
                <p className="mt-2 text-sm text-slate-700">Planlı: {formatDate(preview.scheduledAt)}</p>
                <p className="text-sm text-slate-700">Gönderildi: {formatDate(preview.sentAt)}</p>
              </div>
            </div>
            <Panel title="Delivery Logları">
              {preview.deliveryLogs.length === 0 ? (
                <EmptyState message="Henüz delivery logu oluşmadı." />
              ) : (
                <div className="space-y-3">
                  {preview.deliveryLogs.map((log) => (
                    <div className="rounded-2xl border border-slate-100 p-4" key={log.id}>
                      <div className="flex items-center justify-between gap-3">
                        <p className="font-bold">{log.provider}</p>
                        <StatusBadge
                          label={log.status}
                          tone={
                            log.status === 'QUEUED'
                              ? 'info'
                              : log.status === 'NOT_CONFIGURED'
                                ? 'warning'
                                : 'default'
                          }
                        />
                      </div>
                      {log.errorMessage ? (
                        <p className="mt-2 text-sm text-amber-700">{log.errorMessage}</p>
                      ) : null}
                      <p className="mt-2 text-xs text-slate-500">{formatDate(log.createdAt)}</p>
                    </div>
                  ))}
                </div>
              )}
            </Panel>
          </div>
        ) : null}
      </Modal>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={draft.id ? 'Bildirimi Düzenle' : 'Yeni Bildirim'}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="Başlık"
            onChange={(value) => setDraft((current) => ({ ...current, title: value }))}
            value={draft.title}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Hedef Kitle</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setDraft((current) => ({
                  ...current,
                  audience: event.target.value as NotificationAudience,
                }))
              }
              value={draft.audience}
            >
              {AUDIENCE_OPTIONS.map((audience) => (
                <option key={audience} value={audience}>
                  {audience}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Durum</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setDraft((current) => ({
                  ...current,
                  status: event.target.value as NotificationStatus,
                }))
              }
              value={draft.status}
            >
              {STATUS_OPTIONS.map((status) => (
                <option key={status} value={status}>
                  {notificationStatusLabel(status)}
                </option>
              ))}
            </select>
          </label>
          <TextInput
            label="Planlanan Gönderim"
            onChange={(value) => setDraft((current) => ({ ...current, scheduledAt: value }))}
            type="datetime-local"
            value={draft.scheduledAt}
          />
        </div>
        <div className="mt-5">
          <TextArea
            label="Mesaj"
            onChange={(value) => setDraft((current) => ({ ...current, body: value }))}
            rows={6}
            value={draft.body}
          />
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveNotification()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Kaydet'}
          </button>
        </div>
      </Modal>
    </div>
  );
}
