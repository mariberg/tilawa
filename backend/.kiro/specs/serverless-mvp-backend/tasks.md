# Tasks

## Task 1: Project Setup and Dependencies

- [x] 1.1 Initialize Node.js project with `package.json` (type: module, name: serverless-mvp-backend)
- [x] 1.2 Install runtime dependencies: `@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb`, `strands-agents`
- [x] 1.3 Install dev dependencies: `vitest`, `fast-check`
- [x] 1.4 Add test scripts to `package.json` (`"test": "vitest --run"`)

## Task 2: CloudFormation Template

- [x] 2.1 Create `template.yaml` with Parameters (StageName, ProjectName)
- [x] 2.2 Define DynamoDB table resource with PK/SK composite key, PAY_PER_REQUEST billing, and Retain deletion policy
- [x] 2.3 Define IAM execution role with policies for DynamoDB (GetItem, PutItem, UpdateItem, DeleteItem, Query), Bedrock (InvokeModel, InvokeModelWithResponseStream), and CloudWatch Logs
- [x] 2.4 Define Lambda function resource (Node.js runtime, handler: src/index.handler, TABLE_NAME env var)
- [x] 2.5 Define API Gateway REST API with proxy resource ({proxy+}), ANY method (apiKeyRequired: true, Lambda proxy integration), and OPTIONS mock integration for CORS
- [x] 2.6 Define API Key, Usage Plan, UsagePlanKey, Deployment, and Stage resources
- [x] 2.7 Define Lambda invoke permission for API Gateway
- [x] 2.8 Add Outputs for API invoke URL and API key value

## Task 3: Lambda Auth Module

- [x] 3.1 Create `src/auth.mjs` with `extractUserId(event)` function that extracts userId from Bearer token (case-insensitive header lookup)
- [x] 3.2 Implement validation: throw error if Authorization header is missing or doesn't start with "Bearer "

## Task 4: Lambda Router Module

- [x] 4.1 Create `src/router.mjs` with `routeRequest(event, userId)` function that routes by httpMethod and path
- [x] 4.2 Implement stub routes: GET /health returns 200, all other routes return 404

## Task 5: Lambda DB Module

- [x] 5.1 Create `src/db.mjs` with DynamoDB Document Client singleton (table name from TABLE_NAME env var)
- [x] 5.2 Export helper functions: getItem, putItem, queryItems, updateItem, deleteItem

## Task 6: Lambda Agent Module

- [x] 6.1 Create `src/agent.mjs` with `invokeAgent(prompt, userId)` function using Strands Agents SDK with Bedrock model

## Task 7: Lambda Handler Entry Point

- [x] 7.1 Create `src/index.mjs` handler that adds CORS headers, calls extractUserId, calls routeRequest, and returns JSON responses
- [x] 7.2 Implement top-level try/catch: auth errors return 401, unknown errors return 500 with generic message (no internal details)

## Task 8: Unit Tests

- [x] 8.1 Create `tests/unit/auth.test.mjs` — test extractUserId with valid token, missing header, malformed header
- [x] 8.2 Create `tests/unit/router.test.mjs` — test health route returns 200, unknown route returns 404
- [x] 8.3 Create `tests/unit/template.test.mjs` — validate CloudFormation template has required resources, parameters, and outputs

## Task 9: Property-Based Tests

- [x] 9.1 Create `tests/property/auth.property.test.mjs` — Property 1: Bearer token round trip, Property 2: Invalid auth rejection
- [x] 9.2 Create `tests/property/handler.property.test.mjs` — Property 3: Router structured response, Property 4: Response structure + CORS, Property 5: Safe 500 responses
