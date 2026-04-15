import { useCallback, useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, MetricCard, Modal, PageHeader, Panel, TextArea, TextInput, Toast } from '../components/ui';
import { formatCurrency, formatDate } from '../lib/formatters';
import type { BusinessListItem, BusinessProfileResponse, FinanceSummary } from '../lib/types';

type PayoutDraft = {
  vendorId: string;
  bankAccountId: string;
  amount: string;
  note: string;
};

export function Finance() {
  const { request } = useAdminAuth();
  const [summary, setSummary] = useState<FinanceSummary | null>(null);
  const [businesses, setBusinesses] = useState<BusinessListItem[]>([]);
  const [profile, setProfile] = useState<BusinessProfileResponse | null>(null);
  const [detailProfile, setDetailProfile] = useState<BusinessProfileResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [selectedVendorId, setSelectedVendorId] = useState('');
  const [draft, setDraft] = useState<PayoutDraft>({
    vendorId: '',
    bankAccountId: '',
    amount: '',
    note: '',
  });

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [next, nextBusinesses] = await Promise.all([
        request<FinanceSummary>('/admin/finance/summary'),
        request<BusinessListItem[]>('/admin/businesses'),
      ]);
      setSummary(next);
      setBusinesses(nextBusinesses);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Finans verisi alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [request]);

  useEffect(() => {
    void load();
  }, [load]);

  async function openPayoutModal() {
    const vendorId = businesses[0]?.id ?? '';
    setDraft({ vendorId, bankAccountId: '', amount: '', note: '' });
    setProfile(null);
    setModalOpen(true);
    if (vendorId) {
      await loadProfile(vendorId);
    }
  }

  async function loadProfile(vendorId: string) {
    if (!vendorId) {
      setProfile(null);
      return;
    }
    const next = await request<BusinessProfileResponse>(`/admin/businesses/${vendorId}/profile`);
    setProfile(next);
    setDraft((current) => ({
      ...current,
      vendorId,
      bankAccountId: next.bankAccounts.find((account) => account.isDefault)?.id ?? next.bankAccounts[0]?.id ?? '',
    }));
  }

  async function openVendorDetail(vendorId: string) {
    setSelectedVendorId(vendorId);
    setDetailOpen(true);
    setError('');
    try {
      const next = await request<BusinessProfileResponse>(`/admin/businesses/${vendorId}/profile`);
      setDetailProfile(next);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'İşletme detayı alınamadı.');
    }
  }

  function exportFinanceCsv() {
    if (!summary) {
      return;
    }
    const rows = [
      ['vendorId', 'vendorName', 'availableBalance', 'pendingPayouts', 'lastPayoutAt'],
      ...summary.vendorBalances.map((item) => [
        item.vendorId,
        item.vendorName,
        String(item.availableBalance),
        String(item.pendingPayouts),
        item.lastPayoutAt ?? '',
      ]),
      [],
      ['payoutId', 'vendorName', 'amount', 'status', 'requestedAt', 'completedAt', 'bankName', 'iban', 'note'],
      ...summary.recentPayouts.map((payout) => [
        payout.id,
        payout.vendorName,
        String(payout.amount),
        payout.status,
        payout.requestedAt,
        payout.completedAt ?? '',
        payout.bankName,
        payout.iban,
        payout.note ?? '',
      ]),
    ];
    const csv = rows
      .map((row) =>
        row
          .map((cell) => `"${String(cell).replaceAll('"', '""')}"`)
          .join(','),
      )
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = 'finance-summary.csv';
    anchor.click();
    URL.revokeObjectURL(url);
  }

  async function savePayout() {
    setSaving(true);
    setError('');
    try {
      const next = await request<FinanceSummary>('/admin/finance/payouts', {
        method: 'POST',
        body: {
          ...draft,
          amount: Number(draft.amount),
          status: 'PENDING',
        },
      });
      setSummary(next);
      setModalOpen(false);
      setToast('Payout talebi oluşturuldu.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Payout oluşturulamadı.');
    } finally {
      setSaving(false);
    }
  }

  async function updatePayout(payoutId: string, status: 'PAID' | 'FAILED') {
    setSaving(true);
    setError('');
    try {
      const next = await request<FinanceSummary>(`/admin/finance/payouts/${payoutId}`, {
        method: 'PATCH',
        body: { status },
      });
      setSummary(next);
      setToast(status === 'PAID' ? 'Payout ödendi işaretlendi.' : 'Payout başarısız işaretlendi.');
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : 'Payout güncellenemedi.');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return <LoadingState label="Finans verileri hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <Toast message={toast} onClose={() => setToast('')} />
      <PageHeader
        title="Finans"
        description="Platform genelindeki gelir, payout ve işletme bakiyelerini canlı olarak yönetin."
        action={
          <div className="flex flex-wrap gap-3">
            <button
              className="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-bold hover:bg-slate-50"
              onClick={exportFinanceCsv}
              type="button"
            >
              CSV Export
            </button>
            <button
              className="rounded-2xl bg-primary px-5 py-3 text-sm font-bold text-white hover:bg-emerald-700"
              onClick={() => void openPayoutModal()}
              type="button"
            >
              Payout Oluştur
            </button>
          </div>
        }
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
                        <td className="py-4">
                          <div className="flex items-center justify-between gap-3">
                            <span>{formatDate(item.lastPayoutAt)}</span>
                            <button
                              className="rounded-2xl border border-slate-200 px-3 py-2 text-xs font-semibold hover:bg-slate-50"
                              onClick={() => void openVendorDetail(item.vendorId)}
                              type="button"
                            >
                              Detay
                            </button>
                          </div>
                        </td>
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
                        {payout.note ? <p className="mt-2 text-sm text-slate-600">{payout.note}</p> : null}
                      </div>
                      <div className="text-right">
                        <p className="font-bold">{formatCurrency(payout.amount)}</p>
                        <p className="text-xs text-slate-500">{formatDate(payout.requestedAt)}</p>
                        <p className="mt-1 text-xs font-bold text-slate-500">{payout.status}</p>
                        {payout.status === 'PENDING' ? (
                          <div className="mt-3 flex justify-end gap-2">
                            <button
                              className="rounded-2xl border border-emerald-200 px-3 py-2 text-xs font-bold text-emerald-700 disabled:opacity-60"
                              disabled={saving}
                              onClick={() => void updatePayout(payout.id, 'PAID')}
                              type="button"
                            >
                              Ödendi
                            </button>
                            <button
                              className="rounded-2xl border border-red-200 px-3 py-2 text-xs font-bold text-red-700 disabled:opacity-60"
                              disabled={saving}
                              onClick={() => void updatePayout(payout.id, 'FAILED')}
                              type="button"
                            >
                              Başarısız
                            </button>
                          </div>
                        ) : null}
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

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Payout Oluştur">
        <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">İşletme</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => void loadProfile(event.target.value)}
              value={draft.vendorId}
            >
              {businesses.map((business) => (
                <option key={business.id} value={business.id}>
                  {business.name}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-semibold text-slate-600">Banka Hesabı</span>
            <select
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none"
              onChange={(event) => setDraft((current) => ({ ...current, bankAccountId: event.target.value }))}
              value={draft.bankAccountId}
            >
              <option value="">Banka hesabı seçin</option>
              {(profile?.bankAccounts ?? []).map((account) => (
                <option key={account.id} value={account.id}>
                  {account.bankName} · {account.iban}
                </option>
              ))}
            </select>
          </label>
          <TextInput
            label="Tutar"
            onChange={(value) => setDraft((current) => ({ ...current, amount: value }))}
            type="number"
            value={draft.amount}
          />
        </div>
        <div className="mt-5">
          <TextArea
            label="Not"
            onChange={(value) => setDraft((current) => ({ ...current, note: value }))}
            rows={3}
            value={draft.note}
          />
        </div>
        <div className="mt-6 flex justify-end">
          <button
            className="rounded-2xl bg-primary px-5 py-3 text-sm font-bold text-white disabled:opacity-60"
            disabled={saving || !draft.bankAccountId || !draft.amount}
            onClick={() => void savePayout()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Payout Kaydet'}
          </button>
        </div>
      </Modal>

      <Modal
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        title={detailProfile?.business.name ?? 'İşletme Finans Detayı'}
      >
        {summary && selectedVendorId ? (
          <div className="space-y-6">
            {summary.vendorBalances
              .filter((item) => item.vendorId === selectedVendorId)
              .map((item) => (
                <div className="grid grid-cols-1 gap-4 md:grid-cols-3" key={item.vendorId}>
                  <Panel title="Kullanılabilir">
                    <p className="text-2xl font-black">{formatCurrency(item.availableBalance)}</p>
                  </Panel>
                  <Panel title="Bekleyen Payout">
                    <p className="text-2xl font-black">{formatCurrency(item.pendingPayouts)}</p>
                  </Panel>
                  <Panel title="Son Ödeme">
                    <p className="text-sm font-semibold text-slate-700">{formatDate(item.lastPayoutAt)}</p>
                  </Panel>
                </div>
              ))}

            <Panel title="Banka Hesapları">
              {(detailProfile?.bankAccounts ?? []).length === 0 ? (
                <EmptyState message="İşletmenin banka hesabı bulunmuyor." />
              ) : (
                <div className="space-y-3">
                  {detailProfile?.bankAccounts.map((account) => (
                    <div className="rounded-2xl border border-slate-100 p-4" key={account.id}>
                      <div className="flex items-center justify-between gap-3">
                        <div>
                          <p className="font-bold">{account.bankName}</p>
                          <p className="text-sm text-slate-500">{account.iban}</p>
                        </div>
                        {account.isDefault ? <span className="text-xs font-bold text-emerald-700">Varsayılan</span> : null}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Panel>

            <Panel title="İlgili Payoutlar">
              {summary.recentPayouts.filter((item) => item.vendorId === selectedVendorId).length === 0 ? (
                <EmptyState message="Bu işletme için son payout kaydı bulunmuyor." />
              ) : (
                <div className="space-y-3">
                  {summary.recentPayouts
                    .filter((item) => item.vendorId === selectedVendorId)
                    .map((payout) => (
                      <div className="rounded-2xl border border-slate-100 p-4" key={payout.id}>
                        <div className="flex items-center justify-between gap-3">
                          <p className="font-bold">{formatCurrency(payout.amount)}</p>
                          <p className="text-xs font-bold text-slate-500">{payout.status}</p>
                        </div>
                        <p className="mt-2 text-sm text-slate-500">
                          {payout.bankName} · {payout.iban}
                        </p>
                        {payout.note ? <p className="mt-2 text-sm text-slate-700">{payout.note}</p> : null}
                        <p className="mt-2 text-xs text-slate-500">{formatDate(payout.requestedAt)}</p>
                      </div>
                    ))}
                </div>
              )}
            </Panel>
          </div>
        ) : null}
      </Modal>
    </div>
  );
}
