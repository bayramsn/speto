import type { AdminSession } from './types';

const env = import.meta.env as Record<string, string | undefined>;
export type AdminHttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE';
export type AdminQueryValue = string | number | boolean | null | undefined;
export type AdminQuery = Record<string, AdminQueryValue>;

function resolveAdminApiBaseUrl() {
  const configured = env.VITE_ADMIN_API_BASE_URL || env.ADMIN_API_BASE_URL;
  if (configured) {
    return configured.replace(/\/$/, '');
  }
  if (import.meta.env.DEV) {
    return 'http://127.0.0.1:4100/api';
  }
  return '';
}

export const ADMIN_API_BASE_URL = resolveAdminApiBaseUrl();

export class AdminApiError extends Error {
  readonly status: number;

  constructor(
    message: string,
    status: number,
  ) {
    super(message);
    this.status = status;
  }
}

export async function adminApiRequest<T>(
  path: string,
  options: {
    method?: AdminHttpMethod;
    body?: unknown;
    query?: AdminQuery;
    accessToken?: string;
    responseType?: 'json' | 'text' | 'blob';
  } = {},
): Promise<T> {
  if (!ADMIN_API_BASE_URL) {
    throw new AdminApiError(
      'Admin API adresi production build icin tanimli degil. VITE_ADMIN_API_BASE_URL ayarlanmali.',
      0,
    );
  }

  const url = new URL(`${ADMIN_API_BASE_URL}${path}`);
  for (const [key, value] of Object.entries(options.query ?? {})) {
    if (value !== undefined && value !== null && value !== '') {
      url.searchParams.set(key, String(value));
    }
  }

  const response = await fetch(url.toString(), {
    method: options.method ?? 'GET',
    headers: {
      Accept: 'application/json',
      ...(options.body === undefined ? {} : { 'Content-Type': 'application/json' }),
      ...(options.accessToken
        ? {
            Authorization: `Bearer ${options.accessToken}`,
          }
        : {}),
    },
    credentials: 'include',
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });

  if (!response.ok) {
    let message = 'İstek başarısız oldu.';
    try {
      const payload = (await response.json()) as { message?: string | string[] };
      if (Array.isArray(payload.message)) {
        message = payload.message.join(', ');
      } else if (payload.message) {
        message = payload.message;
      }
    } catch {
      message = response.statusText || message;
    }
    throw new AdminApiError(message, response.status);
  }

  if (response.status === 204) {
    return undefined as T;
  }
  if (options.responseType === 'blob') {
    return (await response.blob()) as T;
  }
  if (options.responseType === 'text') {
    return (await response.text()) as T;
  }
  return (await response.json()) as T;
}

export function isSessionExpired(session: AdminSession | null) {
  if (!session) {
    return true;
  }
  return new Date(session.tokens.accessTokenExpiresAt).getTime() <= Date.now();
}
