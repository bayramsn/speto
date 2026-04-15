import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, MetricCard, PageHeader, Panel, StatusBadge } from '../components/ui';
import { formatCurrency, formatDate, orderStatusLabel, orderStatusTone } from '../lib/formatters';
import type { DashboardSummary } from '../lib/types';

export function Dashboard() {
  const { request } = useAdminAuth();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError('');
      try {
        const next = await request<DashboardSummary>('/admin/dashboard/summary');
        if (!cancelled) {
          setSummary(next);
        }
      } catch (loadError) {
        if (!cancelled) {
          setError(loadError instanceof Error ? loadError.message : 'Dashboard alınamadı.');
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [request]);

  if (loading) {
    return <LoadingState label="Dashboard verileri hazırlanıyor..." />;
  }

  if (!summary) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Dashboard"
          description="Platformun canlı operasyon, işletme ve sipariş akışını buradan izleyin."
        />
        <Panel>{error ? <EmptyState message={error} /> : <EmptyState message="Dashboard verisi bulunamadı." />}</Panel>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Dashboard"
        description="God-mode panelin canlı görünümü. Sipariş, işletme, kullanıcı ve kampanya hareketlerini tek ekranda izleyin."
      />

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
        <MetricCard label="Toplam Hacim" value={formatCurrency(summary.metrics.grossVolume)} tone="primary" />
        <MetricCard label="Aktif İşletme" value={String(summary.metrics.activeBusinesses)} />
        <MetricCard label="Toplam Kullanıcı" value={String(summary.metrics.totalUsers)} />
        <MetricCard label="Açık Destek Talebi" value={String(summary.metrics.openSupportTickets)} tone="warning" />
      </div>

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <Panel title="Son Eklenen İşletmeler" description="Admin paneline son düşen işletme kayıtları.">
          {summary.recentBusinesses.length === 0 ? (
            <EmptyState message="Henüz işletme kaydı bulunmuyor." />
          ) : (
            <div className="space-y-4">
              {summary.recentBusinesses.map((business) => (
                <div
                  className="flex items-center justify-between gap-4 rounded-2xl border border-slate-100 p-4"
                  key={business.id}
                >
                  <div>
                    <p className="font-bold">{business.name}</p>
                    <p className="text-sm text-slate-500">
                      {business.category} · {business.city || 'Şehir yok'}
                    </p>
                  </div>
                  <StatusBadge
                    label={business.approvalStatus === 'APPROVED' ? 'Onaylı' : 'Bekliyor'}
                    tone={business.approvalStatus === 'APPROVED' ? 'success' : 'warning'}
                  />
                </div>
              ))}
            </div>
          )}
        </Panel>

        <Panel
          title="Son Siparişler"
          description="Tüm işletmelerden gelen en yeni siparişler."
        >
          {summary.recentOrders.length === 0 ? (
            <EmptyState message="Henüz sipariş bulunmuyor." />
          ) : (
            <div className="space-y-4">
              {summary.recentOrders.map((order) => (
                <div className="rounded-2xl border border-slate-100 p-4" key={order.id}>
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="font-bold">{order.vendorName}</p>
                      <p className="text-sm text-slate-500">
                        {order.userName} · {formatDate(order.createdAt)}
                      </p>
                    </div>
                    <StatusBadge label={orderStatusLabel(order.status)} tone={orderStatusTone(order.status)} />
                  </div>
                  <p className="mt-3 text-sm text-slate-600">
                    {order.items.map((item) => `${item.title} x${item.quantity}`).join(', ')}
                  </p>
                  <p className="mt-3 font-bold">{formatCurrency(order.totalAmount)}</p>
                </div>
              ))}
            </div>
          )}
        </Panel>

        <Panel
          title="Aktif Kampanyalar"
          description="En son güncellenen kampanya akışları."
        >
          {summary.topCampaigns.length === 0 ? (
            <EmptyState message="Aktif kampanya bulunmuyor." />
          ) : (
            <div className="space-y-4">
              {summary.topCampaigns.map((campaign) => (
                <div className="rounded-2xl border border-slate-100 p-4" key={campaign.id}>
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="font-bold">{campaign.title}</p>
                      <p className="text-sm text-slate-500">{campaign.vendorName}</p>
                    </div>
                    <StatusBadge
                      label={campaign.status === 'ACTIVE' ? 'Aktif' : 'Taslak'}
                      tone={campaign.status === 'ACTIVE' ? 'success' : 'default'}
                    />
                  </div>
                  <p className="mt-3 text-sm text-slate-600">
                    {campaign.productTitles.slice(0, 3).join(', ') || 'Ürün bağlı değil'}
                  </p>
                </div>
              ))}
            </div>
          )}
        </Panel>
      </div>
    </div>
  );
}
