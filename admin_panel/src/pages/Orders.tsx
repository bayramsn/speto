import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { BulkBar, EmptyState, LoadingState, PageHeader, Pagination, Panel, StatusBadge, TextInput, Toast } from '../components/ui';
import { useLiveReload } from '../hooks/useLiveReload';
import { formatCurrency, formatDate, orderStatusLabel, orderStatusTone } from '../lib/formatters';
import type { AdminOrder, OrderStatus, PagedResponse } from '../lib/types';

const ORDER_STATUSES: OrderStatus[] = [
  'CREATED',
  'ACCEPTED',
  'PREPARING',
  'READY',
  'COMPLETED',
  'CANCELLED',
];

export function Orders() {
  const { request, downloadCsv } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const pageSize = 25;
  const query = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      status: searchParams.get('status') ?? '',
      page,
      pageSize,
    }),
    [page, searchParams],
  );
  const exportQuery = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      status: searchParams.get('status') ?? '',
    }),
    [searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const next = await request<PagedResponse<AdminOrder>>('/admin/orders', { query });
      setOrders(next.items);
      setTotal(next.total);
      setSelectedIds([]);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Siparişler alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);
  useLiveReload(load);

  async function updateStatus(order: AdminOrder, status: OrderStatus) {
    if (order.status !== status && !window.confirm(`${order.pickupCode} siparişi ${orderStatusLabel(status)} yapılacak. Onaylıyor musunuz?`)) {
      return;
    }
    setError('');
    try {
      await request(`/admin/businesses/${order.vendorId}/orders/${order.id}/status`, {
        method: 'PATCH',
        body: { status },
      });
      await load();
      setToast('Sipariş durumu güncellendi.');
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : 'Sipariş güncellenemedi.');
    }
  }

  async function bulkStatus(status: OrderStatus) {
    if (selectedIds.length === 0) {
      return;
    }
    if (!window.confirm(`${selectedIds.length} sipariş ${orderStatusLabel(status)} yapılacak. Onaylıyor musunuz?`)) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      await request('/admin/orders/bulk-status', {
        method: 'POST',
        body: { orderIds: selectedIds, status },
      });
      await load();
      setToast('Toplu sipariş işlemi tamamlandı.');
    } catch (bulkError) {
      setError(bulkError instanceof Error ? bulkError.message : 'Toplu sipariş işlemi başarısız.');
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
    return <LoadingState label="Global sipariş akışı yükleniyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="Siparişler"
        description="Tüm işletmelerdeki sipariş akışını tek yerden yönetin."
        action={
          <button
            className="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold hover:bg-slate-50"
            onClick={() => void downloadCsv('/admin/export/orders', 'orders.csv', exportQuery)}
            type="button"
          >
            CSV Export
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
            <span className="text-sm font-semibold text-slate-600">Durum</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => updateParam('status', event.target.value)}
              value={searchParams.get('status') ?? ''}
            >
              <option value="">Tümü</option>
              {ORDER_STATUSES.map((status) => (
                <option key={status} value={status}>
                  {orderStatusLabel(status)}
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

      <BulkBar count={selectedIds.length}>
        {ORDER_STATUSES.map((status) => (
          <button
            className="rounded-2xl bg-white px-4 py-2 font-bold text-emerald-800 disabled:opacity-60"
            disabled={saving}
            key={status}
            onClick={() => void bulkStatus(status)}
            type="button"
          >
            {orderStatusLabel(status)}
          </button>
        ))}
      </BulkBar>

      <Panel title="Global Sipariş Akışı">
        {orders.length === 0 ? (
          <EmptyState message="Sipariş bulunmuyor." />
        ) : (
          <div className="space-y-4">
            {orders.map((order) => (
              <div className="rounded-2xl border border-slate-100 p-5" key={order.id}>
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                  <div>
                    <div className="flex flex-wrap items-center gap-3">
                      <input
                        checked={selectedIds.includes(order.id)}
                        onChange={(event) => toggleSelected(order.id, event.target.checked)}
                        type="checkbox"
                      />
                      <h3 className="font-bold">{order.vendorName}</h3>
                      <StatusBadge
                        label={orderStatusLabel(order.status)}
                        tone={orderStatusTone(order.status)}
                      />
                    </div>
                    <p className="mt-2 text-sm text-slate-500">
                      {order.userName} · {order.userEmail} · {order.pickupCode}
                    </p>
                    <p className="mt-3 text-sm text-slate-700">
                      {order.items.map((item) => `${item.title} x${item.quantity}`).join(', ')}
                    </p>
                  </div>

                  <div className="w-full max-w-xs">
                    <p className="text-sm font-bold text-right">{formatCurrency(order.totalAmount)}</p>
                    <p className="text-xs text-slate-500 text-right">{formatDate(order.createdAt)}</p>
                    <select
                      className="mt-3 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
                      onChange={(event) => void updateStatus(order, event.target.value as OrderStatus)}
                      value={order.status}
                    >
                      {ORDER_STATUSES.map((status) => (
                        <option key={status} value={status}>
                          {orderStatusLabel(status)}
                        </option>
                      ))}
                    </select>
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
    </div>
  );
}
