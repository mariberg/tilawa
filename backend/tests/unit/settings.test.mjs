import { describe, it, expect, vi, beforeEach } from 'vitest';

// In-memory store to mock the DB layer (same pattern as property tests)
const store = vi.hoisted(() => new Map());

vi.mock('../../src/db.mjs', () => ({
  getItem: async (pk, sk) => {
    const key = `${pk}#${sk}`;
    return store.get(key) ?? null;
  },
  putItem: async (item) => {
    const key = `${item.PK}#${item.SK}`;
    store.set(key, { ...item });
  },
  queryItems: async (pk, skPrefix) => {
    const results = [];
    for (const [key, value] of store.entries()) {
      if (key.startsWith(`${pk}#`) && (!skPrefix || key.split('#').slice(1).join('#').startsWith(skPrefix))) {
        results.push(value);
      }
    }
    return results;
  },
  updateItem: async () => ({}),
}));

// Mock agent.mjs to avoid real Bedrock calls
vi.mock('../../src/agent.mjs', () => ({
  invokeAgent: async () => '{"overview":[],"keywords":[]}',
}));

// Partial mock: keep real prepareSession, stub the rest to avoid external deps in router
vi.mock(import('../../src/sessions.mjs'), async (importOriginal) => {
  const actual = await importOriginal();
  return {
    ...actual,
    createSession: async () => ({ statusCode: 200, body: {} }),
    updateSessionFeeling: async () => ({ statusCode: 200, body: {} }),
    getRecentSessions: async () => ({ statusCode: 200, body: {} }),
  };
});

import { saveSettings, getSettings } from '../../src/settings.mjs';
import { routeRequest } from '../../src/router.mjs';
import { prepareSession } from '../../src/sessions.mjs';

beforeEach(() => {
  store.clear();
});

/**
 * Validates: Requirement 2.2
 */
describe('getSettings', () => {
  it('returns { arabicLevel: null } for a user with no settings record', async () => {
    const result = await getSettings('user-no-settings');

    expect(result.statusCode).toBe(200);
    expect(result.body).toEqual({ arabicLevel: null });
  });
});

/**
 * Validates: Requirements 1.2, 1.3
 */
describe('saveSettings – invalid values', () => {
  it('returns 400 when arabicLevel is undefined', async () => {
    const result = await saveSettings({}, 'user-1');

    expect(result.statusCode).toBe(400);
    expect(result.body).toHaveProperty('error');
    expect(result.body).toHaveProperty('message');
  });

  it('returns 400 when arabicLevel is an empty string', async () => {
    const result = await saveSettings({ arabicLevel: '' }, 'user-1');

    expect(result.statusCode).toBe(400);
    expect(result.body).toHaveProperty('error');
    expect(result.body).toHaveProperty('message');
  });

  it('returns 400 when arabicLevel is an invalid string', async () => {
    const result = await saveSettings({ arabicLevel: 'invalid_string' }, 'user-1');

    expect(result.statusCode).toBe(400);
    expect(result.body).toHaveProperty('error');
    expect(result.body.message).toContain('arabicLevel must be one of');
  });
});

/**
 * Validates: Requirement 3.3
 */
describe('prepareSession – missing familiarity', () => {
  it('returns 400 when no stored setting and no familiarity in body', async () => {
    const result = await prepareSession({ pages: '1' }, 'user-no-settings');

    expect(result.statusCode).toBe(400);
    expect(result.body).toHaveProperty('error');
    expect(result.body.message).toContain('familiarity');
  });
});

/**
 * Validates: Regression – router 404 for unrelated routes
 */
describe('routeRequest – 404 for unrelated routes', () => {
  it('returns 404 for an unknown path', async () => {
    const event = { httpMethod: 'GET', path: '/nonexistent' };
    const result = await routeRequest(event, 'user-1', null);

    expect(result.statusCode).toBe(404);
    expect(result.body).toEqual({ error: 'Not Found', message: 'Route not found' });
  });
});
