export const VALID_USERS = ['demo-user-1', 'demo-user-2', 'demo-user-3'];

export function extractUserId(event) {
  const authHeader = event.headers?.Authorization
    || event.headers?.authorization;

  if (!authHeader) {
    return {
      statusCode: 401,
      body: JSON.stringify({ error: 'Authentication required' }),
    };
  }

  const token = authHeader.replace(/^Bearer\s+/i, '');

  if (!VALID_USERS.includes(token)) {
    return {
      statusCode: 403,
      body: JSON.stringify({ error: 'Invalid user' }),
    };
  }

  return { userId: token };
}
