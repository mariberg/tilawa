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

  /** Validates: Requirement 2.2 — lemma matches known set, arabic does not */
  it('excludes keyword when lemma matches known set but arabic does not', () => {
    const keywords = [
      { arabic: 'كَفَرُوا', lemma: 'كفر', translation: 'they disbelieved', hint: 'root verb', type: 'focus' },
      { arabic: 'نور', translation: 'light', hint: 'noun', type: 'focus' },
    ];
    const knownSet = new Set(['كفر']);

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toHaveLength(1);
    expect(result[0].arabic).toBe('نور');
  });

  /** Validates: Requirement 2.3 — falls back to arabic when lemma is undefined */
  it('uses arabic for comparison when lemma is undefined', () => {
    const keywords = [
      { arabic: 'بسم', lemma: undefined, translation: 'In the name', hint: 'opening', type: 'focus' },
    ];
    const knownSet = new Set(['بسم']);

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toEqual([]);
  });

  /** Validates: Requirement 2.3 — falls back to arabic when lemma is null */
  it('uses arabic for comparison when lemma is null', () => {
    const keywords = [
      { arabic: 'الله', lemma: null, translation: 'God', hint: 'divine name', type: 'focus' },
    ];
    const knownSet = new Set(['الله']);

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toEqual([]);
  });

  /** Validates: Requirement 2.3 — falls back to arabic when lemma is empty string */
  it('uses arabic for comparison when lemma is empty string', () => {
    const keywords = [
      { arabic: 'الرحمن', lemma: '', translation: 'The Most Gracious', hint: 'attribute', type: 'advanced' },
    ];
    const knownSet = new Set(['الرحمن']);

    const result = filterKnownKeywords(keywords, knownSet);

    expect(result).toEqual([]);
  });

  /** Validates: Requirement 2.3 — falls back to arabic when lemma property is absent */
  it('uses arabic for comparison when lemma property is missing', () => {
    const keywords = [
      { arabic: 'نور', translation: 'light', hint: 'noun', type: 'focus' },
    ];
    const knownSet = new Set(['نور']);

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
  getItemFn: vi.fn(),
  agentResponse: null,
}));

vi.mock('../../src/db.mjs', () => ({
  queryItems: (...args) => mockState.queryItemsFn(...args),
  putItem: (...args) => mockState.putItemFn(...args),
  getItem: (...args) => mockState.getItemFn(...args),
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
    mockState.getItemFn.mockReset();
    mockState.agentResponse = JSON.stringify({
      overview: ['theme 1', 'theme 2', 'theme 3'],
      keywords: [
        { arabic: 'كلمة', translation: 'word', hint: 'vocab', type: 'focus' },
      ],
    });
    // Default: return empty known keywords
    mockState.queryItemsFn.mockResolvedValue([]);
    // Default: return beginner level (no exclusions)
    mockState.getItemFn.mockResolvedValue({ arabicLevel: 'beginner' });
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

describe('prepareSession — Filter 1 lemma-based exclusion', () => {
  beforeEach(() => {
    mockState.queryItemsFn.mockReset();
    mockState.putItemFn.mockReset();
    mockState.getItemFn.mockReset();
    // No known keywords in DB
    mockState.queryItemsFn.mockResolvedValue([]);
  });

  /** Validates: Requirement 2.1 — Filter 1 excludes keyword when lemma matches exclusion set */
  it('excludes keyword whose lemma matches exclusion set but arabic does not', async () => {
    // 'صبر' is in common_Quranic_words.json → included in advanced exclusion set
    // 'صَابِرِينَ' normalizes to 'صابرين' which is NOT in any exclusion list
    mockState.getItemFn.mockResolvedValue({ arabicLevel: 'advanced' });
    mockState.agentResponse = JSON.stringify({
      overview: ['theme 1', 'theme 2', 'theme 3'],
      keywords: [
        { arabic: 'صَابِرِينَ', lemma: 'صبر', translation: 'the patient ones', hint: 'virtue', type: 'focus' },
        { arabic: 'تَبَارَكَ', translation: 'blessed', hint: 'praise', type: 'focus' },
      ],
    });

    const result = await prepareSession({ pages: '1', familiarity: 'new' }, 'user-test');

    expect(result.statusCode).toBe(200);
    // 'صَابِرِينَ' should be excluded because its lemma 'صبر' is in the exclusion set
    const arabicValues = result.body.keywords.map(k => k.arabic);
    expect(arabicValues).not.toContain('صَابِرِينَ');
    // 'تَبَارَكَ' has no lemma and doesn't match exclusion set → should remain
    expect(arabicValues).toContain('تَبَارَكَ');
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
