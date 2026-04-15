/**
 * OAuth2 Token Proxy
 *
 * Proxies token exchange requests to the Quran.com OAuth2 endpoint.
 * Extracts client_id and client_secret from the form body, converts them
 * to a Basic Auth header, and forwards the cleaned request upstream.
 */

/**
 * Returns the OAuth2 token host.
 * Always targets the prelive endpoint — authentication and user-facing
 * OAuth2 flows use prelive regardless of QF_ENV (which controls content APIs).
 *
 * @returns {string} The base URL of the OAuth2 token server
 */
export function getTokenHost() {
  return "https://prelive-oauth2.quran.foundation";
}

/**
 * Handles POST /oauth2/token requests by proxying to the upstream OAuth2 endpoint.
 *
 * @param {object} event - API Gateway proxy event
 * @returns {Promise<{statusCode: number, body: object}>}
 */
export async function handleTokenProxy(event) {
  // Only POST is allowed
  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      body: { error: "Method Not Allowed" },
    };
  }

  // Validate body is present
  if (!event.body) {
    return {
      statusCode: 400,
      body: { error: "bad_request", message: "Missing request body" },
    };
  }

  // Parse form-urlencoded body
  const params = new URLSearchParams(event.body);

  const clientId = params.get("client_id");
  if (!clientId) {
    return {
      statusCode: 400,
      body: { error: "bad_request", message: "Missing client_id" },
    };
  }

  const clientSecret = params.get("client_secret");
  if (!clientSecret) {
    return {
      statusCode: 400,
      body: { error: "bad_request", message: "Missing client_secret" },
    };
  }

  // Build Basic Auth header from extracted credentials
  const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  // Remove credentials from forwarded body
  params.delete("client_id");
  params.delete("client_secret");

  const tokenHost = getTokenHost();
  const upstreamUrl = `${tokenHost}/oauth2/token`;

  try {
    const res = await fetch(upstreamUrl, {
      method: "POST",
      headers: {
        Authorization: `Basic ${basicAuth}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    });

    const responseBody = await res.json();

    return {
      statusCode: res.status,
      body: responseBody,
    };
  } catch (error) {
    // Log error details but never log credentials
    console.error("Token proxy error:", {
      message: error.message,
      url: upstreamUrl,
    });

    return {
      statusCode: 502,
      body: { error: "proxy_error", message: error.message },
    };
  }
}
