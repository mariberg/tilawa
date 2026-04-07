# Requirements Document

## Introduction

This document defines the requirements for an MVP serverless backend on AWS. The backend consists of a single monolith Lambda function (Node.js) behind API Gateway, using DynamoDB for persistence and Amazon Bedrock for AI model invocation via the Strands Agents SDK. Authentication uses a simplified Bearer token scheme where the token value directly represents the user ID. API Gateway enforces API key validation on all requests. Infrastructure is defined as code using AWS CloudFormation.

## Glossary

- **API_Gateway**: The AWS API Gateway REST API that routes HTTP requests to the Lambda function and enforces API key usage
- **Lambda_Function**: The single Node.js AWS Lambda function that handles all backend logic
- **DynamoDB_Table**: The single-table DynamoDB resource used for all data persistence
- **CloudFormation_Stack**: The AWS CloudFormation template defining all infrastructure resources
- **Bearer_Token**: A simplified authentication token sent in the Authorization header, where the token value is the user ID (e.g., "Bearer demo-user-1" means userId = "demo-user-1")
- **API_Key**: An API Gateway API key required in the x-api-key header for all requests
- **Strands_Agents_SDK**: The Strands Agents library used within the Lambda function to orchestrate AI agent workflows
- **Bedrock_Model**: An Amazon Bedrock foundation model invoked by the Lambda function through the Strands Agents SDK
- **Single_Table_Design**: A DynamoDB design pattern where all entities are stored in one table using composite keys (PK/SK)

## Requirements

### Requirement 1: CloudFormation Infrastructure Definition

**User Story:** As a developer, I want all infrastructure defined in a CloudFormation template, so that I can deploy and tear down the entire stack reproducibly.

#### Acceptance Criteria

1. THE CloudFormation_Stack SHALL define all AWS resources (API_Gateway, Lambda_Function, DynamoDB_Table, IAM roles, API_Key) in a single template file
2. WHEN the CloudFormation_Stack is deployed, THE CloudFormation_Stack SHALL create a fully functional backend with all resources connected
3. THE CloudFormation_Stack SHALL use parameterized values for stage name and project name to support multiple deployments

### Requirement 2: API Gateway Configuration

**User Story:** As a developer, I want an API Gateway REST API that routes all requests to my Lambda function, so that I have a single HTTP entry point for the backend.

#### Acceptance Criteria

1. THE API_Gateway SHALL expose a REST API with a proxy resource that forwards all HTTP methods and paths to the Lambda_Function
2. THE API_Gateway SHALL require a valid API_Key in the x-api-key header for every request
3. WHEN a request is received without a valid API_Key, THE API_Gateway SHALL return a 403 Forbidden response
4. THE API_Gateway SHALL include a usage plan associated with the API_Key to enable request tracking
5. WHEN the CloudFormation_Stack is deployed, THE API_Gateway SHALL output the invoke URL and API_Key value

### Requirement 3: Simple Token-Based Authentication

**User Story:** As a developer, I want a simple token-based authentication mechanism, so that the backend can identify users without a full auth system during MVP development.

#### Acceptance Criteria

1. WHEN a request includes an Authorization header with format "Bearer {userId}", THE Lambda_Function SHALL extract the userId by removing the "Bearer " prefix from the header value
2. IF a request is received without an Authorization header, THEN THE Lambda_Function SHALL return a 401 Unauthorized response with a descriptive error message
3. IF a request contains an Authorization header that does not start with "Bearer ", THEN THE Lambda_Function SHALL return a 401 Unauthorized response with a descriptive error message
4. WHEN a valid Bearer_Token is extracted, THE Lambda_Function SHALL make the userId available for use in downstream request processing

### Requirement 4: Monolith Lambda Function

**User Story:** As a developer, I want a single Lambda function that handles all backend logic, so that I can iterate quickly on the MVP without managing multiple functions.

#### Acceptance Criteria

1. THE Lambda_Function SHALL be implemented in Node.js and handle all incoming API_Gateway requests
2. THE Lambda_Function SHALL have an IAM execution role with permissions to query the DynamoDB_Table, invoke the Bedrock_Model, and write CloudWatch logs
3. THE Lambda_Function SHALL use the Strands_Agents_SDK to orchestrate AI agent workflows that invoke the Bedrock_Model
4. WHEN the Lambda_Function receives a request, THE Lambda_Function SHALL route the request based on the HTTP method and path
5. THE Lambda_Function SHALL return responses in JSON format with appropriate HTTP status codes

### Requirement 5: DynamoDB Single Table Design

**User Story:** As a developer, I want a single DynamoDB table with a flexible key schema, so that I can store multiple entity types and iterate on the data model during MVP development.

#### Acceptance Criteria

1. THE DynamoDB_Table SHALL use a composite primary key with a partition key (PK) of type String and a sort key (SK) of type String
2. THE DynamoDB_Table SHALL use on-demand (PAY_PER_REQUEST) billing mode to avoid capacity planning during MVP development
3. THE CloudFormation_Stack SHALL define the DynamoDB_Table with DeletionPolicy set to retain data on stack deletion

### Requirement 6: Lambda Permissions and Integrations

**User Story:** As a developer, I want the Lambda function to have the correct permissions for DynamoDB, Bedrock, and external API calls, so that all integrations work without manual configuration.

#### Acceptance Criteria

1. THE Lambda_Function SHALL have IAM permissions to perform GetItem, PutItem, UpdateItem, DeleteItem, and Query operations on the DynamoDB_Table
2. THE Lambda_Function SHALL have IAM permissions to invoke Bedrock_Model via the bedrock:InvokeModel and bedrock:InvokeModelWithResponseStream actions
3. THE Lambda_Function SHALL be deployed in a configuration that allows outbound HTTPS connections for external API calls
4. IF the Lambda_Function fails to access the DynamoDB_Table or Bedrock_Model due to a permissions error, THEN THE Lambda_Function SHALL return a 500 Internal Server Error response with a generic error message (no internal details exposed)

### Requirement 7: CORS Support

**User Story:** As a developer, I want the API to support CORS, so that a frontend application can make requests to the backend from a browser.

#### Acceptance Criteria

1. THE API_Gateway SHALL include CORS response headers (Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers) on all responses
2. WHEN an OPTIONS preflight request is received, THE API_Gateway SHALL return a 200 response with appropriate CORS headers
