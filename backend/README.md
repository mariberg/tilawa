# Tilawa Backend

Serverless backend for a Quran study app. Fetches Quran content from the [Quran.com API](https://quran.com), generates AI-powered session prep (summaries and vocabulary) via Amazon Bedrock, and persists user data in DynamoDB.

Built with AWS Lambda, API Gateway, and CloudFormation.

## Architecture

- **Runtime**: Node.js 22 (ES modules)
- **Compute**: Single Lambda function behind API Gateway (proxy integration)
- **Database**: DynamoDB single-table design (`PK`/`SK`)
- **AI**: Amazon Bedrock (Nova Lite) via cross-account role assumption
- **Auth**: JWT Bearer tokens — `sub` claim used as user ID
- **IaC**: CloudFormation (`template.yaml`)

## API Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | ✅ | Health check |
| PUT | `/settings` | ✅ | Save user settings (Arabic level) |
| GET | `/settings` | ✅ | Get user settings |
| POST | `/sessions/prepare` | ✅ | AI-powered session prep (overview + keywords) |
| POST | `/sessions` | ✅ | Save a completed session + sync to Quran.com |
| GET | `/sessions/recent` | ✅ | List recent sessions |
| PATCH | `/sessions/:id/feeling` | ✅ | Update session feeling |
| POST | `/oauth2/token` | ❌ | OAuth2 token proxy to Quran.com |

## Setup

```bash
npm install
cp .env.example .env
# Fill in your actual values in .env
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `TABLE_NAME` | DynamoDB table name |
| `QF_CLIENT_ID` | Quran.com OAuth2 client ID (production) |
| `QF_CLIENT_SECRET` | Quran.com OAuth2 client secret (production) |
| `QF_PRELIVE_CLIENT_ID` | Quran.com OAuth2 client ID (prelive) |
| `QF_PRELIVE_CLIENT_SECRET` | Quran.com OAuth2 client secret (prelive) |
| `QF_ENV` | `production` or `prelive` (defaults to `prelive`) |
| `BEDROCK_ROLE_ARN` | Cross-account IAM role ARN for Bedrock access |

## Deploy

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name tilawa-dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    BedrockRoleArn=arn:aws:iam::ACCOUNT:role/ROLE \
    QuranClientId=YOUR_ID \
    QuranClientSecret=YOUR_SECRET \
    QuranPreliveClientId=YOUR_PRELIVE_ID \
    QuranPreliveClientSecret=YOUR_PRELIVE_SECRET
```

## Tests

```bash
npm test
```

Runs unit and property-based tests with [Vitest](https://vitest.dev/) and [fast-check](https://fast-check.dev/).

## Project Structure

```
src/
├── index.mjs          # Lambda handler entry point
├── router.mjs         # Route dispatcher
├── auth.mjs           # JWT extraction (no verification — relies on API Gateway)
├── sessions.mjs       # Session prep (Bedrock AI), CRUD, keyword filtering
├── settings.mjs       # User settings (Arabic level)
├── agent.mjs          # Bedrock Nova Lite invocation (cross-account STS)
├── db.mjs             # DynamoDB Document Client helpers
├── tokenProxy.mjs     # OAuth2 token proxy for Quran.com
└── utils/auth.mjs     # Demo auth helper
tests/
├── unit/              # Unit tests
└── property/          # Property-based tests (fast-check)
template.yaml          # CloudFormation stack
```

## License

MIT
