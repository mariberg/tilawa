import { STSClient, AssumeRoleCommand } from "@aws-sdk/client-sts";
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";

const sts = new STSClient({});

/**
 * Assumes the cross-account Bedrock role and returns a configured Bedrock client.
 */
async function getBedrockClient() {
  const { Credentials } = await sts.send(
    new AssumeRoleCommand({
      RoleArn: process.env.BEDROCK_ROLE_ARN,
      RoleSessionName: "LambdaBedrockSession",
    })
  );

  return new BedrockRuntimeClient({
    region: "us-east-1",
    credentials: {
      accessKeyId: Credentials.AccessKeyId,
      secretAccessKey: Credentials.SecretAccessKey,
      sessionToken: Credentials.SessionToken,
    },
  });
}

/**
 * Invokes Amazon Nova Lite via Bedrock (cross-account) and returns the response text.
 *
 * @param {string} prompt - The user prompt to send
 * @param {string} userId - User ID for context tracking
 * @returns {Promise<string>} The model's response text
 */
export async function invokeAgent(prompt, userId) {
  const bedrock = await getBedrockClient();

  const command = new InvokeModelCommand({
    modelId: "amazon.nova-lite-v1:0",
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify({
      messages: [
        {
          role: "user",
          content: [{ text: prompt }],
        },
      ],
      inferenceConfig: {
        maxTokens: 4096,
        temperature: 0.3,
      },
    }),
  });

  const response = await bedrock.send(command);
  const result = JSON.parse(new TextDecoder().decode(response.body));

  return result.output?.message?.content?.[0]?.text ?? "";
}
