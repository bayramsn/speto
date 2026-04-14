import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { EmptyState, LoadingState, PageHeader, Panel, StatusBadge } from '../components/ui';
import { formatDate, supportStatusLabel } from '../lib/formatters';
import type { AdminSupportTicket, SupportStatus } from '../lib/types';

const SUPPORT_STATUSES: SupportStatus[] = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

export function Support() {
  const { request } = useAdminAuth();
  const [tickets, setTickets] = useState<AdminSupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    try {
      const next = await request<AdminSupportTicket[]>('/admin/support/tickets');
      setTickets(next);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Destek kayıtları alınamadı.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function updateStatus(ticketId: string, status: SupportStatus) {
    await request(`/admin/support/tickets/${ticketId}`, {
      method: 'PATCH',
      body: { status },
    });
    await load();
  }

  if (loading) {
    return <LoadingState label="Destek kayıtları yükleniyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Destek"
        description="Müşteri ve işletme kaynaklı tüm destek taleplerini tek kuyrukta yönetin."
      />

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
                    </div>
                    <p className="mt-2 text-sm text-slate-500">
                      {ticket.userName} · {ticket.userEmail} · {ticket.channel}
                    </p>
                    <p className="mt-4 text-sm text-slate-700 whitespace-pre-wrap">{ticket.message}</p>
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
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </Panel>
    </div>
  );
}
