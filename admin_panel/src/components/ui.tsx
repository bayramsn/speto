import type { PropsWithChildren, ReactNode } from 'react';

export function PageHeader({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
      <div>
        <h2 className="text-3xl font-extrabold font-headline tracking-tight text-on-surface">
          {title}
        </h2>
        {description ? (
          <p className="mt-2 text-sm text-slate-500 max-w-2xl">{description}</p>
        ) : null}
      </div>
      {action ? <div>{action}</div> : null}
    </div>
  );
}

export function Panel({
  title,
  description,
  children,
  action,
}: PropsWithChildren<{
  title?: string;
  description?: string;
  action?: ReactNode;
}>) {
  return (
    <section className="bg-white rounded-[1.75rem] border border-slate-100 shadow-sm">
      {title || description || action ? (
        <div className="px-6 py-5 border-b border-slate-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            {title ? <h3 className="text-lg font-bold font-headline">{title}</h3> : null}
            {description ? <p className="text-sm text-slate-500 mt-1">{description}</p> : null}
          </div>
          {action ? <div>{action}</div> : null}
        </div>
      ) : null}
      <div className="p-6">{children}</div>
    </section>
  );
}

export function MetricCard({
  label,
  value,
  tone = 'default',
}: {
  label: string;
  value: string;
  tone?: 'default' | 'primary' | 'warning' | 'danger';
}) {
  const toneClass =
    tone === 'primary'
      ? 'bg-primary/10 text-primary'
      : tone === 'warning'
        ? 'bg-amber-100 text-amber-700'
        : tone === 'danger'
          ? 'bg-red-100 text-red-700'
          : 'bg-slate-100 text-slate-700';
  return (
    <div className="bg-surface-container-lowest rounded-[1.5rem] border border-slate-100 p-5">
      <div className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${toneClass}`}>
        {label}
      </div>
      <div className="mt-4 text-3xl font-black font-headline tracking-tight">{value}</div>
    </div>
  );
}

export function StatusBadge({
  label,
  tone = 'default',
}: {
  label: string;
  tone?: 'default' | 'success' | 'warning' | 'danger' | 'info';
}) {
  const toneClass =
    tone === 'success'
      ? 'bg-emerald-100 text-emerald-700'
      : tone === 'warning'
        ? 'bg-amber-100 text-amber-700'
        : tone === 'danger'
          ? 'bg-red-100 text-red-700'
          : tone === 'info'
            ? 'bg-blue-100 text-blue-700'
            : 'bg-slate-100 text-slate-700';
  return (
    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${toneClass}`}>
      {label}
    </span>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="py-10 text-center text-sm text-slate-500 border border-dashed border-slate-200 rounded-2xl">
      {message}
    </div>
  );
}

export function LoadingState({ label = 'Yükleniyor...' }: { label?: string }) {
  return (
    <div className="py-16 text-center">
      <div className="w-10 h-10 border-4 border-primary/20 border-t-primary rounded-full animate-spin mx-auto" />
      <p className="mt-4 text-sm text-slate-500">{label}</p>
    </div>
  );
}

export function Modal({
  open,
  title,
  onClose,
  children,
}: PropsWithChildren<{
  open: boolean;
  title: string;
  onClose: () => void;
}>) {
  if (!open) {
    return null;
  }
  return (
    <div
      aria-modal="true"
      className="fixed inset-0 bg-slate-950/40 backdrop-blur-sm flex items-center justify-center p-4 z-[100]"
      onMouseDown={onClose}
      role="dialog"
    >
      <div
        className="w-full max-w-3xl max-h-[90vh] bg-white rounded-[1.75rem] shadow-2xl overflow-hidden flex flex-col"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="flex items-center justify-between px-6 py-5 border-b border-slate-100">
          <h3 className="text-lg font-bold font-headline">{title}</h3>
          <button
            className="text-sm font-semibold text-slate-500 hover:text-slate-700"
            onClick={onClose}
            type="button"
          >
            Kapat
          </button>
        </div>
        <div className="p-6 overflow-y-auto">{children}</div>
      </div>
    </div>
  );
}

