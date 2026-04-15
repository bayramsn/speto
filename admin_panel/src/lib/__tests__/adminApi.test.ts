import { beforeEach, describe, expect, it, vi } from 'vitest';

import { adminApiRequest } from '../adminApi';

describe('adminApiRequest', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.stubGlobal('fetch', vi.fn());
  });

  it('sends credentials and preserves query filters for CSV/blob downloads', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock.mockResolvedValueOnce(
      new Response('id,name\n1,Ali\n', {
        status: 200,
        headers: { 'Content-Type': 'text/csv' },
      }),
    );

    const blob = await adminApiRequest<Blob>('/admin/export/users', {
      accessToken: 'access-token',
      query: {
        q: 'ali',
        role: 'CUSTOMER',
        empty: '',
        page: null,
      },
      responseType: 'blob',
    });

    expect(await blob.text()).toContain('Ali');
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining('/admin/export/users?q=ali&role=CUSTOMER'),
      expect.objectContaining({
        credentials: 'include',
        headers: expect.objectContaining({
          Authorization: 'Bearer access-token',
        }),
      }),
    );
  });
});
