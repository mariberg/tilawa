import { describe, it, expect } from 'vitest';
import { routeRequest } from '../../src/router.mjs';

describe('routeRequest', () => {
  it('GET /health returns 200 with OK message', async () => {
    const event = { httpMethod: 'GET', path: '/health' };
    const result = await routeRequest(event, 'test-user');

    expect(result.statusCode).toBe(200);
    expect(result.body).toEqual({ message: 'OK' });
  });

  it('unknown route returns 404', async () => {
    const event = { httpMethod: 'GET', path: '/unknown' };
    const result = await routeRequest(event, 'test-user');

    expect(result.statusCode).toBe(404);
    expect(result.body).toEqual({ error: 'Not Found', message: 'Route not found' });
  });
});
