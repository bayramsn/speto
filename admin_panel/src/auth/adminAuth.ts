import { createContext, useContext } from 'react';

import type { AdminHttpMethod, AdminQuery } from '../lib/adminApi';
import type { AdminSession } from '../lib/types';

export type AdminRequestOptions = {
  method?: AdminHttpMethod;
  body?: unknown;
  query?: AdminQuery;
  responseType?: 'json' | 'text' | 'blob';
};

export type AdminAuthContextValue = {
  session: AdminSession | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  request: <T>(path: string, options?: AdminRequestOptions) => Promise<T>;
  downloadCsv: (path: string, filename: string, query?: AdminQuery) => Promise<void>;
};

export const AdminAuthContext = createContext<AdminAuthContextValue | null>(null);

export function useAdminAuth() {
  const context = useContext(AdminAuthContext);
  if (!context) {
    throw new Error('useAdminAuth must be used within AdminAuthProvider');
  }
  return context;
}
