import { randomUUID } from "node:crypto";
import { putItem, queryItems, updateItem } from "./db.mjs";
import { invokeAgent } from "./agent.mjs";

/**
 * POST /sessions/prepare
 * Generates preparation content (overview + keywords) for a recitation session.
 */
export async function prepareSession(body, userId) {
  const { pages, surah, familiarity } = body;

  if (!pages || !surah || !familiarity) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "pages, surah, and familiarity are required" },
    };
  }

  const sessionId = randomUUID();

  const prompt = [
    `You are a Quran preparation assistant. Your role is to help a user mentally
prepare before reciting a portion of the Quran — not to teach, not to lecture,
but to give a brief, focused mental overview so they can recite with awareness.

The user will provide:

1. A portion of the Quran (page range ${pages} or Surah name ${surah})
2. A familiarity level ${familiarity}: "new", "somewhat_familiar", or "well_known"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Always produce a concise, high-level summary.
Focus only on the most important recurring themes.
Do NOT try to cover everything.

Always produce exactly 3 bullet points. No more, no fewer.
Each bullet point is one concise sentence.
Order them by importance — most central theme first.
Return them as a JSON array of 3 strings, not as prose.

The tone should be calm, reverent, and neutral — not academic, not preachy.

Adjust depth based on familiarity level:

- "new": Write as if the user has never encountered this passage before.
Use simple language. Focus on the single most dominant theme only.
Avoid any Arabic terminology without explanation.
Example tone: "This passage describes the story of a prophet who faced
rejection from his people, and how he remained patient in the face of that."
- "somewhat_familiar": Assume the user has read this before but needs a
reminder. You can reference 2 themes. Slightly more precise language.
One Arabic term is acceptable if immediately explained.
Example tone: "This passage returns to the theme of tawakkul — trusting
in Allah — as the Prophet navigates opposition and doubt from those around him."
- "well_known": Assume the user knows this passage well and just needs a
sharp, precise mental anchor before reciting. Be concise and precise.
Arabic terminology is welcome. Reference up to 3 themes or structural
elements of the passage.
Example tone: "This passage moves between the theme of divine mercy (rahmah)
and the consequences of ingratitude (kufr al-ni'mah), closing with a reminder
of Allah's complete awareness of what is concealed."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KEYWORD RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Produce exactly 20 keywords. No more, no fewer.
Order them from most important to least important within the passage.
Each keyword must appear or be directly relevant to the specific passage provided.
Do not include generic Islamic terms that could apply to any passage.

Each keyword must include:

- arabic: the Arabic word with full diacritics (tashkeel)
- translation: a short English translation (3–5 words max)
- hint: one sentence explaining how this word is used in THIS passage specifically
- type: either "focus" or "advanced" (see below)

Adjust type assignment based on familiarity level:

- "new":
Assign "focus" to the 10 most common, accessible words.
Assign "advanced" to the remaining 10.
Prioritize words the user will encounter frequently in the passage.
- "somewhat_familiar":
Assign "focus" to the 12 most thematically significant words.
Assign "advanced" to the remaining 8.
Prioritize words that carry theological or narrative weight.
- "well_known":
Assign "focus" to the 15 most nuanced or theologically rich words.
Assign "advanced" to the remaining 5 — these should be rare or
particularly deep words that even experienced readers may overlook.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OUTPUT FORMAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Respond only in valid JSON. No preamble, no explanation, no markdown.

{
"overview": [
"string (one concise sentence)",
"string (one concise sentence)",
"string (one concise sentence)"

"keywords": [
{
"arabic": "string (with full diacritics)",
"translation": "string (3–5 words)",
"hint": "string (one sentence, passage-specific)",
"type": "focus | advanced"
}
// exactly 20 items, ordered most to least important
]
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHAT TO AVOID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Do not reproduce any Quranic ayat or Arabic text from the Quran itself
- Do not give tafsir-level detail — this is preparation, not study
- Do not moralize or give advice to the user
- Do not include generic words like "Allah", "Islam", "Muslim" as keywords
unless they appear in a specific and meaningful way in this passage
- Do not vary the JSON structure based on familiarity level —
the structure is always identical, only the content depth changes`,
  ].join("\n");

  const raw = await invokeAgent(prompt, userId);

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    parsed = { overview: raw, keywords: [] };
  }

  return {
    statusCode: 200,
    body: {
      sessionId,
      overview: parsed.overview ?? "",
      keywords: parsed.keywords ?? [],
    },
  };
}


/**
 * POST /sessions
 * Creates a completed session record.
 */
export async function createSession(body, userId) {
  const { pages, surah, durationSecs } = body;

  if (!pages || !surah || durationSecs == null) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "pages, surah, and durationSecs are required" },
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
    createdAt,
  });

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

  // Find the session by querying user's sessions and matching sessionId
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
 * Returns the last 2 sessions for the user.
 */
export async function getRecentSessions(userId) {
  const sessions = await queryItems(`USER#${userId}`, "SESSION#");

  // Sort descending by createdAt (SK contains the timestamp) and take last 2
  const recent = sessions
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .slice(0, 2)
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
