import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { AdminAuthProvider } from '../AdminAuthContext';
import { useAdminAuth } from '../adminAuth';
import type { AdminSession } from '../../lib/types';

const futureDate = new Date(Date.now() + 60_000).toISOString();

function buildSession(accessToken: string): AdminSession {
  return {
    user: {
      id: 'admin-1',
      email: 'admin@speto.app',
      displayName: 'Speto Admin',
      role: 'SUPER_ADMIN',
      avatarUrl: '',
      createdAt: '2026-04-15T00:00:00.000Z',
      lastLoginAt: null,
    },
    tokens: {
      accessToken,
      accessTokenExpiresAt: futureDate,
    },
  };
}

function jsonResponse(status: number, body: unknown) {
  return Promise.resolve(
    new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    }),
  );
}

function SessionProbe() {
  const { loading, session } = useAdminAuth();
  if (loading) {
    return <p>loading</p>;
  }
  return <p>{session?.user.email ?? 'no-session'}</p>;
}

function RequestProbe() {
  const { loading, request } = useAdminAuth();
  const [result, setResult] = useState('');

  if (loading) {
    return <p>loading</p>;
  }

  return (
    <>
      <button
        onClick={async () => {
          const response = await request<{ ok: boolean }>('/admin/probe');
          setResult(response.ok ? 'request-ok' : 'request-failed');
        }}
        type="button"
      >
        Run request
      </button>
      <p>{result}</p>
    </>
  );
}

describe('AdminAuthProvider', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.stubGlobal('fetch', vi.fn());
  });

  it('bootstraps the session through the HttpOnly refresh cookie flow', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock.mockResolvedValueOnce(await jsonResponse(200, buildSession('access-token')));

    render(
      <AdminAuthProvider>
        <SessionProbe />
      </AdminAuthProvider>,
    );

    expect(await screen.findByText('admin@speto.app')).toBeInTheDocument();
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining('/admin/auth/refresh'),
      expect.objectContaining({
        credentials: 'include',
        method: 'POST',
      }),
    );
  });

  it('retries protected requests once after a 401 by rotating the refresh cookie', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock
      .mockResolvedValueOnce(await jsonResponse(200, buildSession('old-access-token')))
      .mockResolvedValueOnce(await jsonResponse(401, { message: 'expired' }))
      .mockResolvedValueOnce(await jsonResponse(200, buildSession('new-access-token')))
      .mockResolvedValueOnce(await jsonResponse(200, { ok: true }));

    render(
      <AdminAuthProvider>
        <RequestProbe />
      </AdminAuthProvider>,
    );

    await userEvent.click(await screen.findByRole('button', { name: 'Run request' }));

    expect(await screen.findByText('request-ok')).toBeInTheDocument();
    expect(fetchMock).toHaveBeenLastCalledWith(
      expect.stringContaining('/admin/probe'),
      expect.objectContaining({
        credentials: 'include',
        headers: expect.objectContaining({
          Authorization: 'Bearer new-access-token',
        }),
      }),
    );
  });
});
