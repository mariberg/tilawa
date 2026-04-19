import { randomUUID } from "node:crypto";
import { getItem, putItem, queryItems, updateItem } from "./db.mjs";
import { invokeAgent } from "./agent.mjs";
import highFrequencyWords from './high_frequency_words.json' with { type: 'json' };
import commonWords from './common_Quranic_words.json' with { type: 'json' };

const AUTH_BASE_BY_ENV = {
  prelive: "https://prelive-oauth2.quran.foundation",
  production: "https://oauth2.quran.foundation",
};

const API_BASE_BY_ENV = {
  prelive: "https://apis-prelive.quran.foundation",
  production: "https://apis.quran.foundation",
};

// Simple in-memory token cache (lives for the Lambda execution context)
let cachedToken = null;
let tokenExpiresAt = 0;

// Independent prelive token cache for Reading Sessions API
let cachedPreliveToken = null;
let preliveTokenExpiresAt = 0;

/**
 * Fetches an OAuth2 access token using client credentials flow.
 * Caches the token in memory until it expires.
 */
async function getAccessToken() {
  if (cachedToken && Date.now() < tokenExpiresAt) {
    return cachedToken;
  }

  const env = process.env.QF_ENV || "prelive";
  const authBase = AUTH_BASE_BY_ENV[env];
  const basicAuth = Buffer.from(
    `${process.env.QF_CLIENT_ID}:${process.env.QF_CLIENT_SECRET}`
  ).toString("base64");

  const res = await fetch(`${authBase}/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basicAuth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      scope: "content",
    }),
  });

  if (!res.ok) {
    const errBody = await res.text();
    console.error("Quran OAuth token error:", res.status, errBody);
    throw new Error(`Quran OAuth token request failed: ${res.status}`);
  }

  const data = await res.json();
  cachedToken = data.access_token;
  // Refresh 60s before actual expiry to avoid edge cases
  tokenExpiresAt = Date.now() + (data.expires_in - 60) * 1000;
  return cachedToken;
}

/**
 * Fetches an OAuth2 access token from the prelive auth server.
 * Always targets prelive regardless of QF_ENV.
 * Caches independently from the production token used by the content API.
 */
async function getPreliveAccessToken() {
  if (cachedPreliveToken && Date.now() < preliveTokenExpiresAt) {
    return cachedPreliveToken;
  }

  const basicAuth = Buffer.from(
    `${process.env.QF_PRELIVE_CLIENT_ID}:${process.env.QF_PRELIVE_CLIENT_SECRET}`
  ).toString("base64");

  const res = await fetch(
    "https://prelive-oauth2.quran.foundation/oauth2/token",
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${basicAuth}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "client_credentials",
        scope: "reading_session",
      }),
    }
  );

  if (!res.ok) {
    const errBody = await res.text();
    console.error("Prelive OAuth token error:", res.status, errBody);
    throw new Error(`Prelive OAuth token request failed: ${res.status}`);
  }

  const data = await res.json();
  cachedPreliveToken = data.access_token;
  // Refresh 60s before actual expiry to avoid edge cases
  preliveTokenExpiresAt = Date.now() + (data.expires_in - 60) * 1000;
  return cachedPreliveToken;
}

/**
 * Makes an authenticated GET request to the Quran API and returns parsed verses.
 */
async function fetchVerses(path) {
  const env = process.env.QF_ENV || "prelive";
  const apiBase = API_BASE_BY_ENV[env];
  const token = await getAccessToken();

  const url = `${apiBase}/content/api/v4/${path}?fields=text_uthmani&translations=131&per_page=50`;
  console.log("Quran API request:", url);
  const res = await fetch(url, {
    headers: {
      "x-auth-token": token,
      "x-client-id": process.env.QF_CLIENT_ID,
    },
  });
  if (!res.ok) {
    const body = await res.text();
    console.error("Quran API error:", res.status, body);
    throw new Error(`Quran API error: ${res.status}`);
  }
  const data = await res.json();
  return (data.verses || []).map((v) => ({
    verseKey: v.verse_key,
    arabic: v.text_uthmani || "",
    translation: v.translations?.[0]?.text?.replace(/<[^>]*>/g, "") || "",
  }));
}

/**
 * Fetches verses for a single Mushaf page number.
 */
async function fetchVersesForPage(pageNumber) {
  return fetchVerses(`verses/by_page/${pageNumber}`);
}

/**
 * Fetches verses for a chapter (surah) number.
 */
async function fetchVersesForChapter(chapterNumber) {
  return fetchVerses(`verses/by_chapter/${chapterNumber}`);
}

/**
 * Parses a page range string like "50-54" or "50–54" into an array of page numbers.
 */
function parsePageRange(pages) {
  const cleaned = pages.replace(/–/g, "-");
  const parts = cleaned.split("-").map((s) => parseInt(s.trim(), 10));
  if (parts.length === 1) return [parts[0]];
  const [start, end] = parts;
  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
}

/**
 * Resolves session parameters to chapter/verse numbers and verse key range.
 *
 * @param {string|number|undefined} surah - Surah number if provided
 * @param {string|undefined} pages - Page range string if provided (e.g. "50-54")
 * @returns {Promise<{chapterNumber: number, verseNumber: number, startVerseKey: string, endVerseKey: string}>}
 */
async function resolveChapterAndVerse(surah, pages) {
  console.log("resolveChapterAndVerse called with:", { surah, pages });
  if (surah != null) {
    const verses = await fetchVersesForChapter(Number(surah));
    if (!verses || verses.length === 0) {
      throw new Error(`No verses returned for chapter ${surah}`);
    }
    const lastVerse = verses[verses.length - 1];
    const lastVerseNumber = Number(lastVerse.verseKey.split(":")[1]);
    const startVerseKey = `${Number(surah)}:1`;
    const endVerseKey = lastVerse.verseKey;
    console.log("Using surah path:", { chapterNumber: Number(surah), verseNumber: lastVerseNumber, startVerseKey, endVerseKey });
    return { chapterNumber: Number(surah), verseNumber: lastVerseNumber, startVerseKey, endVerseKey };
  }

  const pageNumbers = parsePageRange(pages);
  const firstPage = pageNumbers[0];
  const lastPage = pageNumbers[pageNumbers.length - 1];
  console.log("Using pages path, fetching verses for first page:", firstPage, "last page:", lastPage);

  const firstPageVerses = await fetchVersesForPage(firstPage);
  if (!firstPageVerses || firstPageVerses.length === 0) {
    throw new Error(`No verses returned for page ${firstPage}`);
  }

  const startVerseKey = firstPageVerses[0].verseKey;
  if (!startVerseKey || !startVerseKey.includes(":")) {
    throw new Error(`Invalid verse_key format: ${startVerseKey}`);
  }

  // Fetch last page verses (may be the same page for single-page ranges)
  let endVerseKey;
  if (lastPage === firstPage) {
    endVerseKey = firstPageVerses[firstPageVerses.length - 1].verseKey;
  } else {
    const lastPageVerses = await fetchVersesForPage(lastPage);
    if (!lastPageVerses || lastPageVerses.length === 0) {
      throw new Error(`No verses returned for page ${lastPage}`);
    }
    endVerseKey = lastPageVerses[lastPageVerses.length - 1].verseKey;
  }

  if (!endVerseKey || !endVerseKey.includes(":")) {
    throw new Error(`Invalid verse_key format: ${endVerseKey}`);
  }

  const [chapter, verse] = startVerseKey.split(":").map(Number);
  if (Number.isNaN(chapter) || Number.isNaN(verse)) {
    throw new Error(`Failed to parse verse_key: ${startVerseKey}`);
  }

  return { chapterNumber: chapter, verseNumber: verse, startVerseKey, endVerseKey };
}

/**
 * Syncs a completed session to the Quran.com Reading Sessions API.
 * Fire-and-forget: logs errors but never throws.
 *
 * @param {number} chapterNumber - Quran chapter number (>= 1)
 * @param {number} verseNumber - Verse number within the chapter (>= 1)
 * @param {string} userAccessToken - The user's OAuth2 access token
 */
async function syncReadingSession(chapterNumber, verseNumber, userAccessToken) {
  if (!userAccessToken) {
    console.warn("syncReadingSession: missing user access token, skipping sync");
    return;
  }

  try {
    const requestBody = { chapterNumber, verseNumber };
    console.log("Syncing reading session:", requestBody);

    const res = await fetch(
      "https://apis-prelive.quran.foundation/auth/v1/reading-sessions",
      {
        method: "POST",
        headers: {
          "x-auth-token": userAccessToken,
          "x-client-id": process.env.QF_PRELIVE_CLIENT_ID,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      }
    );

    if (!res.ok) {
      const errBody = await res.text();
      console.error("Reading Sessions API error:", res.status, errBody);
    } else {
      console.log("Reading session synced:", { chapterNumber, verseNumber });
    }
  } catch (err) {
    console.error("Reading session sync error:", err);
  }
}

/**
 * Syncs a completed session to the Quran.com Activity Days API.
 * Fire-and-forget: logs errors but never throws.
 *
 * @param {string} startVerseKey - e.g. "2:1"
 * @param {string} endVerseKey - e.g. "2:5"
 * @param {number} durationSecs - Session duration in seconds (integer >= 1)
 * @param {string} userAccessToken - The user's OAuth2 access token
 */
async function syncActivityDay(startVerseKey, endVerseKey, durationSecs, userAccessToken) {
  try {
    if (!userAccessToken || userAccessToken === "") {
      console.warn("syncActivityDay: missing user access token, skipping sync");
      return;
    }

    if (!Number.isInteger(durationSecs) || durationSecs < 1) {
      console.warn("syncActivityDay: invalid durationSecs, skipping sync:", durationSecs);
      return;
    }

    const requestBody = {
      type: "QURAN",
      seconds: durationSecs,
      ranges: [`${startVerseKey}-${endVerseKey}`],
      mushafId: 4,
    };
    console.log("Syncing activity day:", requestBody);

    const res = await fetch(
      "https://apis-prelive.quran.foundation/auth/v1/activity-days",
      {
        method: "POST",
        headers: {
          "x-auth-token": userAccessToken,
          "x-client-id": process.env.QF_PRELIVE_CLIENT_ID,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      }
    );

    if (!res.ok) {
      const errBody = await res.text();
      console.error("Activity Days API error:", res.status, errBody);
    } else {
      console.log("Activity day synced:", { startVerseKey, endVerseKey, durationSecs });
    }
  } catch (err) {
    console.error("Activity day sync error:", err);
  }
}

/**
 * Strips Arabic diacritical marks (tashkīl) from a string for comparison.
 */
const stripDiacritics = (str) =>
  str.replace(/[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]/g, '');

/**
 * Strips the definite article (ال) from the start of an Arabic word.
 * Handles both regular (القمر) and sun-letter assimilated forms (الشمس).
 */
const stripDefiniteArticle = (str) => str.replace(/^ال/, '');

/**
 * Normalizes an Arabic word for comparison: strips diacritics, then returns
 * both the with-article and without-article forms so either can match.
 */
function normalizeArabic(str) {
  const bare = stripDiacritics(str);
  return [bare, stripDefiniteArticle(bare)];
}

/**
 * Builds a Set of normalized roots from a word list for fast lookup.
 * Each word is stored both with and without the definite article.
 */
function buildExclusionSet(words) {
  const set = new Set();
  for (const w of words) {
    for (const form of normalizeArabic(w)) {
      set.add(form);
    }
  }
  return set;
}

/**
 * Checks if a keyword's arabic field matches any entry in an exclusion set,
 * accounting for diacritics and definite article differences.
 */
function isExcluded(arabic, exclusionSet) {
  return normalizeArabic(arabic).some(form => exclusionSet.has(form));
}

/**
 * Removes keywords whose arabic field matches an entry in the known set.
 * Preserves original ordering. Comparison is diacritics-insensitive and
 * matches with or without the definite article (ال).
 *
 * @param {Array<{arabic: string, translation: string, hint: string, type: string}>} keywords - LLM keywords
 * @param {Set<string>} knownArabicSet - Set of known Arabic strings
 * @returns {Array<{arabic: string, translation: string, hint: string, type: string}>} Filtered keywords
 */
export function filterKnownKeywords(keywords, knownArabicSet) {
  const normalizedKnown = buildExclusionSet([...knownArabicSet]);
  return keywords.filter(k => !isExcluded(k.lemma || k.arabic, normalizedKnown));
}

/**
 * POST /sessions/prepare
 * Fetches Quran content, sends it to Bedrock (Nova Pro) with familiarity context,
 * and returns a 3-bullet overview + 20 ranked keywords.
 */
export async function prepareSession(body, userId) {
  const { pages, surah, familiarity } = body;

  if (!familiarity) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "familiarity is required" },
    };
  }

  // Fetch stored Arabic level from user settings
  let arabicLevel = null;
  try {
    const storedSettings = await getItem(`USER#${userId}`, "SETTINGS");
    if (storedSettings?.arabicLevel) {
      arabicLevel = storedSettings.arabicLevel;
    }
  } catch (err) {
    console.error("Failed to fetch stored settings:", err);
  }

  if (!arabicLevel) {
    return {
      statusCode: 400,
      body: {
        error: "Bad Request",
        message: "arabicLevel is required (set your Arabic level in settings)",
      },
    };
  }

  console.log("prepareSession settings:", { arabicLevel, familiarity, userId });

  if (!pages && !surah) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "Either pages or surah is required" },
    };
  }

  // Fetch user's known keywords for filtering (graceful degradation on failure)
  let knownArabicSet = new Set();
  try {
    const knownItems = await queryItems(`USER#${userId}`, "KEYWORD#");
    knownArabicSet = new Set(knownItems.map(item => item.arabic));
  } catch (err) {
    console.error("Failed to fetch known keywords, continuing with empty set:", err);
  }

  // Fetch Quran content based on what the frontend sent
  let allVerses = [];
  let passageLabel = "";

  if (pages) {
    const pageNumbers = parsePageRange(pages);
    for (const pg of pageNumbers) {
      const verses = await fetchVersesForPage(pg);
      allVerses.push(...verses);
    }
    passageLabel = `Pages ${pages}`;
  } else {
    // surah is a chapter number (1-114)
    allVerses = await fetchVersesForChapter(surah);
    passageLabel = `Surah ${surah}`;
  }

  console.log(`Fetched ${allVerses.length} verses for ${passageLabel}`);

  // Build passage content for the prompt
  const passageContent = allVerses
    .map((v) => `[${v.verseKey}] ${v.arabic}\nTranslation: ${v.translation}`)
    .join("\n\n");


  const excludedWords = arabicLevel === 'advanced'
    ? [...highFrequencyWords.words, ...commonWords.words]
    : arabicLevel === 'intermediate'
      ? highFrequencyWords.words
      : []  // 'beginner' gets no exclusions

  const prompt = `You are a Quran study assistant. Your sole source of information is the passage provided below — do not draw on outside knowledge, tafsir, or hadith.

---
PASSAGE (${passageLabel}):
${passageContent}
---

ARABIC LEVEL: "${arabicLevel}"
SURAH FAMILIARITY: "${familiarity}"

SUMMARY TASK:
Write exactly 3 bullet points summarizing the passage's key themes.
Calibrate tone and depth to SURAH FAMILIARITY:
- "new": plain language, literal meaning, no assumed structural knowledge
- "somewhat_familiar": identify thematic links between verses, note structure
- "well_known": linguistic and rhetorical depth, word-choice precision
Each bullet is one complete sentence derived strictly from the passage text.

KEYWORD TASK:
Extract exactly 30 keywords directly from the passage.

STEP 1 — KEYWORD SELECTION:
Calibrate the word list strictly to ARABIC LEVEL. A beginner needs the 
building blocks of the passage — include common and high-frequency Quranic 
vocabulary. An intermediate reader already knows everyday Quranic nouns, 
verbs, and prepositions — skip these unless they carry an unusual meaning 
here. An advanced reader knows the Quranic lexicon broadly — only surface 
words that are rare, morphologically complex, or semantically nuanced in 
this specific passage. When in doubt, ask: would a reader at this level 
already know this word from general Quran exposure? If yes, leave it out.

STEP 2 — RANK by semantic centrality: ask yourself "if the reader understood 
only the first 5 words on this list, how much of this passage's core message 
would they grasp?" That answer should be: most of it. Do NOT rank by position 
in the text.

STEP 3 — LABEL each keyword:
- "focus"    → essential for understanding this passage's core message
- "advanced" → morphologically complex, rare, or semantically nuanced

Apply this type ratio based on ARABIC LEVEL:
- "beginner":               18 focus, 2 advanced
- "intermediate": 12 focus, 8 advanced  
- "advanced":        5 focus,  15 advanced

STEP 4 — VOCALIZATION: Every "arabic" value MUST include full harakāt 
(tashkīl). If the source text is unvocalized, reconstruct the standard 
Quranic vocalization. A keyword without complete harakāt is invalid.

STEP 5 - For each word, also return its base form (lemma/root).

Return JSON like:
[
  { "word": "كفروا", "lemma": "كفر" },
  { "word": "قالوا", "lemma": "قال" }
]

Return ONLY valid JSON — no markdown, no commentary, no trailing text.

VALIDATION RULES:
- "overview" must contain exactly 3 strings
- "keywords" must contain exactly 20 objects
- Every "arabic" value must carry full harakāt
- "translation" must be a short phrase, not a sentence (save explanation for "hint")
- "hint" must explain why THIS word matters at THIS arabic level

{
  "overview": ["string", "string", "string"],
  "keywords": [
    {
      "arabic": "string",
      "transliteration": "string",
      "translation": "string",
      "hint": "string",
      "type": "focus | advanced",
      "lemma": "string"
    }
  ]
}`

  const raw = await invokeAgent(prompt, userId);

  let parsed;
  try {
    // Handle cases where the model wraps JSON in markdown code fences
    const jsonStr = raw.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
    parsed = JSON.parse(jsonStr);
  } catch {
    parsed = { overview: [raw], keywords: [] };
  }

  const sessionId = randomUUID();

  // Filter 1: remove level-based excluded words (high-frequency / common Quranic)
  const exclusionSet = buildExclusionSet(excludedWords);
  const afterExclusions = (parsed.keywords ?? []).filter(
    k => !isExcluded(k.lemma || k.arabic, exclusionSet)
  );

  // Filter 2: remove user's known keywords from DB
  const finalKeywords = filterKnownKeywords(afterExclusions, knownArabicSet).slice(0, 20);

  console.log("prepareSession result:", {
    arabicLevel,
    familiarity,
    keywordCount: finalKeywords.length,
    keywords: finalKeywords.map(k => ({ arabic: k.arabic, type: k.type })),
  });

  return {
    statusCode: 200,
    body: {
      sessionId,
      overview: parsed.overview ?? [],
      keywords: finalKeywords,
    },
  };
}

