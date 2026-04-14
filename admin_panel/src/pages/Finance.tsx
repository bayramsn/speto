import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { EmptyState, LoadingState, MetricCard, PageHeader, Panel } from '../components/ui';
import { formatCurrency, formatDate } from '../lib/formatters';
import type { FinanceSummary } from '../lib/types';

export function Finance() {
  const { request } = useAdminAuth();
  const [summary, setSummary] = useState<FinanceSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const next = await request<FinanceSummary>('/admin/finance/summary');
        if (!cancelled) {
          setSummary(next);
        }
      } catch (loadError) {
        if (!cancelled) {
          setError(loadError instanceof Error ? loadError.message : 'Finans verisi alınamadı.');
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
    return <LoadingState label="Finans verileri hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Finans"
        description="Platform genelindeki gelir, payout ve işletme bakiyelerini canlı olarak yönetin."
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      {summary ? (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
            <MetricCard label="Brüt Hacim" value={formatCurrency(summary.grossVolume)} tone="primary" />
            <MetricCard label="Tamamlanan Sipariş" value={String(summary.completedOrders)} />
            <MetricCard label="Ödenen Payout" value={formatCurrency(summary.totalPayouts)} />
            <MetricCard label="Bekleyen Payout" value={formatCurrency(summary.pendingPayouts)} tone="warning" />
          </div>

          <Panel title="İşletme Bakiyeleri" description="Her işletmenin admin tarafından görülen anlık bakiyesi.">
            {summary.vendorBalances.length === 0 ? (
              <EmptyState message="Bakiye verisi bulunamadı." />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="text-xs uppercase tracking-wide text-slate-500">
                    <tr>
                      <th className="py-3">İşletme</th>
                      <th className="py-3">Kullanılabilir</th>
                      <th className="py-3">Bekleyen</th>
                      <th className="py-3">Son ödeme</th>
                    </tr>
                  </thead>
                  <tbody>
                    {summary.vendorBalances.map((item) => (
                      <tr className="border-t border-slate-100" key={item.vendorId}>
                        <td className="py-4 font-semibold">{item.vendorName}</td>
                        <td className="py-4">{formatCurrency(item.availableBalance)}</td>
                        <td className="py-4">{formatCurrency(item.pendingPayouts)}</td>
                        <td className="py-4">{formatDate(item.lastPayoutAt)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Panel>

          <Panel title="Son Payout Talepleri" description="İşletme bazlı ödeme akışı.">
            {summary.recentPayouts.length === 0 ? (
              <EmptyState message="Henüz payout kaydı bulunmuyor." />
            ) : (
              <div className="space-y-4">
                {summary.recentPayouts.map((payout) => (
                  <div className="rounded-2xl border border-slate-100 p-4" key={payout.id}>
                    <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
                      <div>
                        <p className="font-bold">{payout.vendorName}</p>
                        <p className="text-sm text-slate-500">
                          {payout.bankName} · {payout.iban}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-bold">{formatCurrency(payout.amount)}</p>
                        <p className="text-xs text-slate-500">{formatDate(payout.requestedAt)}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Panel>
        </>
      ) : (
        <Panel>
          <EmptyState message="Finans verisi bulunamadı." />
        </Panel>
      )}
    </div>
  );
}
