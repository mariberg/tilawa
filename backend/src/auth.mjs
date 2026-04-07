/**
 * Extracts userId from the Bearer token in the Authorization header.
 *
 * @param {object} event - API Gateway proxy event
 * @returns {string} The userId extracted from the Bearer token
 * @throws {Error} If Authorization header is missing or doesn't start with "Bearer "
 */
export function extractUserId(event) {
  const headers = event.headers || {};

  // Case-insensitive header lookup
  const authHeader =
    headers.Authorization ??
    headers.authorization ??
    Object.entries(headers).find(
      ([key]) => key.toLowerCase() === "authorization"
    )?.[1];

  if (!authHeader) {
    throw new Error("Missing Authorization header");
  }

  if (!authHeader.startsWith("Bearer ")) {
    throw new Error("Invalid Authorization header format");
  }

  return authHeader.slice(7);
}
