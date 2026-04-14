import { randomUUID } from "node:crypto";
import { putItem, queryItems, updateItem } from "./db.mjs";
import { invokeAgent } from "./agent.mjs";

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
 * Removes keywords whose arabic field matches an entry in the known set.
 * Preserves original ordering.
 *
 * @param {Array<{arabic: string, translation: string, hint: string, type: string}>} keywords - LLM keywords
 * @param {Set<string>} knownArabicSet - Set of known Arabic strings
 * @returns {Array<{arabic: string, translation: string, hint: string, type: string}>} Filtered keywords
 */
export function filterKnownKeywords(keywords, knownArabicSet) {
  return keywords.filter(k => !knownArabicSet.has(k.arabic));
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

  const prompt = `You are a Quran study assistant helping a reader prepare for recitation.

PASSAGE CONTENT (${passageLabel}):
${passageContent}

READER FAMILIARITY: ${familiarity}
- "new" means the reader has never recited this passage before. Focus on foundational vocabulary and core themes.
- "somewhat_familiar" means the reader has some exposure. Highlight nuances and connections between verses.
- "well_known" means the reader knows this passage well. Focus on deeper linguistic insights and advanced vocabulary.

TASK:
1. Provide exactly 3 bullet points summarizing the key themes of this passage. Each bullet should be one concise sentence.
2. Provide exactly 20 keywords from the passage, ordered from most important to least important. Each keyword should include the Arabic word, its English translation, a short contextual hint, and a type ("focus" for essential vocabulary, "advanced" for deeper study).

Return ONLY valid JSON with this exact shape, no extra text:
{
  "overview": ["bullet 1", "bullet 2", "bullet 3"],
  "keywords": [
    { "arabic": "string", "translation": "string", "hint": "string", "type": "focus | advanced" }
  ]
}`;

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

  return {
    statusCode: 200,
    body: {
      sessionId,
      overview: parsed.overview ?? [],
      keywords: filterKnownKeywords(parsed.keywords ?? [], knownArabicSet).slice(0, 20),
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
 */
export async function createSession(body, userId) {
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
