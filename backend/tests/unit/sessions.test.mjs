import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock db.mjs
vi.mock('../../src/db.mjs', () => ({
  getItem: async () => null,
  putItem: async () => {},
  queryItems: async () => [],
  updateItem: async () => {},
}));

// Mock agent.mjs
vi.mock('../../src/agent.mjs', () => ({
  invokeAgent: async () => '{"overview":[],"keywords":[]}',
}));

// Track fetch calls for assertions
let fetchCalls;

beforeEach(() => {
  fetchCalls = [];
  process.env.QF_ENV = 'prelive';
  process.env.QF_CLIENT_ID = 'test-client-id';
  process.env.QF_CLIENT_SECRET = 'test-client-secret';
  process.env.QF_PRELIVE_CLIENT_ID = 'test-prelive-id';
  process.env.QF_PRELIVE_CLIENT_SECRET = 'test-prelive-secret';
});

/**
 * Builds a mock verse API response for a given surah with `count` verses.
 */
function buildVerseApiResponse(surah, count) {
  return {
    verses: Array.from({ length: count }, (_, i) => ({
      verse_key: `${surah}:${i + 1}`,
      text_uthmani: `Arabic text ${i + 1}`,
      translations: [{ text: `Translation ${i + 1}` }],
    })),
  };
}

/**
 * Builds a mock verse-by-page API response for a given page number.
 */
function buildPageVerseApiResponse(pageNumber) {
  const chapter = Math.floor(pageNumber / 20) + 1;
  return {
    verses: Array.from({ length: 10 }, (_, i) => ({
      verse_key: `${chapter}:${pageNumber + i}`,
      text_uthmani: `Arabic page ${pageNumber} verse ${i + 1}`,
      translations: [{ text: `Translation page ${pageNumber} verse ${i + 1}` }],
    })),
  };
}

/**
 * Sets up global.fetch mock that handles OAuth, verses/by_chapter, and sync endpoints.
 */
function setupSurahFetchMock(surah, verseCount) {
  global.fetch = vi.fn(async (url, opts) => {
    const urlStr = typeof url === 'string' ? url : url.toString();
    fetchCalls.push({ url: urlStr, opts });

    if (urlStr.includes('oauth2/token')) {
      return { ok: true, json: async () => ({ access_token: 'test-token', expires_in: 3600 }) };
    }
    if (urlStr.includes('verses/by_chapter')) {
      return { ok: true, json: async () => buildVerseApiResponse(surah, verseCount) };
    }
    if (urlStr.includes('reading-sessions')) {
      return { ok: true, json: async () => ({}) };
    }
    if (urlStr.includes('activity-days')) {
      return { ok: true, json: async () => ({}) };
    }
    return { ok: true, json: async () => ({}) };
  });
}

/**
 * Sets up global.fetch mock for page-based sessions.
 */
function setupPageFetchMock() {
  global.fetch = vi.fn(async (url, opts) => {
    const urlStr = typeof url === 'string' ? url : url.toString();
    fetchCalls.push({ url: urlStr, opts });

    if (urlStr.includes('oauth2/token')) {
      return { ok: true, json: async () => ({ access_token: 'test-token', expires_in: 3600 }) };
    }
    const pageMatch = urlStr.match(/verses\/by_page\/(\d+)/);
    if (pageMatch) {
      const pg = parseInt(pageMatch[1], 10);
      return { ok: true, json: async () => buildPageVerseApiResponse(pg) };
    }
    if (urlStr.includes('reading-sessions')) {
      return { ok: true, json: async () => ({}) };
    }
    if (urlStr.includes('activity-days')) {
      return { ok: true, json: async () => ({}) };
    }
    return { ok: true, json: async () => ({}) };
  });
}

// ─── Task 4.1: Surah branch unit tests ───────────────────────────────────────

