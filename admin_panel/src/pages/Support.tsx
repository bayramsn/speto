import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, Modal, PageHeader, Pagination, Panel, StatusBadge, TextArea, TextInput, Toast } from '../components/ui';
import { useLiveReload } from '../hooks/useLiveReload';
import { formatDate, supportStatusLabel } from '../lib/formatters';
import type { AdminSupportTicket, AdminSupportTicketDetail, PagedResponse, SupportPriority, SupportStatus } from '../lib/types';

const SUPPORT_STATUSES: SupportStatus[] = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
const SUPPORT_PRIORITIES: SupportPriority[] = ['LOW', 'NORMAL', 'HIGH', 'URGENT'];

export function Support() {
  const { request, session } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [tickets, setTickets] = useState<AdminSupportTicket[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [detail, setDetail] = useState<AdminSupportTicketDetail | null>(null);
  const [reply, setReply] = useState('');
  const [internalNote, setInternalNote] = useState('');

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const pageSize = 25;
  const query = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      status: searchParams.get('status') ?? '',
      priority: searchParams.get('priority') ?? '',
      page,
      pageSize,
    }),
    [page, searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const next = await request<PagedResponse<AdminSupportTicket>>('/admin/support/tickets', { query });
      setTickets(next.items);
      setTotal(next.total);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Destek kayıtları alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);
  useLiveReload(load);

  async function updateStatus(ticketId: string, status: SupportStatus) {
    setError('');
    try {
      await request(`/admin/support/tickets/${ticketId}`, {
        method: 'PATCH',
        body: { status },
      });
      await load();
      if (detail?.id === ticketId) {
        await openDetail(ticketId);
      }
      setToast('Destek durumu güncellendi.');
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : 'Destek kaydı güncellenemedi.');
    }
  }

  async function updatePriority(ticketId: string, priority: SupportPriority) {
    setError('');
    try {
      await request(`/admin/support/tickets/${ticketId}`, {
        method: 'PATCH',
        body: { priority },
      });
      await load();
      if (detail?.id === ticketId) {
        await openDetail(ticketId);
      }
      setToast('Öncelik güncellendi.');
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : 'Öncelik güncellenemedi.');
    }
  }

  async function openDetail(ticketId: string) {
    const next = await request<AdminSupportTicketDetail>(`/admin/support/tickets/${ticketId}`);
    setDetail(next);
  }

  async function updateAssignment(ticketId: string, assignedAdminId: string | null) {
    setSaving(true);
    setError('');
    try {
      await request(`/admin/support/tickets/${ticketId}/assignment`, {
        method: 'PATCH',
        body: { assignedAdminId },
      });
      await load();
      if (detail?.id === ticketId) {
        await openDetail(ticketId);
      }
      setToast(assignedAdminId ? 'Talep size atandı.' : 'Atama kaldırıldı.');
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : 'Atama güncellenemedi.');
    } finally {
      setSaving(false);
    }
  }

  async function sendMessage(isInternal: boolean) {
    if (!detail) {
      return;
    }
    const body = isInternal ? internalNote : reply;
    if (!body.trim()) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request(`/admin/support/tickets/${detail.id}/messages`, {
        method: 'POST',
        body: { body, isInternal },
      });
      setReply('');
      setInternalNote('');
      await openDetail(detail.id);
      await load();
      setToast(isInternal ? 'İç not eklendi.' : 'Yanıt kaydedildi.');
    } catch (sendError) {
      setError(sendError instanceof Error ? sendError.message : 'Mesaj kaydedilemedi.');
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
    return <LoadingState label="Destek kayıtları yükleniyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="Destek"
        description="Müşteri ve işletme kaynaklı tüm destek taleplerini tek kuyrukta yönetin."
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
              {SUPPORT_STATUSES.map((status) => (
                <option key={status} value={status}>
                  {supportStatusLabel(status)}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Öncelik</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('priority', event.target.value)}
              value={searchParams.get('priority') ?? ''}
            >
              <option value="">Tümü</option>
              {SUPPORT_PRIORITIES.map((priority) => (
                <option key={priority} value={priority}>
                  {priority}
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

      <Panel title="Destek Kuyruğu">
        {tickets.length === 0 ? (
          <EmptyState message="Destek talebi bulunmuyor." />
        ) : (
          <div className="space-y-4">
            {tickets.map((ticket) => (
              <div className="rounded-2xl border border-slate-100 p-5" key={ticket.id}>
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-bold">{ticket.subject}</h3>
                      <StatusBadge
                        label={supportStatusLabel(ticket.status)}
                        tone={
                          ticket.status === 'RESOLVED'
                            ? 'success'
                            : ticket.status === 'CLOSED'
                              ? 'danger'
                              : 'warning'
                        }
                      />
                      <StatusBadge label={ticket.priority} tone={ticket.priority === 'URGENT' || ticket.priority === 'HIGH' ? 'danger' : 'info'} />
                    </div>
                    <p className="mt-2 text-sm text-slate-500">
                      {ticket.userName} · {ticket.userEmail} · {ticket.channel}
                    </p>
                    <p className="mt-4 text-sm text-slate-700 whitespace-pre-wrap">{ticket.message}</p>
                    {ticket.assignedAdminName ? (
                      <p className="mt-2 text-xs text-slate-500">Atanan: {ticket.assignedAdminName}</p>
                    ) : null}
                  </div>
                  <div className="min-w-[220px]">
                    <p className="text-sm text-slate-500">{formatDate(ticket.createdAt)}</p>
                    <select
                      className="mt-3 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
                      onChange={(event) => void updateStatus(ticket.id, event.target.value as SupportStatus)}
                      value={ticket.status}
                    >
                      {SUPPORT_STATUSES.map((status) => (
                        <option key={status} value={status}>
                          {supportStatusLabel(status)}
                        </option>
                      ))}
                    </select>
                    <select
                      className="mt-3 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
                      onChange={(event) => void updatePriority(ticket.id, event.target.value as SupportPriority)}
                      value={ticket.priority}
                    >
                      {SUPPORT_PRIORITIES.map((priority) => (
                        <option key={priority} value={priority}>
                          {priority}
                        </option>
                      ))}
                    </select>
                    <button
                      className="mt-3 w-full rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold hover:bg-slate-50"
                      onClick={() => void openDetail(ticket.id)}
                      type="button"
                    >
                      Detay
                    </button>
                    {session?.user.id ? (
                      <button
                        className="mt-2 w-full rounded-2xl border border-emerald-200 px-4 py-2 text-sm font-semibold text-emerald-700 hover:bg-emerald-50 disabled:opacity-60"
                        disabled={saving}
                        onClick={() =>
                          void updateAssignment(
                            ticket.id,
                            ticket.assignedAdminId === session.user.id ? null : session.user.id,
                          )
                        }
                        type="button"
                      >
                        {ticket.assignedAdminId === session.user.id ? 'Atamayı Kaldır' : 'Bana Ata'}
                      </button>
                    ) : null}
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
        open={detail !== null}
        onClose={() => setDetail(null)}
        title={detail ? detail.subject : 'Destek Detayı'}
      >
        {detail ? (
          <div className="space-y-6">
            <div className="rounded-2xl border border-slate-100 p-4">
              <p className="text-sm text-slate-500">{detail.userName} · {detail.userEmail}</p>
              <p className="mt-3 whitespace-pre-wrap text-sm text-slate-700">{detail.message}</p>
              <div className="mt-4 flex flex-wrap items-center gap-3">
                <StatusBadge label={detail.priority} tone={detail.priority === 'URGENT' || detail.priority === 'HIGH' ? 'danger' : 'info'} />
                <StatusBadge
                  label={supportStatusLabel(detail.status)}
                  tone={
                    detail.status === 'RESOLVED'
                      ? 'success'
                      : detail.status === 'CLOSED'
                        ? 'danger'
                        : 'warning'
                  }
                />
                {detail.assignedAdminName ? (
                  <StatusBadge label={`Atanan: ${detail.assignedAdminName}`} tone="default" />
                ) : (
                  <StatusBadge label="Atama yok" tone="default" />
                )}
              </div>
            </div>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <label className="block">
                <span className="text-sm font-semibold text-slate-600">Durum</span>
                <select
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
                  onChange={(event) => void updateStatus(detail.id, event.target.value as SupportStatus)}
                  value={detail.status}
                >
                  {SUPPORT_STATUSES.map((status) => (
                    <option key={status} value={status}>
                      {supportStatusLabel(status)}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="text-sm font-semibold text-slate-600">Öncelik</span>
                <select
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
                  onChange={(event) => void updatePriority(detail.id, event.target.value as SupportPriority)}
                  value={detail.priority}
                >
                  {SUPPORT_PRIORITIES.map((priority) => (
                    <option key={priority} value={priority}>
                      {priority}
                    </option>
                  ))}
                </select>
              </label>
              <div className="flex items-end">
                {session?.user.id ? (
                  <button
                    className="w-full rounded-2xl border border-emerald-200 px-4 py-3 text-sm font-semibold text-emerald-700 hover:bg-emerald-50 disabled:opacity-60"
                    disabled={saving}
                    onClick={() =>
                      void updateAssignment(
                        detail.id,
                        detail.assignedAdminId === session.user.id ? null : session.user.id,
                      )
                    }
                    type="button"
                  >
                    {detail.assignedAdminId === session.user.id ? 'Atamayı Kaldır' : 'Bana Ata'}
                  </button>
                ) : null}
              </div>
            </div>
            <Panel title="Konuşma">
              {detail.messages.length === 0 ? (
                <EmptyState message="Henüz yanıt veya iç not yok." />
              ) : (
                <div className="space-y-3">
                  {detail.messages.map((message) => (
                    <div className="rounded-2xl border border-slate-100 p-4" key={message.id}>
                      <div className="flex items-center justify-between gap-3">
                        <p className="text-sm font-bold">{message.authorName}</p>
                        <StatusBadge label={message.isInternal ? 'İç not' : 'Yanıt'} tone={message.isInternal ? 'warning' : 'success'} />
                      </div>
                      <p className="mt-2 whitespace-pre-wrap text-sm text-slate-700">{message.body}</p>
                      <p className="mt-2 text-xs text-slate-500">{formatDate(message.createdAt)}</p>
                    </div>
                  ))}
                </div>
              )}
            </Panel>
            <TextArea label="Yanıt" onChange={setReply} rows={4} value={reply} />
            <div className="flex justify-end">
              <button
                className="rounded-2xl bg-primary px-5 py-3 text-sm font-bold text-white disabled:opacity-60"
                disabled={saving}
                onClick={() => void sendMessage(false)}
                type="button"
              >
                Yanıtı Kaydet
              </button>
            </div>
            <TextArea label="İç Not" onChange={setInternalNote} rows={3} value={internalNote} />
            <div className="flex justify-end">
              <button
                className="rounded-2xl border border-amber-200 px-5 py-3 text-sm font-bold text-amber-700 disabled:opacity-60"
                disabled={saving}
                onClick={() => void sendMessage(true)}
                type="button"
              >
                İç Not Ekle
              </button>
            </div>
          </div>
        ) : null}
      </Modal>
    </div>
  );
}
