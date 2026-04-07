import { Agent } from "strands-agents";

/**
 * Invokes a Strands Agent configured with a Bedrock model.
 *
 * @param {string} prompt - The user prompt to send to the agent
 * @param {string} userId - User ID for context/session tracking
 * @returns {Promise<string>} The agent's response text
 */
export async function invokeAgent(prompt, userId) {
  const agent = new Agent({
    model: "bedrock",
  });

  const response = await agent.invoke(prompt, {
    userId,
  });

  return typeof response === "string" ? response : String(response);
}