/**
 * POST /sessions
 * Creates a completed session record and upserts known keywords for the user.
 *
 * @param {object} body - Request body
 * @param {string} body.pages - Page range (e.g. "50-54")
 * @param {string|number} body.surah - Surah number
 * @param {number} body.durationSecs - Session duration in seconds
 * @param {Array<{arabic: string, translation: string, status: string}>} [body.keywords] - Keyword familiarity selections
 * @param {string} userId - Authenticated user ID
 * @param {string|null} userAccessToken - Raw Bearer token from the caller (passed to syncReadingSession)
 */
export async function createSession(body, userId, userAccessToken) {
  const { pages, surah, durationSecs, keywords } = body;

  if (!pages && !surah) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "Either pages or surah is required" },
    };
  }

  if (durationSecs == null) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "durationSecs is required" },
    };
  }

  if (!Array.isArray(keywords)) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "keywords array is required" },
    };
  }

  const sessionId = randomUUID();
  const createdAt = new Date().toISOString();

  await putItem({
    PK: `USER#${userId}`,
    SK: `SESSION#${createdAt}#${sessionId}`,
    sessionId,
    pages,
    surah,
    durationSecs,
    keywords: keywords || [],
    createdAt,
  });

  // Upsert a KEYWORD# item for each keyword marked "known"
  if (Array.isArray(keywords)) {
    const knownKeywords = keywords.filter((k) => k.status === "known" && k.arabic);
    await Promise.all(
      knownKeywords.map((k) =>
        putItem({
          PK: `USER#${userId}`,
          SK: `KEYWORD#${k.arabic}`,
          arabic: k.arabic,
          translation: k.translation || "",
          lastSeenAt: createdAt,
          sessionId,
        })
      )
    );
  }

  // Fire-and-forget syncs to Quran.com APIs
  try {
    const { chapterNumber, verseNumber, startVerseKey, endVerseKey } =
      await resolveChapterAndVerse(surah, pages);

    try {
      await syncReadingSession(chapterNumber, verseNumber, userAccessToken);
    } catch (err) {
      console.error("Reading session sync failed:", err);
    }

    try {
      await syncActivityDay(startVerseKey, endVerseKey, durationSecs, userAccessToken);
    } catch (err) {
      console.error("Activity day sync failed:", err);
    }
  } catch (err) {
    console.error("Verse resolution failed, skipping syncs:", err);
  }

  return {
    statusCode: 201,
    body: { sessionId, createdAt },
  };
}

