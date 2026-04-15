import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, MetricCard, PageHeader, Panel } from '../components/ui';
import { formatCurrency } from '../lib/formatters';
import type { ReportsOverview } from '../lib/types';

export function Reports() {
  const { request } = useAdminAuth();
  const [report, setReport] = useState<ReportsOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const next = await request<ReportsOverview>('/admin/reports/overview');
        if (!cancelled) {
          setReport(next);
        }
      } catch (loadError) {
        if (!cancelled) {
          setError(loadError instanceof Error ? loadError.message : 'Rapor verisi alınamadı.');
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
    return <LoadingState label="Raporlar hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Raporlar"
        description="Gerçek sipariş ve ürün verisinden türetilen performans raporları."
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      {report ? (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-5 gap-5">
            <MetricCard label="Brüt Hacim" value={formatCurrency(report.grossVolume)} tone="primary" />
            <MetricCard label="Ortalama Sepet" value={formatCurrency(report.averageOrderValue)} />
            <MetricCard label="Tamamlanan Sipariş" value={String(report.completedOrders)} />
            <MetricCard label="Aktif İşletme" value={String(report.activeBusinesses)} />
            <MetricCard label="Aktif Kampanya" value={String(report.activeCampaigns)} />
          </div>

          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <Panel title="Günlük Gelir Serisi" description="Son 7 günün canlı gelir görünümü.">
              {report.dailyRevenue.length === 0 ? (
                <EmptyState message="Gelir serisi bulunamadı." />
              ) : (
                <div className="space-y-4">
                  {report.dailyRevenue.map((item) => (
                    <div className="flex items-center gap-3" key={item.date}>
                      <div className="w-28 text-sm text-slate-500">{item.date}</div>
                      <div className="flex-1 h-3 rounded-full bg-slate-100 overflow-hidden">
                        <div
                          className="h-full rounded-full bg-primary"
                          style={{
                            width: `${Math.min(
                              100,
                              report.grossVolume > 0 ? (item.total / report.grossVolume) * 100 * 7 : 0,
                            )}%`,
                          }}
                        />
                      </div>
                      <div className="w-32 text-right text-sm font-semibold">
                        {formatCurrency(item.total)}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Panel>

            <div className="xl:col-span-2">
              <Panel title="En Çok Satan Ürünler" description="Tamamlanan siparişlerden hesaplanan satış performansı.">
                {report.topProducts.length === 0 ? (
                  <EmptyState message="Henüz ürün raporu oluşmadı." />
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-left">
                      <thead className="text-xs uppercase tracking-wide text-slate-500">
                        <tr>
                          <th className="py-3">Ürün</th>
                          <th className="py-3">İşletme</th>
                          <th className="py-3">Satış</th>
                          <th className="py-3 text-right">Gelir</th>
                        </tr>
                      </thead>
                      <tbody>
                        {report.topProducts.map((product) => (
                          <tr className="border-t border-slate-100" key={product.productId}>
                            <td className="py-4 font-semibold">{product.title}</td>
                            <td className="py-4 text-slate-600">{product.vendorName}</td>
                            <td className="py-4">{product.quantity}</td>
                            <td className="py-4 text-right font-bold">
                              {formatCurrency(product.revenue)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </Panel>
            </div>
          </div>
        </>
      ) : (
        <Panel>
          <EmptyState message="Rapor verisi bulunamadı." />
        </Panel>
      )}
    </div>
  );
}
