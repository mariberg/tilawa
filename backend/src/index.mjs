import { extractUserId } from "./auth.mjs";
import { routeRequest } from "./router.mjs";
import { handleTokenProxy } from "./tokenProxy.mjs";

const CORS_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-api-key",
};

/**
 * Lambda handler entry point.
 * Adds CORS headers to every response, extracts userId from Bearer token,
 * routes the request, and returns structured JSON responses.
 *
 * @param {object} event - API Gateway proxy event
 * @param {object} context - Lambda context
 * @returns {Promise<{statusCode: number, headers: object, body: string}>}
 */
export async function handler(event, context) {
  try {
    // Handle CORS preflight for any path
    if ((event.httpMethod || "").toUpperCase() === "OPTIONS") {
      return { statusCode: 200, headers: CORS_HEADERS, body: "" };
    }

    // Bypass auth for the OAuth2 token proxy route
    if (event.path === "/oauth2/token") {
      const result = await handleTokenProxy(event);
      return {
        statusCode: result.statusCode,
        headers: CORS_HEADERS,
        body: JSON.stringify(result.body),
      };
    }

    const { userId, accessToken } = extractUserId(event);

    const result = await routeRequest(event, userId, accessToken);

    return {
      statusCode: result.statusCode,
      headers: CORS_HEADERS,
      body: JSON.stringify(result.body),
    };
  } catch (error) {
    // Auth errors from extractUserId → 401
    if (
      error.message === "Missing Authorization header" ||
      error.message === "Invalid Authorization header format" ||
      error.message === "Invalid JWT format" ||
      error.message === "JWT missing sub claim"
    ) {
      return {
        statusCode: 401,
        headers: CORS_HEADERS,
        body: JSON.stringify({
          error: "Unauthorized",
          message: error.message,
        }),
      };
    }

    // All other errors → 500 with generic message (no internal details)
    console.error("Unhandled error:", error);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({
        error: "Internal Server Error",
        message: "An unexpected error occurred",
      }),
    };
  }
}