/**
 * PATCH /sessions/:sessionId/feeling
 * Updates the feeling on an existing session.
 */
export async function updateSessionFeeling(sessionId, body, userId) {
  const { feeling } = body;
  const validFeelings = ["smooth", "struggled", "revisit"];

  if (!feeling || !validFeelings.includes(feeling)) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: `feeling must be one of: ${validFeelings.join(", ")}` },
    };
  }

  const sessions = await queryItems(`USER#${userId}`, "SESSION#");
  const session = sessions.find((s) => s.sessionId === sessionId);

  if (!session) {
    return {
      statusCode: 404,
      body: { error: "Not Found", message: "Session not found" },
    };
  }

  await updateItem(session.PK, session.SK, { feeling });

  return {
    statusCode: 200,
    body: { sessionId, feeling },
  };
}

/**
 * GET /sessions/recent
 * Returns all sessions for the user, sorted newest first.
 */
export async function getRecentSessions(userId) {
  const sessions = await queryItems(`USER#${userId}`, "SESSION#");

  const recent = sessions
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .map(({ sessionId, pages, surah, feeling, createdAt }) => ({
      sessionId,
      pages,
      surah,
      feeling: feeling ?? null,
      createdAt,
    }));

  return {
    statusCode: 200,
    body: recent,
  };
}
