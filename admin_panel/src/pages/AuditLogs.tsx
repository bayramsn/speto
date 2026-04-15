import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuth';
import { EmptyState, LoadingState, PageHeader, Pagination, Panel, TextInput } from '../components/ui';
import { useLiveReload } from '../hooks/useLiveReload';
import { formatDate } from '../lib/formatters';
import type { AdminAuditLog, PagedResponse } from '../lib/types';

const PAGE_SIZE = 25;

export function AuditLogs() {
  const { request } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [logs, setLogs] = useState<AdminAuditLog[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);
  const query = useMemo(
    () => ({
      q: searchParams.get('q') ?? '',
      action: searchParams.get('action') ?? '',
      entityType: searchParams.get('entityType') ?? '',
      page,
      pageSize: PAGE_SIZE,
    }),
    [page, searchParams],
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const next = await request<PagedResponse<AdminAuditLog>>('/admin/audit-logs', {
        query,
      });
      setLogs(next.items);
      setTotal(next.total);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Audit kayıtları alınamadı.');
    } finally {
      setLoading(false);
    }
  }, [query, request]);

  useEffect(() => {
    void load();
  }, [load]);
  useLiveReload(load);

  function updateParam(key: string, value: string) {
    const next = new URLSearchParams(searchParams);
    if (value.trim()) {
      next.set(key, value.trim());
    } else {
      next.delete(key);
    }
    next.set('page', '1');
    setSearchParams(next);
  }

  if (loading) {
    return <LoadingState label="Audit kayıtları hazırlanıyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Audit Logs"
        description="Admin işlemlerinin kim, ne zaman, hangi varlık üzerinde yaptığı değişikliklerle izlenebilir kaydı."
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <Panel title="Filtreler">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <TextInput
            label="Arama"
            onChange={(value) => updateParam('q', value)}
            value={searchParams.get('q') ?? ''}
          />
          <TextInput
            label="Aksiyon"
            onChange={(value) => updateParam('action', value)}
            value={searchParams.get('action') ?? ''}
          />
          <TextInput
            label="Varlık Tipi"
            onChange={(value) => updateParam('entityType', value)}
            value={searchParams.get('entityType') ?? ''}
          />
        </div>
      </Panel>

      <Panel title="Kayıtlar">
        {logs.length === 0 ? (
          <EmptyState message="Audit kaydı bulunamadı." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="py-3">Zaman</th>
                  <th className="py-3">Admin</th>
                  <th className="py-3">Aksiyon</th>
                  <th className="py-3">Varlık</th>
                  <th className="py-3">Metadata</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <tr className="border-t border-slate-100 align-top" key={log.id}>
                    <td className="py-4 text-sm text-slate-600">{formatDate(log.createdAt)}</td>
                    <td className="py-4">
                      <p className="font-semibold">{log.adminUserName}</p>
                      <p className="text-xs text-slate-500">{log.adminUserEmail}</p>
                    </td>
                    <td className="py-4 font-semibold">{log.action}</td>
                    <td className="py-4 text-sm text-slate-600">
                      {log.entityType}
                      {log.entityId ? ` · ${log.entityId}` : ''}
                    </td>
                    <td className="py-4">
                      <pre className="max-w-sm whitespace-pre-wrap rounded-2xl bg-slate-50 p-3 text-xs text-slate-600">
                        {log.metadata ? JSON.stringify(log.metadata, null, 2) : '-'}
                      </pre>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <Pagination
          page={page}
          pageSize={PAGE_SIZE}
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