export function TextInput({
  label,
  value,
  onChange,
  type = 'text',
  placeholder,
}: {
  label: string;
  value: string | number;
  onChange: (value: string) => void;
  type?: string;
  placeholder?: string;
}) {
  return (
    <label className="block">
      <span className="text-sm font-semibold text-slate-600">{label}</span>
      <input
        className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        type={type}
        value={value}
      />
    </label>
  );
}

export function TextArea({
  label,
  value,
  onChange,
  rows = 4,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  rows?: number;
}) {
  return (
    <label className="block">
      <span className="text-sm font-semibold text-slate-600">{label}</span>
      <textarea
        className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 outline-none focus:border-primary focus:bg-white"
        onChange={(event) => onChange(event.target.value)}
        rows={rows}
        value={value}
      />
    </label>
  );
}

export function Toast({
  message,
  tone = 'success',
  onClose,
}: {
  message: string;
  tone?: 'success' | 'danger' | 'warning';
  onClose: () => void;
}) {
  if (!message) {
    return null;
  }
  const toneClass =
    tone === 'danger'
      ? 'border-red-200 bg-red-50 text-red-700'
      : tone === 'warning'
        ? 'border-amber-200 bg-amber-50 text-amber-800'
        : 'border-emerald-200 bg-emerald-50 text-emerald-800';
  return (
    <div className={`fixed right-6 top-20 z-[120] max-w-sm rounded-2xl border px-4 py-3 text-sm shadow-lg ${toneClass}`}>
      <div className="flex items-start gap-4">
        <p className="flex-1">{message}</p>
        <button className="font-bold" onClick={onClose} type="button">
          Kapat
        </button>
      </div>
    </div>
  );
}

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = 'Onayla',
  danger = false,
  onCancel,
  onConfirm,
}: {
  open: boolean;
  title: string;
  description: string;
  confirmLabel?: string;
  danger?: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  if (!open) {
    return null;
  }
  return (
    <div className="fixed inset-0 z-[130] flex items-center justify-center bg-slate-950/40 p-4" role="dialog" aria-modal="true">
      <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
        <h3 className="text-lg font-bold font-headline">{title}</h3>
        <p className="mt-2 text-sm text-slate-600">{description}</p>
        <div className="mt-6 flex justify-end gap-3">
          <button className="rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold" onClick={onCancel} type="button">
            Vazgeç
          </button>
          <button
            className={`rounded-2xl px-4 py-2 text-sm font-bold text-white ${danger ? 'bg-red-600 hover:bg-red-700' : 'bg-primary hover:bg-emerald-700'}`}
            onClick={onConfirm}
            type="button"
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

export function Pagination({
  page,
  pageSize,
  total,
  onPageChange,
}: {
  page: number;
  pageSize: number;
  total: number;
  onPageChange: (page: number) => void;
}) {
  const pageCount = Math.max(1, Math.ceil(total / pageSize));
  return (
    <div className="flex flex-col gap-3 border-t border-slate-100 px-6 py-4 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
      <span>
        {total} kayıt · Sayfa {page}/{pageCount}
      </span>
      <div className="flex gap-2">
        <button
          className="rounded-2xl border border-slate-200 px-4 py-2 font-semibold disabled:opacity-40"
          disabled={page <= 1}
          onClick={() => onPageChange(page - 1)}
          type="button"
        >
          Önceki
        </button>
        <button
          className="rounded-2xl border border-slate-200 px-4 py-2 font-semibold disabled:opacity-40"
          disabled={page >= pageCount}
          onClick={() => onPageChange(page + 1)}
          type="button"
        >
          Sonraki
        </button>
      </div>
    </div>
  );
}

export function BulkBar({
  count,
  children,
}: PropsWithChildren<{
  count: number;
}>) {
  if (count === 0) {
    return null;
  }
  return (
    <div className="sticky top-20 z-30 flex flex-col gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900 shadow-sm md:flex-row md:items-center md:justify-between">
      <span className="font-bold">{count} kayıt seçildi</span>
      <div className="flex flex-wrap gap-2">{children}</div>
    </div>
  );
}
