/**
 * Routes incoming API Gateway requests by HTTP method and path.
 *
 * @param {object} event - API Gateway proxy event
 * @param {string} userId - Authenticated user ID
 * @returns {Promise<{statusCode: number, body: object|string}>} Route response
 */
export async function routeRequest(event, userId) {
  try {
    const method = (event.httpMethod || "").toUpperCase();
    const path = event.path || "";

    if (method === "GET" && path === "/health") {
      return {
        statusCode: 200,
        body: { message: "OK" },
      };
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
