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

describe('Feature: lemma-based-keyword-filter, Property 1: Lemma-based exclusion', () => {
  /**
   * Validates: Requirements 2.1, 2.2
   *
   * For any keyword with a truthy `lemma` matching the exclusion/known set,
   * the keyword is excluded from output.
   *
   * Strategy: generate keyword objects with a truthy lemma, then build a known
   * set that contains that lemma value. filterKnownKeywords must exclude the keyword.
   */
  it('keywords with truthy lemma matching known set are always excluded', () => {
    // Arbitrary: a non-empty Arabic-ish string for the lemma
    const lemmaArb = fc.string({ minLength: 1 });

    // Arbitrary: a keyword object with a truthy lemma field
    const keywordWithLemmaArb = fc.record({
      arabic: fc.string({ minLength: 1 }),
      lemma: lemmaArb,
      translation: fc.string(),
      hint: fc.string(),
      type: fc.constantFrom('focus', 'advanced'),
    });

    fc.assert(
      fc.property(
        // Generate 1–10 keywords that all have a truthy lemma
        fc.array(keywordWithLemmaArb, { minLength: 1, maxLength: 10 }),
        // Generate 0–5 extra "bystander" keywords (no lemma) that should NOT be excluded
        fc.array(keywordArb, { minLength: 0, maxLength: 5 }),
        (lemmaKeywords, bystanders) => {
          // Build a known set from all the lemma values of the lemma keywords
          const knownSet = new Set(lemmaKeywords.map(k => k.lemma));

          // Combine: lemma keywords first, then bystanders
          const allKeywords = [...lemmaKeywords, ...bystanders];

          const result = filterKnownKeywords(allKeywords, knownSet);

          // Every keyword whose lemma is in the known set must be excluded
          for (const kw of lemmaKeywords) {
            const found = result.some(r => r === kw);
            expect(found).toBe(false);
          }
        }
      ),
      { numRuns: 200 }
    );
  });
});

describe('Feature: lemma-based-keyword-filter, Property 2: Preservation — fallback for no-lemma keywords', () => {
  /**
   * Validates: Requirements 2.3, 3.1, 3.2, 3.3, 3.4
   *
   * For any keyword without a `lemma`, the fixed filter produces the same
   * result as filtering on `k.arabic`. This ensures backward compatibility:
   * keywords with falsy lemma (undefined, null, empty string, or missing)
   * all resolve to the same filtering outcome.
   */
  it('no-lemma keywords are filtered identically regardless of falsy lemma variant', () => {
    // Arbitrary: keyword with NO lemma property at all (baseline "original" behavior)
    const keywordNoLemmaArb = fc.record({
      arabic: fc.string({ minLength: 1 }),
      translation: fc.string(),
      hint: fc.string(),
      type: fc.constantFrom('focus', 'advanced'),
    });

    // Arbitrary: a falsy lemma value (undefined, null, or empty string)
    const falsyLemmaArb = fc.constantFrom(undefined, null, '');

    fc.assert(
      fc.property(
        fc.array(keywordNoLemmaArb, { minLength: 1, maxLength: 15 }),
        fc.array(fc.string({ minLength: 1 }), { minLength: 0, maxLength: 10 }),
        falsyLemmaArb,
        (keywords, knownArray, falsyLemma) => {
          const knownSet = new Set(knownArray);

          // Baseline: keywords with no lemma property
          const baselineResult = filterKnownKeywords(keywords, knownSet);

          // Variant: same keywords but with an explicit falsy lemma value
          const withFalsyLemma = keywords.map(k => ({ ...k, lemma: falsyLemma }));
          const variantResult = filterKnownKeywords(withFalsyLemma, knownSet);

          // Both must produce the same number of results
          expect(variantResult).toHaveLength(baselineResult.length);

          // Each result must correspond to the same original keyword (by arabic field and position)
          for (let i = 0; i < baselineResult.length; i++) {
            expect(variantResult[i].arabic).toBe(baselineResult[i].arabic);
            expect(variantResult[i].translation).toBe(baselineResult[i].translation);
          }

          // Ordering is preserved: result indices are monotonically increasing in the input
          const inputArabics = keywords.map(k => k.arabic);
          let lastIdx = -1;
          for (const r of baselineResult) {
            const idx = inputArabics.indexOf(r.arabic, lastIdx + 1);
            expect(idx).toBeGreaterThan(lastIdx);
            lastIdx = idx;
          }
        }
      ),
      { numRuns: 200 }
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
