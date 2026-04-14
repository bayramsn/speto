import type { AdminSession } from './types';

const env = import.meta.env as Record<string, string | undefined>;

export const ADMIN_API_BASE_URL = (
  env.VITE_ADMIN_API_BASE_URL ||
  env.ADMIN_API_BASE_URL ||
  'http://127.0.0.1:4100/api'
).replace(/\/$/, '');

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
    method?: 'GET' | 'POST' | 'PATCH';
    body?: unknown;
    accessToken?: string;
  } = {},
): Promise<T> {
  const response = await fetch(`${ADMIN_API_BASE_URL}${path}`, {
    method: options.method ?? 'GET',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(options.accessToken
        ? {
            Authorization: `Bearer ${options.accessToken}`,
          }
        : {}),
    },
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
  return (await response.json()) as T;
}

export function isSessionExpired(session: AdminSession | null) {
  if (!session) {
    return true;
  }
  return new Date(session.tokens.accessTokenExpiresAt).getTime() <= Date.now();
}
