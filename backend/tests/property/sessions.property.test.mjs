import { describe, it, expect, vi, beforeEach } from 'vitest';
import fc from 'fast-check';

// Mock db.mjs — createSession calls putItem, queryItems
vi.mock('../../src/db.mjs', () => ({
  getItem: async () => null,
  putItem: async () => {},
  queryItems: async () => [],
  updateItem: async () => {},
}));

// Mock agent.mjs — prepareSession calls invokeAgent
vi.mock('../../src/agent.mjs', () => ({
  invokeAgent: async () => '{"overview":[],"keywords":[]}',
}));

// Track fetch calls for assertions
let fetchCalls;

beforeEach(() => {
  fetchCalls = [];
  // Set required env vars
  process.env.QF_ENV = 'prelive';
  process.env.QF_CLIENT_ID = 'test-client-id';
  process.env.QF_CLIENT_SECRET = 'test-client-secret';
  process.env.QF_PRELIVE_CLIENT_ID = 'test-prelive-id';
  process.env.QF_PRELIVE_CLIENT_SECRET = 'test-prelive-secret';
});

/**
 * Builds a mock verse array for a given surah with `count` verses.
 * Each verse has the shape returned by fetchVerses after mapping.
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

describe('Property 1: Bug Condition — Surah-based sessions resolve correct last verse', () => {
  /**
   * Validates: Requirements 2.1, 2.2
   *
   * For any surah number (1–114) and any verse count (1–286),
   * creating a session with that surah should result in sync calls
   * where endVerseKey = "{surah}:{lastVerse}" and verseNumber = lastVerse.
   */
  it('createSession with a surah resolves endVerseKey and verseNumber to the last verse', async () => {
    // Dynamically import after mocks are set up
    const { createSession } = await import('../../src/sessions.mjs');

    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 114 }),
        fc.integer({ min: 1, max: 286 }),
        async (surah, verseCount) => {
          fetchCalls = [];

          // Mock global fetch to handle all HTTP calls
          global.fetch = vi.fn(async (url, opts) => {
            const urlStr = typeof url === 'string' ? url : url.toString();
            fetchCalls.push({ url: urlStr, opts });

            // OAuth token requests
            if (urlStr.includes('oauth2/token')) {
              return {
                ok: true,
                json: async () => ({ access_token: 'test-token', expires_in: 3600 }),
              };
            }

            // Verses by chapter API
            if (urlStr.includes('verses/by_chapter')) {
              return {
                ok: true,
                json: async () => buildVerseApiResponse(surah, verseCount),
              };
            }

            // Reading Sessions sync
            if (urlStr.includes('reading-sessions')) {
              return { ok: true, json: async () => ({}) };
            }

            // Activity Days sync
            if (urlStr.includes('activity-days')) {
              return { ok: true, json: async () => ({}) };
            }

            return { ok: true, json: async () => ({}) };
          });

          const result = await createSession(
            { surah, durationSecs: 60, keywords: [] },
            'test-user',
            'test-user-token'
          );

          expect(result.statusCode).toBe(201);

          // Find the reading-sessions sync call and verify verseNumber
          const readingSessionCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
          expect(readingSessionCall).toBeDefined();
          const rsBody = JSON.parse(readingSessionCall.opts.body);
          expect(rsBody.verseNumber).toBe(verseCount);
          expect(rsBody.chapterNumber).toBe(surah);

          // Find the activity-days sync call and verify verse range
          const activityDayCall = fetchCalls.find(c => c.url.includes('activity-days'));
          expect(activityDayCall).toBeDefined();
          const adBody = JSON.parse(activityDayCall.opts.body);
          expect(adBody.ranges).toEqual([`${surah}:1-${surah}:${verseCount}`]);
        }
      ),
      { numRuns: 100 }
    );
  });
});


/**
 * Builds a mock verse-by-page API response for a given page number.
 * Deterministic mapping: page N → chapter = floor(N/20)+1, 10 verses starting at verse N.
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

describe('Property 2: Preservation — Page-based sessions produce identical results', () => {
  /**
   * Validates: Requirements 3.1, 3.2, 3.3
   *
   * For any valid page range (single page or startPage-endPage within 1–604),
   * creating a session with that page range should result in sync calls where:
   * - startVerseKey matches the first verse of the first page
   * - endVerseKey matches the last verse of the last page
   * - chapterNumber and verseNumber are parsed from startVerseKey
   */
  it('createSession with pages resolves verse keys from fetched page data', async () => {
    const { createSession } = await import('../../src/sessions.mjs');

    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 604 }),
        fc.integer({ min: 0, max: 20 }),
        async (startPage, rangeSize) => {
          const endPage = Math.min(startPage + rangeSize, 604);
          const pages = startPage === endPage ? `${startPage}` : `${startPage}-${endPage}`;
          fetchCalls = [];

          // Mock global fetch for page-based resolution
          global.fetch = vi.fn(async (url, opts) => {
            const urlStr = typeof url === 'string' ? url : url.toString();
            fetchCalls.push({ url: urlStr, opts });

            // OAuth token requests
            if (urlStr.includes('oauth2/token')) {
              return {
                ok: true,
                json: async () => ({ access_token: 'test-token', expires_in: 3600 }),
              };
            }

            // Verses by page API — extract page number from URL
            const pageMatch = urlStr.match(/verses\/by_page\/(\d+)/);
            if (pageMatch) {
              const pg = parseInt(pageMatch[1], 10);
              return {
                ok: true,
                json: async () => buildPageVerseApiResponse(pg),
              };
            }

            // Reading Sessions sync
            if (urlStr.includes('reading-sessions')) {
              return { ok: true, json: async () => ({}) };
            }

            // Activity Days sync
            if (urlStr.includes('activity-days')) {
              return { ok: true, json: async () => ({}) };
            }

            return { ok: true, json: async () => ({}) };
          });

          const result = await createSession(
            { pages, durationSecs: 60, keywords: [] },
            'test-user',
            'test-user-token'
          );

          expect(result.statusCode).toBe(201);

          // Compute expected values from our deterministic mock
          const firstPageChapter = Math.floor(startPage / 20) + 1;
          const expectedStartVerseKey = `${firstPageChapter}:${startPage}`;

          const lastPageChapter = Math.floor(endPage / 20) + 1;
          // Last verse of a page = pageNumber + 9 (10 verses per page, last index)
          const expectedEndVerseKey = `${lastPageChapter}:${endPage + 9}`;

          const expectedChapterNumber = firstPageChapter;
          const expectedVerseNumber = startPage; // parsed from startVerseKey

          // Verify reading-sessions sync received correct chapterNumber and verseNumber
          const readingSessionCall = fetchCalls.find(c => c.url.includes('reading-sessions'));
          expect(readingSessionCall).toBeDefined();
          const rsBody = JSON.parse(readingSessionCall.opts.body);
          expect(rsBody.chapterNumber).toBe(expectedChapterNumber);
          expect(rsBody.verseNumber).toBe(expectedVerseNumber);

          // Verify activity-days sync received correct verse range
          const activityDayCall = fetchCalls.find(c => c.url.includes('activity-days'));
          expect(activityDayCall).toBeDefined();
          const adBody = JSON.parse(activityDayCall.opts.body);
          expect(adBody.ranges).toEqual([`${expectedStartVerseKey}-${expectedEndVerseKey}`]);
        }
      ),
      { numRuns: 100 }
    );
  });
});
