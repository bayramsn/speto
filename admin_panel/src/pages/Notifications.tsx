import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { EmptyState, LoadingState, Modal, PageHeader, Panel, StatusBadge, TextArea, TextInput } from '../components/ui';
import { formatDate, notificationStatusLabel } from '../lib/formatters';
import type {
  AdminNotification,
  NotificationAudience,
  NotificationStatus,
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
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [draft, setDraft] = useState<NotificationDraft>(EMPTY_DRAFT);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const next = await request<AdminNotification[]>('/admin/notifications');
      setNotifications(next);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Bildirimler alınamadı.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

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
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Bildirim kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return <LoadingState label="Bildirim akışı hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
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
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-slate-500">{formatDate(notification.createdAt)}</p>
                    <button
                      className="mt-3 rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                      onClick={() => openEditModal(notification)}
                      type="button"
                    >
                      Düzenle
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </Panel>

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
