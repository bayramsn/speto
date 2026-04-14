import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { EmptyState, LoadingState, PageHeader, Panel, StatusBadge } from '../components/ui';
import { formatCurrency, formatDate, orderStatusLabel, orderStatusTone } from '../lib/formatters';
import type { AdminOrder, OrderStatus } from '../lib/types';

const ORDER_STATUSES: OrderStatus[] = [
  'CREATED',
  'ACCEPTED',
  'PREPARING',
  'READY',
  'COMPLETED',
  'CANCELLED',
];

export function Orders() {
  const { request } = useAdminAuth();
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    try {
      const next = await request<AdminOrder[]>('/admin/orders');
      setOrders(next);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Siparişler alınamadı.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function updateStatus(order: AdminOrder, status: OrderStatus) {
    await request(`/admin/businesses/${order.vendorId}/orders/${order.id}/status`, {
      method: 'PATCH',
      body: { status },
    });
    await load();
  }

  if (loading) {
    return <LoadingState label="Global sipariş akışı yükleniyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Siparişler"
        description="Tüm işletmelerdeki sipariş akışını tek yerden yönetin."
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

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
      </Panel>
    </div>
  );
}
