import { describe, it, expect, vi } from 'vitest';
import fc from 'fast-check';

// Controllable state for the router mock
const mockState = vi.hoisted(() => ({
  shouldThrow: false,
  error: null,
}));

// Conditionally mock routeRequest — when shouldThrow is true, throw the error;
// otherwise delegate to the real implementation.
vi.mock('../../src/router.mjs', async (importOriginal) => {
  const original = await importOriginal();
  return {
    ...original,
    routeRequest: (...args) => {
      if (mockState.shouldThrow) {
        throw mockState.error;
      }
      return original.routeRequest(...args);
    },
  };
});

import { routeRequest } from '../../src/router.mjs';
import { handler } from '../../src/index.mjs';

describe('Feature: serverless-mvp-backend', () => {
  describe('Property 3: Router always returns a structured response', () => {
    /**
     * Validates: Requirements 4.4
     *
     * For any valid HTTP method and any path string, calling routeRequest
     * should return an object with a numeric statusCode and a string or object body.
     */
    it('routeRequest returns { statusCode: number, body: string|object } for any method and path', async () => {
      const httpMethods = fc.constantFrom('GET', 'POST', 'PUT', 'DELETE', 'PATCH');

      await fc.assert(
        fc.asyncProperty(httpMethods, fc.string(), async (method, path) => {
          const event = { httpMethod: method, path };
          const result = await routeRequest(event, 'test-user');

          expect(result).toBeDefined();
          expect(typeof result.statusCode).toBe('number');
          expect(
            typeof result.body === 'string' || typeof result.body === 'object'
          ).toBe(true);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe('Property 4: All Lambda responses have valid structure with CORS headers', () => {
    /**
     * Validates: Requirements 4.5, 7.1
     *
     * For any request processed by the Lambda handler, the response must contain
     * a numeric statusCode, a headers object with CORS headers, and a JSON-parseable body string.
     */
    it('handler returns valid structure with CORS headers for any event', async () => {
      const validAuthEvent = fc.record({
        httpMethod: fc.constantFrom('GET', 'POST', 'PUT', 'DELETE', 'PATCH'),
        path: fc.string(),
        headers: fc.record({
          Authorization: fc.string({ minLength: 1 }).map((s) => `Bearer ${s}`),
        }),
      });

      const missingAuthEvent = fc.record({
        httpMethod: fc.constantFrom('GET', 'POST', 'PUT', 'DELETE', 'PATCH'),
        path: fc.string(),
        headers: fc.constant({}),
      });

      const invalidAuthEvent = fc.record({
        httpMethod: fc.constantFrom('GET', 'POST', 'PUT', 'DELETE', 'PATCH'),
        path: fc.string(),
        headers: fc.record({
          Authorization: fc.string().filter((s) => !s.startsWith('Bearer ')),
        }),
      });

      const anyEvent = fc.oneof(validAuthEvent, missingAuthEvent, invalidAuthEvent);

      await fc.assert(
        fc.asyncProperty(anyEvent, async (event) => {
          const response = await handler(event, {});

          expect(typeof response.statusCode).toBe('number');
          expect(response.headers).toBeDefined();
          expect(typeof response.headers).toBe('object');
          expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();
          expect(response.headers['Access-Control-Allow-Methods']).toBeDefined();
          expect(response.headers['Access-Control-Allow-Headers']).toBeDefined();
          expect(typeof response.body).toBe('string');
          expect(() => JSON.parse(response.body)).not.toThrow();
        }),
        { numRuns: 100 }
      );
    });
  });

  describe('Property 5: Internal errors produce safe 500 responses', () => {
    /**
     * Validates: Requirements 6.4
     *
     * For any error thrown during request processing, the Lambda handler should
     * return a 500 status code with a response body that does not contain
     * stack traces, internal error messages, or AWS resource identifiers.
     */
    it('handler returns safe 500 response for any thrown error', async () => {
      const forbiddenPatterns = ['stack', 'Stack', 'arn:', 'Error:'];

      // Auth error messages to avoid — these trigger 401, not 500
      const authMessages = [
        'Missing Authorization header',
        'Invalid Authorization header format',
      ];

      // Generate unique error messages unlikely to appear in the generic 500 response body
      const errorMessageArb = fc
        .stringMatching(/^[a-zA-Z0-9_]{3,50}$/)
        .filter((msg) => !authMessages.includes(msg));

      await fc.assert(
        fc.asyncProperty(errorMessageArb, async (errorMessage) => {
          // Activate the mock to throw
          mockState.shouldThrow = true;
          mockState.error = new Error(errorMessage);

          const event = {
            httpMethod: 'GET',
            path: '/test',
            headers: { Authorization: 'Bearer test-user' },
          };

          const response = await handler(event, {});

          // Deactivate the mock
          mockState.shouldThrow = false;
          mockState.error = null;

          // Must be a 500 response
          expect(response.statusCode).toBe(500);

          // CORS headers must still be present
          expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();
          expect(response.headers['Access-Control-Allow-Methods']).toBeDefined();
          expect(response.headers['Access-Control-Allow-Headers']).toBeDefined();

          // Body must be JSON-parseable
          expect(typeof response.body).toBe('string');
          JSON.parse(response.body);

          // Body must not contain forbidden patterns
          const bodyStr = response.body;
          for (const pattern of forbiddenPatterns) {
            expect(bodyStr).not.toContain(pattern);
          }

          // Body must not contain the original error message
          expect(bodyStr).not.toContain(errorMessage);
        }),
        { numRuns: 100 }
      );
    });
  });
});
