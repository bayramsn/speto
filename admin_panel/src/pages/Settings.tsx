import { useEffect, useState } from 'react';

import { useAdminAuth } from '../auth/AdminAuthContext';
import { LoadingState, PageHeader, Panel, TextArea, TextInput } from '../components/ui';
import type { AdminSettings } from '../lib/types';

export function Settings() {
  const { request } = useAdminAuth();
  const [settings, setSettings] = useState<AdminSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError('');
      try {
        const next = await request<AdminSettings>('/admin/settings');
        if (!cancelled) {
          setSettings(next);
        }
      } catch (loadError) {
        if (!cancelled) {
          setError(loadError instanceof Error ? loadError.message : 'Ayarlar alınamadı.');
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

  async function saveSettings() {
    if (!settings) {
      return;
    }
    setSaving(true);
    setError('');
    try {
      const next = await request<AdminSettings>('/admin/settings', {
        method: 'PATCH',
        body: settings,
      });
      setSettings(next);
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Ayarlar kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  }

  if (loading || !settings) {
    return <LoadingState label="Ayarlar yükleniyor..." />;
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Ayarlar"
        description="Platform genelinde davranış gösteren ayarları buradan yönetin."
        action={
          <button
            className="rounded-2xl bg-primary text-white px-5 py-3 text-sm font-bold hover:bg-emerald-700 transition-colors disabled:opacity-60"
            disabled={saving}
            onClick={() => void saveSettings()}
            type="button"
          >
            {saving ? 'Kaydediliyor...' : 'Ayarları Kaydet'}
          </button>
        }
      />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <Panel title="Platform Ayarları" description="Admin backend üzerinde kalıcı olarak saklanan değerler.">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <TextInput
            label="Destek E-postası"
            onChange={(value) => setSettings((current) => current ? { ...current, supportEmail: value } : current)}
            value={settings.supportEmail}
          />
          <TextInput
            label="Destek Telefonu"
            onChange={(value) => setSettings((current) => current ? { ...current, supportPhone: value } : current)}
            value={settings.supportPhone}
          />
          <TextInput
            label="Varsayılan Komisyon (%)"
            onChange={(value) => setSettings((current) => current ? { ...current, defaultCommissionRate: Number(value) || 0 } : current)}
            type="number"
            value={settings.defaultCommissionRate}
          />
          <label className="flex items-center gap-3 mt-8">
            <input
              checked={settings.notificationsEnabled}
              onChange={(event) =>
                setSettings((current) =>
                  current
                    ? { ...current, notificationsEnabled: event.target.checked }
                    : current,
                )
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Genel bildirim sistemi aktif</span>
          </label>
          <label className="flex items-center gap-3 mt-2 md:mt-8">
            <input
              checked={settings.maintenanceMode}
              onChange={(event) =>
                setSettings((current) =>
                  current ? { ...current, maintenanceMode: event.target.checked } : current,
                )
              }
              type="checkbox"
            />
            <span className="text-sm font-semibold text-slate-600">Bakım modu</span>
          </label>
        </div>
        <div className="mt-5">
          <TextArea
            label="Duyuru Bandı"
            onChange={(value) =>
              setSettings((current) => (current ? { ...current, announcementBanner: value } : current))
            }
            rows={5}
            value={settings.announcementBanner}
          />
        </div>
      </Panel>
    </div>
  );
}
