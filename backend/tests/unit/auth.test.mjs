import { describe, it, expect } from 'vitest';
import { extractUserId } from '../../src/auth.mjs';

describe('extractUserId', () => {
  it('returns userId from a valid Bearer token', () => {
    const event = { headers: { Authorization: 'Bearer demo-user-1' } };
    expect(extractUserId(event)).toBe('demo-user-1');
  });

  it('throws when Authorization header is missing', () => {
    const event = { headers: {} };
    expect(() => extractUserId(event)).toThrow('Missing Authorization header');
  });

  it('throws when Authorization header is malformed', () => {
    const event = { headers: { Authorization: 'Basic xyz' } };
    expect(() => extractUserId(event)).toThrow('Invalid Authorization header format');
  });

  it('handles lowercase authorization header (case-insensitive)', () => {
    const event = { headers: { authorization: 'Bearer case-test-user' } };
    expect(extractUserId(event)).toBe('case-test-user');
  });
});
