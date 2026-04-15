import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react';

import { AdminApiError, adminApiRequest } from '../lib/adminApi';
import type { AdminSession } from '../lib/types';
import { AdminAuthContext, type AdminRequestOptions } from './adminAuth';

export function AdminAuthProvider({ children }: PropsWithChildren) {
  const [session, setSession] = useState<AdminSession | null>(null);
  const [loading, setLoading] = useState(true);
  const refreshInFlight = useRef<Promise<AdminSession> | null>(null);

  const refreshSession = useCallback(async () => {
    if (!refreshInFlight.current) {
      refreshInFlight.current = adminApiRequest<AdminSession>('/admin/auth/refresh', {
        method: 'POST',
      })
        .then((nextSession) => {
          setSession(nextSession);
          return nextSession;
        })
        .finally(() => {
          refreshInFlight.current = null;
          setLoading(false);
        });
    }
    return refreshInFlight.current;
  }, []);

  useEffect(() => {
    void refreshSession().catch(() => {
      setSession(null);
      setLoading(false);
    });
  }, [refreshSession]);

  const login = useCallback(async (email: string, password: string) => {
    const nextSession = await adminApiRequest<AdminSession>('/admin/auth/login', {
      method: 'POST',
      body: { email, password },
    });
    setSession(nextSession);
    setLoading(false);
  }, []);

  const logout = useCallback(async () => {
    try {
      await adminApiRequest('/admin/auth/logout', {
        method: 'POST',
      });
    } catch {
      // logout is best-effort
    }
    setSession(null);
    setLoading(false);
  }, []);

  const request = useCallback(
    async function request<T>(path: string, options: AdminRequestOptions = {}) {
      if (!session) {
        throw new Error('Oturum bulunamadı');
      }
      try {
        return await adminApiRequest<T>(path, {
          ...options,
          accessToken: session.tokens.accessToken,
        });
      } catch (error) {
        if (error instanceof AdminApiError && error.status === 401) {
          const nextSession = await refreshSession();
          return adminApiRequest<T>(path, {
            ...options,
            accessToken: nextSession.tokens.accessToken,
          });
        }
        throw error;
      }
    },
    [refreshSession, session],
  );

  const downloadCsv = useCallback(
    async (path: string, filename: string, query: AdminRequestOptions['query'] = {}) => {
      const blob = await request<Blob>(path, {
        query,
        responseType: 'blob',
      });
      const url = window.URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = filename;
      anchor.click();
      window.URL.revokeObjectURL(url);
    },
    [request],
  );

  const value = useMemo(
    () => ({
      session,
      loading,
      login,
      logout,
      request,
      downloadCsv,
    }),
    [downloadCsv, loading, login, logout, request, session],
  );

  return <AdminAuthContext.Provider value={value}>{children}</AdminAuthContext.Provider>;
}
