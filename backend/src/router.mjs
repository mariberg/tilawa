import {
  prepareSession,
  createSession,
  updateSessionFeeling,
  getRecentSessions,
} from "./sessions.mjs";

/**
 * Routes incoming API Gateway requests by HTTP method and path.
 *
 * @param {object} event - API Gateway proxy event
 * @param {string} userId - Authenticated user ID
 * @param {string|null} userAccessToken - Raw Bearer token from the caller (passed to createSession for sync)
 * @returns {Promise<{statusCode: number, body: object|string}>} Route response
 */
export async function routeRequest(event, userId, userAccessToken) {
  try {
    const method = (event.httpMethod || "").toUpperCase();
    const path = event.path || "";

    if (method === "GET" && path === "/health") {
      return { statusCode: 200, body: { message: "OK" } };
    }

    // POST /sessions/prepare
    if (method === "POST" && path === "/sessions/prepare") {
      return prepareSession(JSON.parse(event.body || "{}"), userId);
    }

    // GET /sessions/recent
    if (method === "GET" && path === "/sessions/recent") {
      return getRecentSessions(userId);
    }

    // POST /sessions
    if (method === "POST" && path === "/sessions") {
      return createSession(JSON.parse(event.body || "{}"), userId, userAccessToken);
    }

    // PATCH /sessions/:sessionId/feeling
    const feelingMatch = path.match(/^\/sessions\/([^/]+)\/feeling$/);
    if (method === "PATCH" && feelingMatch) {
      return updateSessionFeeling(feelingMatch[1], JSON.parse(event.body || "{}"), userId);
    }

    return {
      statusCode: 404,
      body: { error: "Not Found", message: "Route not found" },
    };
  } catch {
    return {
      statusCode: 500,
      body: { error: "Internal Server Error", message: "An unexpected error occurred" },
    };
  }
}
