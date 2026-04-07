import { extractUserId } from "./auth.mjs";
import { routeRequest } from "./router.mjs";

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
    const userId = extractUserId(event);
    const result = await routeRequest(event, userId);

    return {
      statusCode: result.statusCode,
      headers: CORS_HEADERS,
      body: JSON.stringify(result.body),
    };
  } catch (error) {
    // Auth errors from extractUserId → 401
    if (
      error.message === "Missing Authorization header" ||
      error.message === "Invalid Authorization header format"
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