describe('createSession — surah branch resolves correct verse range', () => {
  it('surah 108 (Al-Kawthar, 3 verses): endVerseKey="108:3", verseNumber=3', async () => {
    const { createSession } = await import('../../src/sessions.mjs');
    setupSurahFetchMock(108, 3);

    const result = await createSession(
      { surah: 108, durationSecs: 60, keywords: [] },
      'test-user',
      'test-user-token'
    );

    expect(result.statusCode).toBe(201);

    const rsCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
    expect(rsCall).toBeDefined();
    const rsBody = JSON.parse(rsCall.opts.body);
    expect(rsBody.chapterNumber).toBe(108);
    expect(rsBody.verseNumber).toBe(3);

    const adCall = fetchCalls.find(c => c.url.includes('activity-days'));
    expect(adCall).toBeDefined();
    const adBody = JSON.parse(adCall.opts.body);
    expect(adBody.ranges).toEqual(['108:1-108:3']);
  });

  it('surah 2 (Al-Baqarah, 286 verses): endVerseKey="2:286", verseNumber=286', async () => {
    const { createSession } = await import('../../src/sessions.mjs');
    setupSurahFetchMock(2, 286);

    const result = await createSession(
      { surah: 2, durationSecs: 120, keywords: [] },
      'test-user',
      'test-user-token'
    );

    expect(result.statusCode).toBe(201);

    const rsCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
    const rsBody = JSON.parse(rsCall.opts.body);
    expect(rsBody.chapterNumber).toBe(2);
    expect(rsBody.verseNumber).toBe(286);

    const adCall = fetchCalls.find(c => c.url.includes('activity-days'));
    const adBody = JSON.parse(adCall.opts.body);
    expect(adBody.ranges).toEqual(['2:1-2:286']);
  });

  it('surah 69 (Al-Haqqah, 52 verses): endVerseKey="69:52", verseNumber=52', async () => {
    const { createSession } = await import('../../src/sessions.mjs');
    setupSurahFetchMock(69, 52);

    const result = await createSession(
      { surah: 69, durationSecs: 90, keywords: [] },
      'test-user',
      'test-user-token'
    );

    expect(result.statusCode).toBe(201);

    const rsCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
    const rsBody = JSON.parse(rsCall.opts.body);
    expect(rsBody.chapterNumber).toBe(69);
    expect(rsBody.verseNumber).toBe(52);

    const adCall = fetchCalls.find(c => c.url.includes('activity-days'));
    const adBody = JSON.parse(adCall.opts.body);
    expect(adBody.ranges).toEqual(['69:1-69:52']);
  });
});

// ─── Task 4.2: Error case — empty verses array skips syncs ───────────────────

describe('createSession — surah with empty verses skips syncs', () => {
  it('returns 201 but makes no sync calls when fetchVersesForChapter returns empty', async () => {
    const { createSession } = await import('../../src/sessions.mjs');

    global.fetch = vi.fn(async (url, opts) => {
      const urlStr = typeof url === 'string' ? url : url.toString();
      fetchCalls.push({ url: urlStr, opts });

      if (urlStr.includes('oauth2/token')) {
        return { ok: true, json: async () => ({ access_token: 'test-token', expires_in: 3600 }) };
      }
      // Return empty verses array for the chapter API
      if (urlStr.includes('verses/by_chapter')) {
        return { ok: true, json: async () => ({ verses: [] }) };
      }
      if (urlStr.includes('reading-sessions')) {
        return { ok: true, json: async () => ({}) };
      }
      if (urlStr.includes('activity-days')) {
        return { ok: true, json: async () => ({}) };
      }
      return { ok: true, json: async () => ({}) };
    });

    const result = await createSession(
      { surah: 999, durationSecs: 60, keywords: [] },
      'test-user',
      'test-user-token'
    );

    // createSession catches the error and returns 201 anyway
    expect(result.statusCode).toBe(201);

    // No sync calls should have been made
    const rsCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
    expect(rsCall).toBeUndefined();

    const adCall = fetchCalls.find(c => c.url.includes('activity-days'));
    expect(adCall).toBeUndefined();
  });
});

// ─── Task 4.3: Page-based path preservation ──────────────────────────────────

describe('createSession — page-based path still works correctly', () => {
  it('pages "50-54" resolves correct verse keys from page data', async () => {
    const { createSession } = await import('../../src/sessions.mjs');
    setupPageFetchMock();

    const result = await createSession(
      { pages: '50-54', durationSecs: 60, keywords: [] },
      'test-user',
      'test-user-token'
    );

    expect(result.statusCode).toBe(201);

    // Expected from our deterministic mock:
    // Page 50: chapter = floor(50/20)+1 = 3, verses 3:50..3:59
    // Page 54: chapter = floor(54/20)+1 = 3, verses 3:54..3:63
    const expectedStartVerseKey = '3:50';
    const expectedEndVerseKey = '3:63'; // last verse of page 54 = 54+9 = 63

    const rsCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
    expect(rsCall).toBeDefined();
    const rsBody = JSON.parse(rsCall.opts.body);
    expect(rsBody.chapterNumber).toBe(3);
    expect(rsBody.verseNumber).toBe(50);

    const adCall = fetchCalls.find(c => c.url.includes('activity-days'));
    expect(adCall).toBeDefined();
    const adBody = JSON.parse(adCall.opts.body);
    expect(adBody.ranges).toEqual([`${expectedStartVerseKey}-${expectedEndVerseKey}`]);
  });
});
