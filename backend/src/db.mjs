import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
  UpdateCommand,
  DeleteCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient();

/** DynamoDB Document Client singleton */
export const docClient = DynamoDBDocumentClient.from(client);

const tableName = process.env.TABLE_NAME;

/**
 * Gets a single item by partition key and sort key.
 *
 * @param {string} pk - Partition key value
 * @param {string} sk - Sort key value
 * @returns {Promise<object|null>} The item, or null if not found
 */
export async function getItem(pk, sk) {
  const { Item } = await docClient.send(
    new GetCommand({
      TableName: tableName,
      Key: { PK: pk, SK: sk },
    })
  );
  return Item ?? null;
}

/**
 * Puts an item into the table.
 *
 * @param {object} item - Item to put (must include PK and SK attributes)
 * @returns {Promise<void>}
 */
export async function putItem(item) {
  await docClient.send(
    new PutCommand({
      TableName: tableName,
      Item: item,
    })
  );
}

/**
 * Queries items by partition key, optionally filtering by sort key prefix.
 *
 * @param {string} pk - Partition key value
 * @param {string} [skPrefix] - Optional sort key prefix (begins_with)
 * @returns {Promise<object[]>} Array of matching items
 */
export async function queryItems(pk, skPrefix) {
  const params = {
    TableName: tableName,
    KeyConditionExpression: skPrefix
      ? "PK = :pk AND begins_with(SK, :sk)"
      : "PK = :pk",
    ExpressionAttributeValues: { ":pk": pk },
  };

  if (skPrefix) {
    params.ExpressionAttributeValues[":sk"] = skPrefix;
  }

  const { Items } = await docClient.send(new QueryCommand(params));
  return Items ?? [];
}

/**
 * Updates an item's attributes and returns the updated item.
 *
 * @param {string} pk - Partition key value
 * @param {string} sk - Sort key value
 * @param {object} updates - Key-value pairs of attributes to update
 * @returns {Promise<object>} The updated item
 */
export async function updateItem(pk, sk, updates) {
  const keys = Object.keys(updates);
  const { Attributes } = await docClient.send(
    new UpdateCommand({
      TableName: tableName,
      Key: { PK: pk, SK: sk },
      UpdateExpression:
        "SET " + keys.map((k, i) => `#k${i} = :v${i}`).join(", "),
      ExpressionAttributeNames: Object.fromEntries(
        keys.map((k, i) => [`#k${i}`, k])
      ),
      ExpressionAttributeValues: Object.fromEntries(
        keys.map((k, i) => [`:v${i}`, updates[k]])
      ),
      ReturnValues: "ALL_NEW",
    })
  );
  return Attributes;
}

/**
 * Deletes an item by partition key and sort key.
 *
 * @param {string} pk - Partition key value
 * @param {string} sk - Sort key value
 * @returns {Promise<void>}
 */
export async function deleteItem(pk, sk) {
  await docClient.send(
    new DeleteCommand({
      TableName: tableName,
      Key: { PK: pk, SK: sk },
    })
  );
}
