import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { EmptyState, LoadingState, Modal, PageHeader, Panel, StatusBadge, TextInput } from '../components/ui';
import { formatDate } from '../lib/formatters';
import type { AdminAppUser, UserRole } from '../lib/types';

type UserDraft = {
  id?: string;
  email: string;
  displayName: string;
  phone: string;
  password: string;
  role: UserRole;
  notificationsEnabled: boolean;
  isSuspended: boolean;
  suspendedReason: string;
  isBanned: boolean;
  bannedReason: string;
};

const USER_ROLES: UserRole[] = ['CUSTOMER', 'VENDOR', 'SUPPORT', 'ADMIN'];

const EMPTY_DRAFT: UserDraft = {
  email: '',
  displayName: '',
  phone: '',
  password: '',
  role: 'CUSTOMER',
  notificationsEnabled: true,
  isSuspended: false,
  suspendedReason: '',
  isBanned: false,
  bannedReason: '',
};

export function Users() {
  const { request } = useAdminAuth();
  const [users, setUsers] = useState<AdminAppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [draft, setDraft] = useState<UserDraft>(EMPTY_DRAFT);
  const [modalOpen, setModalOpen] = useState(false);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const next = await request<AdminAppUser[]>('/admin/users');
      setUsers(next);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Kullanıcılar alınamadı.');
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

  function openEditModal(user: AdminAppUser) {
    setDraft({
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      phone: user.phone,
      password: '',
      role: user.role,
      notificationsEnabled: user.notificationsEnabled,
      isSuspended: user.isSuspended,
      suspendedReason: user.suspendedReason,
      isBanned: user.isBanned,
      bannedReason: user.bannedReason,
    });
    setModalOpen(true);
  }

  async function saveUser() {
    setSaving(true);
    setError('');
    try {
      if (draft.id) {
        await request(`/admin/users/${draft.id}`, {
          method: 'PATCH',
          body: draft,
        });
      } else {
        await request('/admin/users', {
          method: 'POST',
          body: draft,
        });
      }
      setModalOpen(false);
      setDraft(EMPTY_DRAFT);
      await load();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Kullanıcı kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return <LoadingState label="Kullanıcı listesi hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Kullanıcılar"
        description="Müşteri, işletme operatörü ve destek hesaplarını buradan yönetin."
        action={
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors"
            onClick={openCreateModal}
            type="button"
          >
            Yeni Kullanıcı
          </button>
        }
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <Panel title="Kullanıcı Listesi">
        {users.length === 0 ? (
          <EmptyState message="Kullanıcı bulunmuyor." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="py-3">Ad</th>
                  <th className="py-3">Rol</th>
                  <th className="py-3">Sipariş</th>
                  <th className="py-3">Durum</th>
                  <th className="py-3">Son giriş</th>
                  <th className="py-3 text-right">İşlem</th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr className="border-t border-slate-100" key={user.id}>
                    <td className="py-4">
                      <div>
                        <p className="font-semibold">{user.displayName}</p>
                        <p className="text-sm text-slate-500">{user.email}</p>
                      </div>
                    </td>
                    <td className="py-4">{user.role}</td>
                    <td className="py-4">{user.ordersCount}</td>
                    <td className="py-4">
                      {user.isBanned ? (
                        <StatusBadge label="Yasaklı" tone="danger" />
                      ) : user.isSuspended ? (
                        <StatusBadge label="Askıda" tone="warning" />
                      ) : (
                        <StatusBadge label="Aktif" tone="success" />
                      )}
                    </td>
                    <td className="py-4 text-sm text-slate-500">{formatDate(user.lastLoginAt)}</td>
                    <td className="py-4 text-right">
                      <button
                        className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                        onClick={() => openEditModal(user)}
                        type="button"
                      >
                        Düzenle
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={draft.id ? 'Kullanıcıyı Düzenle' : 'Yeni Kullanıcı'}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="E-posta"
            onChange={(value) => setDraft((current) => ({ ...current, email: value }))}
            value={draft.email}
          />
          <TextInput
            label="Ad Soyad"
            onChange={(value) => setDraft((current) => ({ ...current, displayName: value }))}
            value={draft.displayName}
          />
          <TextInput
            label="Telefon"
            onChange={(value) => setDraft((current) => ({ ...current, phone: value }))}
            value={draft.phone}
          />
          <TextInput
            label="Şifre"
            onChange={(value) => setDraft((current) => ({ ...current, password: value }))}
            type="password"
            value={draft.password}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Rol</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              onChange={(event) =>
                setDraft((current) => ({ ...current, role: event.target.value as UserRole }))
              }
              value={draft.role}
            >
              {USER_ROLES.map((role) => (
                <option key={role} value={role}>
                  {role}
                </option>
              ))}
            </select>
          </label>
          <TextInput
            label="Askı Sebebi"
            onChange={(value) => setDraft((current) => ({ ...current, suspendedReason: value }))}
            value={draft.suspendedReason}
          />
          <TextInput
            label="Ban Sebebi"
            onChange={(value) => setDraft((current) => ({ ...current, bannedReason: value }))}
            value={draft.bannedReason}
          />
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={draft.notificationsEnabled}
              onChange={(event) =>
                setDraft((current) => ({
                  ...current,
                  notificationsEnabled: event.target.checked,
                }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Bildirim alabilir</span>
          </label>
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={draft.isSuspended}
              onChange={(event) =>
                setDraft((current) => ({ ...current, isSuspended: event.target.checked }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Hesap askıda</span>
          </label>
          <label className="flex items-center gap-3 md:col-span-2">
            <input
              checked={draft.isBanned}
              onChange={(event) =>
                setDraft((current) => ({ ...current, isBanned: event.target.checked }))
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Hesap yasaklı</span>
          </label>
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveUser()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Kaydet'}
          </button>
        </div>
      </Modal>
    </div>
  );
}
