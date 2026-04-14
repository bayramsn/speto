import {
  createContext,
  useContext,
  useEffect,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react';

import { adminApiRequest, AdminApiError } from '../lib/adminApi';
import type { AdminSession } from '../lib/types';

const STORAGE_KEY = 'sepetpro.admin.session';

type AdminAuthContextValue = {
  session: AdminSession | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  request: <T>(path: string, options?: { method?: 'GET' | 'POST' | 'PATCH'; body?: unknown }) => Promise<T>;
};

const AdminAuthContext = createContext<AdminAuthContextValue | null>(null);

export function AdminAuthProvider({ children }: PropsWithChildren) {
  const [session, setSession] = useState<AdminSession | null>(null);
  const [loading, setLoading] = useState(true);
  const refreshInFlight = useRef<Promise<AdminSession> | null>(null);

  useEffect(() => {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      setLoading(false);
      return;
    }
    try {
      const parsed = JSON.parse(raw) as AdminSession;
      setSession(parsed);
      void refreshSession(parsed.tokens.refreshToken).catch(() => {
        setSession(null);
        window.localStorage.removeItem(STORAGE_KEY);
        setLoading(false);
      });
    } catch {
      window.localStorage.removeItem(STORAGE_KEY);
      setLoading(false);
    }
  }, []);

  async function refreshSession(refreshToken: string) {
    if (!refreshToken) {
      throw new Error('Refresh token missing');
    }
    if (!refreshInFlight.current) {
      refreshInFlight.current = adminApiRequest<AdminSession>('/admin/auth/refresh', {
        method: 'POST',
        body: { refreshToken },
      }).then((nextSession) => {
        setSession(nextSession);
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(nextSession));
        return nextSession;
      }).finally(() => {
        refreshInFlight.current = null;
        setLoading(false);
      });
    }
    return refreshInFlight.current;
  }

  async function login(email: string, password: string) {
    const nextSession = await adminApiRequest<AdminSession>('/admin/auth/login', {
      method: 'POST',
      body: { email, password },
    });
    setSession(nextSession);
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(nextSession));
    setLoading(false);
  }

  async function logout() {
    const refreshToken = session?.tokens.refreshToken;
    if (refreshToken) {
      try {
        await adminApiRequest('/admin/auth/logout', {
          method: 'POST',
          body: { refreshToken },
        });
      } catch {
        // logout is best-effort
      }
    }
    setSession(null);
    window.localStorage.removeItem(STORAGE_KEY);
    setLoading(false);
  }

  async function request<T>(
    path: string,
    options: {
      method?: 'GET' | 'POST' | 'PATCH';
      body?: unknown;
    } = {},
  ) {
    const currentSession = session;
    if (!currentSession) {
      throw new Error('Oturum bulunamadı');
    }
    try {
      return await adminApiRequest<T>(path, {
        method: options.method,
        body: options.body,
        accessToken: currentSession.tokens.accessToken,
      });
    } catch (error) {
      if (error instanceof AdminApiError && error.status === 401) {
        const nextSession = await refreshSession(currentSession.tokens.refreshToken);
        return adminApiRequest<T>(path, {
          method: options.method,
          body: options.body,
          accessToken: nextSession.tokens.accessToken,
        });
      }
      throw error;
    }
  }

  return (
    <AdminAuthContext.Provider
      value={{
        session,
        loading,
        login,
        logout,
        request,
      }}
    >
      {children}
    </AdminAuthContext.Provider>
  );
}

export function useAdminAuth() {
  const context = useContext(AdminAuthContext);
  if (!context) {
    throw new Error('useAdminAuth must be used within AdminAuthProvider');
  }
  return context;
}
