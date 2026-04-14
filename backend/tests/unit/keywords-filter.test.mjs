import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// ── Pure function tests (no mocking needed) ─────────────────────────────

import { filterKnownKeywords } from '../../src/sessions.mjs';

describe('filterKnownKeywords', () => {
  /** Validates: Baseline — empty known set is a no-op */
  it('returns all keywords when known set is empty', () => {
    const keywords = [
      { arabic: 'بسم', translation: 'In the name', hint: 'opening', type: 'focus' },
      { arabic: 'الله', translation: 'God', hint: 'divine name', type: 'focus' },
      { arabic: 'الرحمن', translation: 'The Most Gracious', hint: 'attribute', type: 'advanced' },
    ];
    const knownSet = new Set();

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toEqual(keywords);
    expect(result).toHaveLength(3);
  });

  /** Validates: Requirement 2.4 — all keywords known → empty array */
  it('returns empty array when all keywords are known', () => {
    const keywords = [
      { arabic: 'بسم', translation: 'In the name', hint: 'opening', type: 'focus' },
      { arabic: 'الله', translation: 'God', hint: 'divine name', type: 'focus' },
    ];
    const knownSet = new Set(['بسم', 'الله']);

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toEqual([]);
  });

  /** Validates: Requirement 2.1 — partially overlapping known set */
  it('returns only unknown keywords in original order', () => {
    const keywords = [
      { arabic: 'بسم', translation: 'In the name', hint: 'opening', type: 'focus' },
      { arabic: 'الله', translation: 'God', hint: 'divine name', type: 'focus' },
      { arabic: 'الرحمن', translation: 'The Most Gracious', hint: 'attribute', type: 'advanced' },
      { arabic: 'الرحيم', translation: 'The Most Merciful', hint: 'attribute', type: 'advanced' },
    ];
    const knownSet = new Set(['الله', 'الرحيم']);

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toHaveLength(2);
    expect(result[0].arabic).toBe('بسم');
    expect(result[1].arabic).toBe('الرحمن');
  });
});


// ── Integration tests (mocked DynamoDB, agent, fetch) ───────────────────

// Hoisted mock state — same conditional pattern as property tests
const mockState = vi.hoisted(() => ({
  queryItemsFn: vi.fn(),
  putItemFn: vi.fn(),
  agentResponse: null,
}));

vi.mock('../../src/db.mjs', () => ({
  queryItems: (...args) => mockState.queryItemsFn(...args),
  putItem: (...args) => mockState.putItemFn(...args),
  updateItem: vi.fn(),
}));

vi.mock('../../src/agent.mjs', () => ({
  invokeAgent: (...args) => {
    if (mockState.agentResponse !== null) {
      return Promise.resolve(mockState.agentResponse);
    }
    return Promise.resolve('{}');
  },
}));

// Stub global fetch for OAuth + Quran API calls
vi.stubGlobal('fetch', vi.fn((...args) => {
  const url = typeof args[0] === 'string' ? args[0] : args[0]?.url;
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
}));

// Dynamic import so mocks are in place before module loads
const { prepareSession, createSession } = await import('../../src/sessions.mjs');

describe('prepareSession — DynamoDB query', () => {
  beforeEach(() => {
    mockState.queryItemsFn.mockReset();
    mockState.putItemFn.mockReset();
    mockState.agentResponse = JSON.stringify({
      overview: ['theme 1', 'theme 2', 'theme 3'],
      keywords: [
        { arabic: 'كلمة', translation: 'word', hint: 'vocab', type: 'focus' },
      ],
    });
    // Default: return empty known keywords
    mockState.queryItemsFn.mockResolvedValue([]);
  });

  /** Validates: Requirements 1.1, 1.2 */
  it('queries DynamoDB with correct PK (USER#{userId}) and SK prefix (KEYWORD#)', async () => {
    const userId = 'user-abc-123';
    await prepareSession({ pages: '1', familiarity: 'new' }, userId);

    expect(mockState.queryItemsFn).toHaveBeenCalledWith(
      `USER#${userId}`,
      'KEYWORD#'
    );
  });
});

describe('createSession — keyword storage', () => {
  beforeEach(() => {
    mockState.queryItemsFn.mockReset();
    mockState.putItemFn.mockReset();
    mockState.putItemFn.mockResolvedValue(undefined);
  });

  /** Validates: Requirements 4.1, 4.2 */
  it('writes KEYWORD#{arabic} items for keywords marked as known', async () => {
    const userId = 'user-xyz-789';
    const body = {
      pages: '10-12',
      durationSecs: 300,
      keywords: [
        { arabic: 'بسم', translation: 'In the name', status: 'known' },
        { arabic: 'الله', translation: 'God', status: 'learning' },
        { arabic: 'الرحمن', translation: 'The Most Gracious', status: 'known' },
      ],
    };

    await createSession(body, userId);

    // Session item + 2 known keyword items = 3 putItem calls
    expect(mockState.putItemFn).toHaveBeenCalledTimes(3);

    // Verify the KEYWORD# items for known keywords
    const keywordCalls = mockState.putItemFn.mock.calls.filter(
      ([item]) => item.SK && item.SK.startsWith('KEYWORD#')
    );
    expect(keywordCalls).toHaveLength(2);

    const keywordSKs = keywordCalls.map(([item]) => item.SK).sort();
    expect(keywordSKs).toEqual(['KEYWORD#الرحمن', 'KEYWORD#بسم']);

    // Verify PK is correct on keyword items
    for (const [item] of keywordCalls) {
      expect(item.PK).toBe(`USER#${userId}`);
      expect(item.arabic).toBeDefined();
      expect(item.translation).toBeDefined();
    }
  });
});
