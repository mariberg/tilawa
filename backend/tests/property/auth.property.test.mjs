import { describe, it, expect } from 'vitest';
import fc from 'fast-check';
import { extractUserId } from '../../src/auth.mjs';

describe('Feature: serverless-mvp-backend', () => {
  describe('Property 1: Bearer token extraction round trip', () => {
    /**
     * Validates: Requirements 3.1
     *
     * For any non-empty string userId, constructing "Bearer " + userId
     * and passing it through extractUserId should return exactly userId.
     */
    it('extractUserId returns the original userId for any valid Bearer token', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 1 }),
          (userId) => {
            const event = { headers: { Authorization: `Bearer ${userId}` } };
            expect(extractUserId(event)).toBe(userId);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe('Property 2: Invalid authorization headers are rejected', () => {
    /**
     * Validates: Requirements 3.3
     *
     * For any string that does not start with "Bearer ", passing it as
     * the Authorization header value to extractUserId should throw an error.
     */
    it('extractUserId throws for any header not starting with "Bearer "', () => {
      fc.assert(
        fc.property(
          fc.string().filter((s) => !s.startsWith('Bearer ')),
          (invalidHeader) => {
            const event = { headers: { Authorization: invalidHeader } };
            expect(() => extractUserId(event)).toThrow();
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
