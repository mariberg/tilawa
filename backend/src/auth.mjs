/**
 * Decodes a JWT payload without verifying the signature.
 * We rely on API Gateway / upstream OAuth2 for token validation —
 * this just extracts claims for routing purposes.
 *
 * @param {string} token - Raw JWT string
 * @returns {object} Decoded payload
 */
function decodeJwtPayload(token) {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid JWT format");
  }
  const payload = Buffer.from(parts[1], "base64url").toString("utf-8");
  return JSON.parse(payload);
}

/**
 * Extracts a stable userId from the Bearer JWT in the Authorization header.
 * Returns the `sub` claim as the userId for DynamoDB partition keys.
 * Also returns the raw token for downstream API calls (e.g. session sync).
 *
 * @param {object} event - API Gateway proxy event
 * @returns {{ userId: string, accessToken: string }} The stable userId and raw token
 * @throws {Error} If Authorization header is missing, malformed, or token has no sub claim
 */
export function extractUserId(event) {
  const headers = event.headers || {};

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

  const token = authHeader.slice(7);
  const payload = decodeJwtPayload(token);

  if (!payload.sub) {
    throw new Error("JWT missing sub claim");
  }

  return { userId: payload.sub, accessToken: token };
}
