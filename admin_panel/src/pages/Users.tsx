import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { BulkBar, EmptyState, LoadingState, Modal, PageHeader, Pagination, Panel, StatusBadge, TextInput, Toast } from '../components/ui';
import { formatDate } from '../lib/formatters';
import type { AdminAppUser, BusinessListItem, PagedResponse, UserRole } from '../lib/types';

type UserDraft = {
  id?: string;
  email: string;
  displayName: string;
  phone: string;
  password: string;
  role: UserRole;
  vendorId: string;
  notificationsEnabled: boolean;
  isSuspended: boolean;
  suspendedReason: string;
  isBanned: boolean;
  bannedReason: string;
};

const USER_ROLES: UserRole[] = ['CUSTOMER', 'VENDOR', 'SUPPORT'];

const EMPTY_DRAFT: UserDraft = {
  email: '',
  displayName: '',
  phone: '',
  password: '',
  role: 'CUSTOMER',
  vendorId: '',
  notificationsEnabled: true,
  isSuspended: false,
  suspendedReason: '',
  isBanned: false,
  bannedReason: '',
};

export function Users() {
  const { request, downloadCsv } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [users, setUsers] = useState<AdminAppUser[]>([]);
  const [businesses, setBusinesses] = useState<BusinessListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [draft, setDraft] = useState<UserDraft>(EMPTY_DRAFT);
  const [modalOpen, setModalOpen] = useState(false);

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const pageSize = 25;
  const query = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      role: searchParams.get('role') ?? '',
      isSuspended: searchParams.get('isSuspended') ?? '',
      isBanned: searchParams.get('isBanned') ?? '',
      page,
      pageSize,
    }),
    [page, searchParams],
  );
  const exportQuery = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      role: searchParams.get('role') ?? '',
      isSuspended: searchParams.get('isSuspended') ?? '',
      isBanned: searchParams.get('isBanned') ?? '',
    }),
    [searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [nextUsers, nextBusinesses] = await Promise.all([
        request<PagedResponse<AdminAppUser>>('/admin/users', { query }),
        request<BusinessListItem[]>('/admin/businesses'),
      ]);
      setUsers(nextUsers.items);
      setTotal(nextUsers.total);
      setBusinesses(nextBusinesses);
      setSelectedIds([]);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Kullanıcılar alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);

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
      vendorId: user.vendorId ?? '',
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
      setToast('Kullanıcı kaydedildi.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Kullanıcı kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function bulkUpdate(payload: Partial<Pick<AdminAppUser, 'notificationsEnabled' | 'isSuspended' | 'isBanned'>> & { suspendedReason?: string; bannedReason?: string }) {
    if (selectedIds.length === 0) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request('/admin/users/bulk', {
        method: 'POST',
        body: { userIds: selectedIds, patch: payload },
      });
      await load();
      setToast('Toplu kullanıcı işlemi tamamlandı.');
    } catch (bulkError) {
      setError(bulkError instanceof Error ? bulkError.message : 'Toplu kullanıcı işlemi başarısız.');
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

  function toggleSelected(id: string, checked: boolean) {
    setSelectedIds((current) =>
      checked ? Array.from(new Set([...current, id])) : current.filter((item) => item !== id),
    );
  }

  if (loading) {
    return <LoadingState label="Kullanıcı listesi hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="Kullanıcılar"
        description="Müşteri, işletme operatörü ve destek hesaplarını buradan yönetin."
        action={
          <div className="flex flex-wrap gap-2">
            <button
              className="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold hover:bg-slate-50"
              onClick={() => void downloadCsv('/admin/export/users', 'users.csv', exportQuery)}
              type="button"
            >
              CSV Export
            </button>
            <button
              className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors"
              onClick={openCreateModal}
              type="button"
            >
              Yeni Kullanıcı
            </button>
          </div>
        }
      />

      <Panel title="Filtreler">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
          <TextInput
            label="Arama"
            onChange={(value) => updateParam('q', value)}
            value={searchParams.get('q') ?? ''}
          />
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Rol</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('role', event.target.value)}
              value={searchParams.get('role') ?? ''}
            >
              <option value="">Tümü</option>
              {USER_ROLES.map((role) => (
                <option key={role} value={role}>
                  {role}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Askı</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('isSuspended', event.target.value)}
              value={searchParams.get('isSuspended') ?? ''}
            >
              <option value="">Tümü</option>
              <option value="true">Askıda</option>
              <option value="false">Askıda değil</option>
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Ban</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('isBanned', event.target.value)}
              value={searchParams.get('isBanned') ?? ''}
            >
              <option value="">Tümü</option>
              <option value="true">Yasaklı</option>
              <option value="false">Yasaklı değil</option>
            </select>
          </label>
        </div>
      </Panel>

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <BulkBar count={selectedIds.length}>
        <button
          className="rounded-2xl bg-white px-4 py-2 font-bold text-emerald-800 disabled:opacity-60"
          disabled={saving}
          onClick={() => void bulkUpdate({ notificationsEnabled: true })}
          type="button"
        >
          Bildirim Aç
        </button>
        <button
          className="rounded-2xl bg-amber-600 px-4 py-2 font-bold text-white disabled:opacity-60"
          disabled={saving}
          onClick={() => void bulkUpdate({ isSuspended: true, suspendedReason: 'Admin toplu askıya alma' })}
          type="button"
        >
          Askıya Al
        </button>
        <button
          className="rounded-2xl bg-red-600 px-4 py-2 font-bold text-white disabled:opacity-60"
          disabled={saving}
          onClick={() => void bulkUpdate({ isBanned: true, bannedReason: 'Admin toplu yasaklama' })}
          type="button"
        >
          Banla
        </button>
      </BulkBar>

      <Panel title="Kullanıcı Listesi">
        {users.length === 0 ? (
          <EmptyState message="Kullanıcı bulunmuyor." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="py-3">
                    <input
                      checked={users.length > 0 && selectedIds.length === users.length}
                      onChange={(event) =>
                        setSelectedIds(event.target.checked ? users.map((user) => user.id) : [])
                      }
                      type="checkbox"
                    />
                  </th>
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
                      <input
                        checked={selectedIds.includes(user.id)}
                        onChange={(event) => toggleSelected(user.id, event.target.checked)}
                        type="checkbox"
                      />
                    </td>
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
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Bağlı İşletme</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
              disabled={draft.role !== 'VENDOR'}
              onChange={(event) => setDraft((current) => ({ ...current, vendorId: event.target.value }))}
              value={draft.vendorId}
            >
              <option value="">İşletme yok</option>
              {businesses.map((business) => (
                <option key={business.id} value={business.id}>
                  {business.name}
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
