import { describe, it, expect, vi } from 'vitest';
import fc from 'fast-check';

// In-memory store to mock the DB layer
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
}));

import { saveSettings, getSettings } from '../../src/settings.mjs';

describe('Feature: arabic-level-settings, Property 1: Settings round-trip', () => {
  /**
   * Validates: Requirements 1.1, 1.4, 1.5, 2.1
   *
   * For any valid arabicLevel value and any user ID, saving the setting
   * via saveSettings and then retrieving it via getSettings should return
   * the most recently saved arabicLevel value.
   */
  it('save then get returns the saved value', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('beginner', 'intermediate', 'advanced'),
        fc.string({ minLength: 1 }),
        async (level, userId) => {
          store.clear();

          const saveResult = await saveSettings({ arabicLevel: level }, userId);
          expect(saveResult.statusCode).toBe(200);
          expect(saveResult.body.arabicLevel).toBe(level);

          const getResult = await getSettings(userId);
          expect(getResult.statusCode).toBe(200);
          expect(getResult.body.arabicLevel).toBe(level);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Validates: Requirements 1.1, 1.4, 1.5, 2.1
   *
   * If two different valid values are saved in sequence, getSettings
   * should return only the second (overwrite) value.
   */
  it('saving two values returns only the second (overwrite)', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('beginner', 'intermediate', 'advanced'),
        fc.constantFrom('beginner', 'intermediate', 'advanced'),
        fc.string({ minLength: 1 }),
        async (first, second, userId) => {
          store.clear();

          await saveSettings({ arabicLevel: first }, userId);
          await saveSettings({ arabicLevel: second }, userId);

          const getResult = await getSettings(userId);
          expect(getResult.statusCode).toBe(200);
          expect(getResult.body.arabicLevel).toBe(second);
        }
      ),
      { numRuns: 100 }
    );
  });
});


describe('Feature: arabic-level-settings, Property 2: Invalid arabicLevel values are rejected', () => {
  const VALID_LEVELS = ['beginner', 'intermediate', 'advanced'];

  /**
   * Validates: Requirements 1.2, 1.3
   *
   * For any string that is not one of "beginner", "intermediate", or "advanced",
   * calling saveSettings should return statusCode 400 and should not modify the
   * user's stored settings.
   */
  it('arbitrary invalid strings are rejected with 400 and no state change', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.string().filter(s => !VALID_LEVELS.includes(s)),
        fc.string({ minLength: 1 }),
        async (invalidLevel, userId) => {
          store.clear();

          const saveResult = await saveSettings({ arabicLevel: invalidLevel }, userId);
          expect(saveResult.statusCode).toBe(400);
          expect(saveResult.body).toHaveProperty('error');
          expect(saveResult.body).toHaveProperty('message');

          const getResult = await getSettings(userId);
          expect(getResult.statusCode).toBe(200);
          expect(getResult.body.arabicLevel).toBeNull();
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Validates: Requirements 1.2, 1.3
   *
   * null, undefined, empty string, and missing body should all be rejected
   * with 400 and no state change.
   */
  it('null, undefined, empty string, and missing body are rejected with 400', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom(
          { arabicLevel: null },
          { arabicLevel: undefined },
          { arabicLevel: '' },
          {},
          null,
          undefined
        ),
        fc.string({ minLength: 1 }),
        async (body, userId) => {
          store.clear();

          const saveResult = await saveSettings(body, userId);
          expect(saveResult.statusCode).toBe(400);
          expect(saveResult.body).toHaveProperty('error');
          expect(saveResult.body).toHaveProperty('message');

          const getResult = await getSettings(userId);
          expect(getResult.statusCode).toBe(200);
          expect(getResult.body.arabicLevel).toBeNull();
        }
      ),
      { numRuns: 100 }
    );
  });
});


// Mock sessions.mjs to prevent real session imports when router is loaded
vi.mock('../../src/sessions.mjs', () => ({
  prepareSession: async () => ({ statusCode: 200, body: {} }),
  createSession: async () => ({ statusCode: 200, body: {} }),
  updateSessionFeeling: async () => ({ statusCode: 200, body: {} }),
  getRecentSessions: async () => ({ statusCode: 200, body: {} }),
}));

import { routeRequest } from '../../src/router.mjs';

describe('Feature: arabic-level-settings, Property 4: Router dispatches settings requests correctly', () => {
  const VALID_LEVELS = ['beginner', 'intermediate', 'advanced'];

  /**
   * Validates: Requirements 4.1, 4.2
   *
   * For any PUT request to /settings with a valid arabicLevel and userId,
   * the router should produce a response identical to calling saveSettings directly.
   */
  it('PUT /settings via router matches direct saveSettings call', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom(...VALID_LEVELS),
        fc.string({ minLength: 1 }),
        async (level, userId) => {
          store.clear();

          const event = {
            httpMethod: 'PUT',
            path: '/settings',
            body: JSON.stringify({ arabicLevel: level }),
          };

          const routerResult = await routeRequest(event, userId, null);

          // Reset store and call handler directly for comparison
          store.clear();
          const directResult = await saveSettings({ arabicLevel: level }, userId);

          expect(routerResult.statusCode).toBe(directResult.statusCode);
          expect(routerResult.body).toEqual(directResult.body);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Validates: Requirements 4.1, 4.2
   *
   * For any GET request to /settings, the router should produce a response
   * identical to calling getSettings directly.
   */
  it('GET /settings via router matches direct getSettings call', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.string({ minLength: 1 }),
        fc.boolean(),
        async (userId, shouldPreSave) => {
          store.clear();

          // Optionally save a setting first so GET has something to return
          if (shouldPreSave) {
            const level = VALID_LEVELS[Math.floor(Math.random() * VALID_LEVELS.length)];
            await saveSettings({ arabicLevel: level }, userId);
          }

          const event = {
            httpMethod: 'GET',
            path: '/settings',
          };

          const routerResult = await routeRequest(event, userId, null);
          const directResult = await getSettings(userId);

          expect(routerResult.statusCode).toBe(directResult.statusCode);
          expect(routerResult.body).toEqual(directResult.body);
        }
      ),
      { numRuns: 100 }
    );
  });
});
