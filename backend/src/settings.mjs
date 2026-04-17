import { getItem, putItem } from "./db.mjs";

const VALID_LEVELS = ["beginner", "intermediate", "advanced"];

/**
 * Validates and persists the user's Arabic level.
 * @param {object} body - { arabicLevel: "beginner" | "intermediate" | "advanced" }
 * @param {string} userId
 * @returns {Promise<{ statusCode: number, body: object }>}
 */
export async function saveSettings(body, userId) {
  const { arabicLevel } = body ?? {};

  if (!arabicLevel) {
    return {
      statusCode: 400,
      body: { error: "Bad Request", message: "arabicLevel is required" },
    };
  }

  if (!VALID_LEVELS.includes(arabicLevel)) {
    return {
      statusCode: 400,
      body: {
        error: "Bad Request",
        message: "arabicLevel must be one of: beginner, intermediate, advanced",
      },
    };
  }

  await putItem({
    PK: `USER#${userId}`,
    SK: "SETTINGS",
    arabicLevel,
    updatedAt: new Date().toISOString(),
  });

  return { statusCode: 200, body: { arabicLevel } };
}

/**
 * Retrieves the user's stored Arabic level.
 * @param {string} userId
 * @returns {Promise<{ statusCode: number, body: object }>}
 */
export async function getSettings(userId) {
  const record = await getItem(`USER#${userId}`, "SETTINGS");
  return {
    statusCode: 200,
    body: { arabicLevel: record ? record.arabicLevel : null },
  };
}
