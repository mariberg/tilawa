---
inclusion: always
---

# Security & Secrets Policy

This is a public repository. Never commit sensitive information.

## Forbidden from being hardcoded

- API keys, tokens, or secrets (OpenAI, AWS, Stripe, etc.)
- Database connection strings with credentials
- Passwords or passphrases
- Private keys or certificates
- OAuth client secrets
- Webhook secrets

## Required practices

- All secrets must come from environment variables (e.g., `process.env.API_KEY`)
- Never log, print, or include secret values in comments — even in debug code
- When generating code that needs credentials, always use `process.env.*` references
- SAM/CloudFormation parameters should use `AWS::SSM::Parameter::Value` or Secrets Manager dynamic references — never inline secrets in `template.yaml`

## .env file handling

- A `.env.example` file with placeholder values (e.g., `API_KEY=your_key_here`) should exist for onboarding
- The actual `.env` file must be listed in `.gitignore` — never commit it

## When generating config or credential files

- Remind the user to add them to `.gitignore` if not already covered
- Prefer secret management tools (AWS Secrets Manager, SSM Parameter Store, Vault) for production environments

## .gitignore verification

Before committing, ensure `.gitignore` covers at minimum:

```
.env
.env.local
.env.*.local
*.pem
*.key
secrets.json
config/credentials.*
```

If `.gitignore` is missing or incomplete, flag it immediately.
