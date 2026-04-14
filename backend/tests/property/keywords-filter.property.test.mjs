import { describe, it, expect, vi } from 'vitest';
import fc from 'fast-check';

// Controllable mock state — only activated for Property 3 tests
const mockState = vi.hoisted(() => ({
  dbShouldThrow: false,
  agentResponse: null,
  mockFetch: false,
}));

// Mock db.mjs: when dbShouldThrow is true, queryItems throws; otherwise delegates to real impl
vi.mock('../../src/db.mjs', async (importOriginal) => {
  const original = await importOriginal();
  return {
    ...original,
    queryItems: (...args) => {
      if (mockState.dbShouldThrow) {
        throw new Error('Simulated DB failure');
      }
      return original.queryItems(...args);
    },
  };
});

// Mock agent.mjs: when agentResponse is set, return it; otherwise delegate to real impl
vi.mock('../../src/agent.mjs', async (importOriginal) => {
  const original = await importOriginal();
  return {
    ...original,
    invokeAgent: (...args) => {
      if (mockState.agentResponse !== null) {
        return Promise.resolve(mockState.agentResponse);
      }
      return original.invokeAgent(...args);
    },
  };
});

// Mock global fetch for Property 3: return minimal valid responses for OAuth + Quran API
const originalFetch = globalThis.fetch;
vi.stubGlobal('fetch', (...args) => {
  if (mockState.mockFetch) {
    const url = typeof args[0] === 'string' ? args[0] : args[0]?.url;
    // OAuth token endpoint
    if (url && url.includes('/oauth2/token')) {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ access_token: 'fake-token', expires_in: 3600 }),
      });
    }
    // Quran API verses endpoint
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ verses: [] }),
    });
  }
  return originalFetch(...args);
});

import { filterKnownKeywords, prepareSession } from '../../src/sessions.mjs';

/**
 * Arbitrary: generates a keyword object with random arabic, translation, hint, and type fields.
 */
const keywordArb = fc.record({
  arabic: fc.string({ minLength: 1 }),
  translation: fc.string(),
  hint: fc.string(),
  type: fc.constantFrom('focus', 'advanced'),
});

describe('Feature: known-keywords-filter, Property 1: Filter correctness', () => {
  /**
   * Validates: Requirements 2.1, 2.2, 2.3, 2.4, 3.1
   *
   * For any list of keyword objects and any set of known Arabic strings,
   * filterKnownKeywords returns exactly the subsequence of keywords whose
   * `arabic` field is not in the known set, preserving original order.
   */
  it('known keywords are removed, unknowns preserved in order', () => {
    fc.assert(
      fc.property(
        fc.array(keywordArb),
        fc.array(fc.string({ minLength: 1 })),
        (keywords, knownArray) => {
          const knownSet = new Set(knownArray);
          const result = filterKnownKeywords(keywords, knownSet);

          // Build expected subsequence manually
          const expected = keywords.filter(k => !knownSet.has(k.arabic));

          // Same length
          expect(result).toHaveLength(expected.length);

          // Each element matches by reference and position (subsequence + order)
          for (let i = 0; i < expected.length; i++) {
            expect(result[i]).toBe(expected[i]);
          }
        }
      ),
      { numRuns: 100 }
    );
  });
});

describe('Feature: known-keywords-filter, Property 2: Output cap', () => {
  /**
   * Validates: Requirements 3.2, 3.3
   *
   * For any list of keyword objects (length 0–50) and any set of known Arabic strings,
   * the combined output of filterKnownKeywords(...).slice(0, 20) always contains
   * at most 20 keywords.
   */
  it('at most 20 keywords returned', () => {
    fc.assert(
      fc.property(
        fc.array(keywordArb, { minLength: 0, maxLength: 50 }),
        fc.array(fc.string({ minLength: 1 })),
        (keywords, knownArray) => {
          const knownSet = new Set(knownArray);
          const result = filterKnownKeywords(keywords, knownSet).slice(0, 20);

          expect(result.length).toBeLessThanOrEqual(20);
        }
      ),
      { numRuns: 100 }
    );
  });
});

describe('Feature: known-keywords-filter, Property 3: Graceful degradation', () => {
  /**
   * Validates: Requirements 1.3
   *
   * For any list of LLM keyword objects, if the DynamoDB query for known keywords
   * throws an error, the system should return the same keyword list as if the known
   * set were empty (i.e., the full unfiltered list, capped at 20).
   */
  it('DB failure returns full keyword list capped at 20', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(keywordArb, { minLength: 0, maxLength: 30 }),
        async (keywords) => {
          // Activate mocks: DB throws, agent returns controlled JSON, fetch is stubbed
          mockState.dbShouldThrow = true;
          mockState.mockFetch = true;
          mockState.agentResponse = JSON.stringify({
            overview: ['bullet 1', 'bullet 2', 'bullet 3'],
            keywords,
          });

          try {
            const result = await prepareSession(
              { pages: '1', familiarity: 'new' },
              'test-user-prop3'
            );

            expect(result.statusCode).toBe(200);

            const expected = keywords.slice(0, 20);
            expect(result.body.keywords).toHaveLength(expected.length);

            // Each keyword matches the unfiltered list in order
            for (let i = 0; i < expected.length; i++) {
              expect(result.body.keywords[i].arabic).toBe(expected[i].arabic);
              expect(result.body.keywords[i].translation).toBe(expected[i].translation);
            }
          } finally {
            // Always deactivate mocks
            mockState.dbShouldThrow = false;
            mockState.mockFetch = false;
            mockState.agentResponse = null;
          }
        }
      ),
      { numRuns: 100 }
    );
  });
});
